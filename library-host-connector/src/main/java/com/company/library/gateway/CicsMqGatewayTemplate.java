package com.company.library.gateway;

import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Objects;

import jakarta.jms.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jms.JmsException;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.jms.core.SessionCallback;
import org.springframework.stereotype.Component;
import com.ibm.mq.jakarta.jms.MQQueue;
import com.ibm.msg.client.jakarta.wmq.WMQConstants;

import com.company.library.infrastructure.correlation.CorrelationIdService;

/**
 * MQ gateway encapsulating request/reply pattern with CorrelationId = MsgId.
 */
@Component
public class CicsMqGatewayTemplate {

    private static final Logger log = LoggerFactory.getLogger(CicsMqGatewayTemplate.class);

    private final JmsTemplate jmsTemplate;
    private final CorrelationIdService correlationIdService;

    public CicsMqGatewayTemplate(JmsTemplate jmsTemplate, CorrelationIdService correlationIdService) {
        this.jmsTemplate = jmsTemplate;
        this.correlationIdService = correlationIdService;
    }

    /**
     * Sends request payload to request queue and waits for reply on reply queue using JMSCorrelationID selector.
     *
     * @param requestPayload payload bytes for host
     * @param requestQueue   name of request queue
     * @param replyQueue     name of reply queue
     * @param timeout        receive timeout
     * @return reply payload bytes
     */
    public byte[] callHost(byte[] requestPayload, String requestQueue, String replyQueue, Duration timeout) {
        Objects.requireNonNull(requestPayload, "requestPayload must not be null");
        Objects.requireNonNull(requestQueue, "requestQueue must not be null");
        Objects.requireNonNull(replyQueue, "replyQueue must not be null");
        Objects.requireNonNull(timeout, "timeout must not be null");

        try {
            String messageId = sendAndReturnMessageId(requestPayload, requestQueue, replyQueue);
            if (messageId == null) {
                throw new HostCommunicationException("JMSMessageID is null after sending request");
            }

            String selector = "JMSCorrelationID = '" + messageId + "'";

            long originalTimeout = jmsTemplate.getReceiveTimeout();
            jmsTemplate.setReceiveTimeout(timeout.toMillis());
            try {
                Message reply = jmsTemplate.receiveSelected(replyQueue, selector);
                if (reply == null) {
                    throw new HostTimeoutException("Timeout waiting for reply with correlationId=" + messageId);
                }
                return extractBytes(reply);
            } finally {
                jmsTemplate.setReceiveTimeout(originalTimeout);
            }
        } catch (JMSException | JmsException ex) {
            throw new HostCommunicationException("Failed to communicate with host MQ", ex);
        }
    }

    private String sendAndReturnMessageId(byte[] requestPayload, String requestQueue, String replyQueue) throws JMSException {
        return jmsTemplate.execute(session -> {

            // IMPORTANT: create MQ destinations via queue:/// so we can set targetClient
            Destination reqDest = session.createQueue("queue:///" + requestQueue);
            Destination repDest = session.createQueue("queue:///" + replyQueue);

            // IMPORTANT: force NONJMS -> no RFH2 header (no MQHRF2)
            if (reqDest instanceof MQQueue mqReq) {
                mqReq.setTargetClient(WMQConstants.WMQ_CLIENT_NONJMS_MQ);
            }
            if (repDest instanceof MQQueue mqRep) {
                mqRep.setTargetClient(WMQConstants.WMQ_CLIENT_NONJMS_MQ);
            }

            BytesMessage msg = session.createBytesMessage();
            msg.writeBytes(requestPayload);

            // OPTIONAL but recommended: populate MQMD.ReplyToQ via JMSReplyTo
            msg.setJMSReplyTo(repDest);

            // IMPORTANT: do NOT set JMS properties here (they can trigger RFH2/JMS headers)
            // String correlationId = correlationIdService.getCurrentCorrelationId();
            // (log it only)
            String correlationId = correlationIdService.getCurrentCorrelationId();

            msg.setStringProperty(WMQConstants.JMS_IBM_FORMAT, "MQSTR   "); // 8 символов!
            msg.setIntProperty(WMQConstants.JMS_IBM_CHARACTER_SET, 1208);

            try (MessageProducer producer = session.createProducer(reqDest)) {
                producer.send(msg);
            }

            if (log.isDebugEnabled()) {
                log.debug("Sent MQ request to {} (httpCorrelationId={})", requestQueue, correlationId);
            }

            return msg.getJMSMessageID();
        }, true);
    }
    private byte[] extractBytes(Message message) throws JMSException {
        if (message instanceof TextMessage textMessage) {
            // JMS (IBM MQ) конвертирует CCSID 1047 -> Java String (Unicode)
            String text = textMessage.getText();
            return text.getBytes(StandardCharsets.UTF_8);
        }

        if (message instanceof BytesMessage bytesMessage) {
            long length = bytesMessage.getBodyLength();
            if (length > Integer.MAX_VALUE) {
                throw new HostCommunicationException("Reply message too large: " + length);
            }
            byte[] data = new byte[(int) length];
            bytesMessage.readBytes(data);
            return data;
        }

        throw new HostCommunicationException("Unsupported reply message type: " + message.getClass().getName());
    }
}
