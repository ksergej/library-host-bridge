package com.company.library.infrastructure.cicsmq.gateway;

import com.company.library.shared.HostException;
import com.company.library.infrastructure.tracing.CorrelationIdFactory;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.jms.core.MessagePostProcessor;

import jakarta.jms.*;

public abstract class CicsMqGatewayTemplate {

    private final JmsTemplate jmsTemplate;
    private final CorrelationIdFactory correlationIdFactory;

    protected CicsMqGatewayTemplate(JmsTemplate jmsTemplate,
                                    CorrelationIdFactory correlationIdFactory) {
        this.jmsTemplate = jmsTemplate;
        this.correlationIdFactory = correlationIdFactory;
    }

    protected <T> T execute(String operationName, Object payload) {
        String correlationId = correlationIdFactory.newId();
        try {
            return doCall(operationName, correlationId, payload);
        } catch (JMSException e) {
            throw new HostException("Error calling host operation " + operationName, e);
        }
    }

    protected abstract <T> T doCall(String operationName,
                                    String correlationId,
                                    Object payload) throws JMSException;

    protected byte[] sendAndReceiveBytes(String requestQueue,
                                         String replyQueue,
                                         byte[] body,
                                         String correlationId) throws JMSException {

        jmsTemplate.convertAndSend(requestQueue, body, (MessagePostProcessor) message -> {
            message.setJMSCorrelationID(correlationId);
            return message;
        });

        String selector = "JMSCorrelationID = '" + correlationId + "'";
        Message message = jmsTemplate.receiveSelected(replyQueue, selector);
        if (message == null) {
            throw new HostException("Timeout waiting for reply with CorrelationID=" + correlationId);
        }
        if (!(message instanceof BytesMessage bytesMessage)) {
            throw new HostException("Unexpected message type " + message.getClass());
        }

        byte[] buffer = new byte[(int) bytesMessage.getBodyLength()];
        bytesMessage.readBytes(buffer);
        return buffer;
    }
}
