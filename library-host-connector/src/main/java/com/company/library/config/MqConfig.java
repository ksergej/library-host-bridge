package com.company.library.config;

import com.ibm.mq.jakarta.jms.MQConnectionFactory;
import com.ibm.msg.client.jakarta.wmq.WMQConstants;
import jakarta.jms.ConnectionFactory;
import jakarta.jms.JMSException;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jms.connection.UserCredentialsConnectionFactoryAdapter;
import org.springframework.jms.core.JmsTemplate;

@Configuration
public class MqConfig {

    private final MqConnectionProperties p;

    public MqConfig(MqConnectionProperties p) {
        this.p = p;
    }

    @Bean
    public ConnectionFactory mqConnectionFactory() throws JMSException {
        MQConnectionFactory mq = new MQConnectionFactory();

        mq.setTransportType(WMQConstants.WMQ_CM_CLIENT);
        mq.setHostName(p.getHost());
        mq.setPort(p.getPort());
        mq.setChannel(p.getChannel());
        mq.setQueueManager(p.getQueueManager());

        UserCredentialsConnectionFactoryAdapter cf = new UserCredentialsConnectionFactoryAdapter();
        cf.setTargetConnectionFactory(mq);
        cf.setUsername(p.getUser());
        cf.setPassword(p.getPassword());

        return cf;
    }

    @Bean
    public JmsTemplate jmsTemplate(ConnectionFactory mqConnectionFactory) {
        return new JmsTemplate(mqConnectionFactory);
    }
}