package com.company.library.config;

import org.springframework.context.annotation.Configuration;

/**
 * Placeholder MQ configuration. In the future this class will:
 * <ul>
 *     <li>Construct a vendor-specific ConnectionFactory using MqConnectionProperties.</li>
 *     <li>Expose JmsTemplate and related beans wired to that ConnectionFactory.</li>
 * </ul>
 * No ConnectionFactory is created here to avoid runtime dependencies on MQ.
 */
@Configuration
public class MqConfig {

    private final MqConnectionProperties connectionProperties;

    public MqConfig(MqConnectionProperties connectionProperties) {
        this.connectionProperties = connectionProperties;
    }

    // TODO: build ConnectionFactory and JmsTemplate when integrating real MQ.
}
