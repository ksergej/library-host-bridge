package com.company.library.ports;

/**
 * Indicates that the host system is unavailable or communication failed.
 */
public class LibraryHostUnavailableException extends RuntimeException {

    public LibraryHostUnavailableException(String message) {
        super(message);
    }

    public LibraryHostUnavailableException(String message, Throwable cause) {
        super(message, cause);
    }
}
