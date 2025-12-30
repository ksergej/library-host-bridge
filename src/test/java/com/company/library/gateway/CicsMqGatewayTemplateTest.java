package com.company.library.gateway;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.Duration;
import jakarta.jms.BytesMessage;
import jakarta.jms.MessageProducer;
import jakarta.jms.Destination;
import jakarta.jms.Queue;
import jakarta.jms.Session;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.jms.JmsException;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.jms.core.SessionCallback;

import com.company.library.infrastructure.correlation.CorrelationIdService;

@ExtendWith(MockitoExtension.class)
class CicsMqGatewayTemplateTest {

    @Mock
    private JmsTemplate jmsTemplate;

    @Mock
    private BytesMessage replyMessage;

    @Mock
    private CorrelationIdService correlationIdService;

    private CicsMqGatewayTemplate gateway;

    @BeforeEach
    void setUp() {
        gateway = new CicsMqGatewayTemplate(jmsTemplate, correlationIdService);
    }

    @Test
    // Happy path: message sent, selector built from JMSMessageID, reply bytes returned and timeouts restored.
    void shouldSendRequestAndReturnReplyByCorrelationId() throws Exception {
        byte[] request = "req".getBytes();
        byte[] response = "resp".getBytes();

        when(jmsTemplate.getReceiveTimeout()).thenReturn(5000L);
        when(jmsTemplate.execute(any(SessionCallback.class), anyBoolean())).thenReturn("ID:123");
        when(jmsTemplate.receiveSelected(anyString(), anyString())).thenReturn(replyMessage);
        when(replyMessage.getBodyLength()).thenReturn((long) response.length);
        doAnswer(invocation -> {
            byte[] buffer = invocation.getArgument(0, byte[].class);
            System.arraycopy(response, 0, buffer, 0, response.length);
            return response.length;
        }).when(replyMessage).readBytes(any(byte[].class));

        byte[] result = gateway.callHost(request, "REQ.QUEUE", "REP.QUEUE", Duration.ofSeconds(2));

        assertArrayEquals(response, result);
        verify(jmsTemplate).setReceiveTimeout(2000L);
        verify(jmsTemplate).setReceiveTimeout(5000L);
        verify(jmsTemplate).receiveSelected("REP.QUEUE", "JMSCorrelationID = 'ID:123'");
    }

    @Test
    // Timeout path: no reply received within requested timeout leads to HostTimeoutException.
    void shouldThrowTimeoutWhenNoReply() {
        when(jmsTemplate.getReceiveTimeout()).thenReturn(1000L);
        when(jmsTemplate.execute(any(SessionCallback.class), anyBoolean())).thenReturn("ID:999");
        when(jmsTemplate.receiveSelected(anyString(), anyString())).thenReturn(null);

        assertThrows(HostTimeoutException.class, () ->
            gateway.callHost("req".getBytes(), "REQ", "REP", Duration.ofMillis(500))
        );
        verify(jmsTemplate).setReceiveTimeout(500L);
        verify(jmsTemplate).setReceiveTimeout(1000L);
    }

    @Test
    // Transport errors (JMS/JmsException) are wrapped into HostCommunicationException.
    void shouldWrapCommunicationErrors() {
        when(jmsTemplate.execute(any(SessionCallback.class), anyBoolean()))
            .thenThrow(new JmsException("boom") { private static final long serialVersionUID = 1L; });

        assertThrows(HostCommunicationException.class, () ->
            gateway.callHost("req".getBytes(), "REQ", "REP", Duration.ofSeconds(1))
        );
    }

    @Test
    void shouldNotSetCorrelationIdPropertyWhenPresent() throws Exception {
        byte[] request = "req".getBytes();

        when(jmsTemplate.getReceiveTimeout()).thenReturn(5000L);
        when(correlationIdService.getCurrentCorrelationId()).thenReturn("corr-123");
        when(jmsTemplate.execute(any(SessionCallback.class), anyBoolean())).thenAnswer(invocation -> {
            SessionCallback<?> callback = invocation.getArgument(0);
            Session session = org.mockito.Mockito.mock(Session.class);
            Queue destination = org.mockito.Mockito.mock(Queue.class);
            Queue replyDestination = org.mockito.Mockito.mock(Queue.class);
            BytesMessage message = org.mockito.Mockito.mock(BytesMessage.class);
            MessageProducer producer = org.mockito.Mockito.mock(MessageProducer.class);
            org.mockito.Mockito.when(session.createQueue("queue:///REQ.QUEUE")).thenReturn(destination);
            org.mockito.Mockito.when(session.createQueue("queue:///REP.QUEUE")).thenReturn(replyDestination);
            org.mockito.Mockito.when(session.createBytesMessage()).thenReturn(message);
            org.mockito.Mockito.when(session.createProducer(destination)).thenReturn(producer);
            callback.doInJms(session);
            org.mockito.Mockito.verify(message, org.mockito.Mockito.never())
                .setStringProperty("CorrelationId", "corr-123");
            return "ID:123";
        });
        when(jmsTemplate.receiveSelected(anyString(), anyString())).thenReturn(replyMessage);
        when(replyMessage.getBodyLength()).thenReturn(0L);
        when(replyMessage.readBytes(any(byte[].class))).thenReturn(0);

        gateway.callHost(request, "REQ.QUEUE", "REP.QUEUE", Duration.ofSeconds(1));
    }
}
