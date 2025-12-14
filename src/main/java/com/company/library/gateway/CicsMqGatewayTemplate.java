package com.company.library.gateway;

import java.time.Duration;
import java.util.Objects;
import jakarta.jms.BytesMessage;
import jakarta.jms.Destination;
import jakarta.jms.JMSException;
import jakarta.jms.Message;
import jakarta.jms.MessageProducer;
import jakarta.jms.Session;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jms.JmsException;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.jms.core.SessionCallback;
import org.springframework.stereotype.Component;

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
            String messageId = sendAndReturnMessageId(requestPayload, requestQueue);
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

    private String sendAndReturnMessageId(byte[] requestPayload, String requestQueue) throws JMSException {
        return jmsTemplate.execute(new SessionCallback<String>() {
            @Override
            public String doInJms(Session session) throws JMSException {
                Destination destination = session.createQueue(requestQueue);
                BytesMessage message = session.createBytesMessage();
                message.writeBytes(requestPayload);

                String correlationId = correlationIdService.getCurrentCorrelationId();
                if (correlationId != null && !correlationId.isBlank()) {
                    message.setStringProperty("CorrelationId", correlationId);
                }

                MessageProducer producer = session.createProducer(destination);
                producer.send(message);
                if (log.isDebugEnabled()) {
                    log.debug("Sent MQ request to {} with correlation property {}", requestQueue, correlationId);
                }
                return message.getJMSMessageID();
            }
        }, true);
    }

    private byte[] extractBytes(Message message) throws JMSException {
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
