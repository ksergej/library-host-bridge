package com.company.library.gateway;

/**
 * Signals any transport-level MQ/JMS communication problems with the host.
 */
public class HostCommunicationException extends RuntimeException {

    public HostCommunicationException(String message) {
        super(message);
    }

    public HostCommunicationException(String message, Throwable cause) {
        super(message, cause);
    }
}
