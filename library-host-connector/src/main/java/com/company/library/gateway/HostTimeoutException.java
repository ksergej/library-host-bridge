package com.company.library.gateway;

/**
 * Indicates a timeout while waiting for host MQ reply.
 */
public class HostTimeoutException extends HostCommunicationException {

    public HostTimeoutException(String message) {
        super(message);
    }

    public HostTimeoutException(String message, Throwable cause) {
        super(message, cause);
    }
}
