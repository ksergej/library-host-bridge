package com.company.library.shared;

public class HostException extends RuntimeException {
    public HostException(String message) {
        super(message);
    }
    public HostException(String message, Throwable cause) {
        super(message, cause);
    }
}
