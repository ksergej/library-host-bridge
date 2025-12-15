// Example only, NOT compiled. Shows how an IBM MQ config could look for Xplore.
//
// package com.company.library.config;
//
// import jakarta.jms.ConnectionFactory;
// import org.springframework.context.annotation.Bean;
// import org.springframework.context.annotation.Configuration;
// import org.springframework.context.annotation.Profile;
// import org.springframework.jms.core.JmsTemplate;
//
// @Configuration
// @Profile("xplore")
// public class XploreMqConfig {
//
//     private final MqConnectionProperties properties;
//
//     public XploreMqConfig(MqConnectionProperties properties) {
//         this.properties = properties;
//     }
//
//     @Bean
//     public ConnectionFactory mqConnectionFactory() {
//         // TODO: create and configure IBM MQ ConnectionFactory using properties
//         // This is intentionally left as a design example and is NOT wired into the build.
//         throw new UnsupportedOperationException("Example only, not implemented");
//     }
//
//     @Bean
//     public JmsTemplate jmsTemplate(ConnectionFactory mqConnectionFactory) {
//         return new JmsTemplate(mqConnectionFactory);
//     }
// }
