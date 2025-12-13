package com.company.library.api.rest;

import com.company.library.ports.LibraryHostUnavailableException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(LibraryHostUnavailableException.class)
    public ResponseEntity<ErrorResponse> handleHostUnavailable(LibraryHostUnavailableException ex) {
        ErrorResponse body = new ErrorResponse("HOST_UNAVAILABLE", ex.getMessage());
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(body);
    }

    public record ErrorResponse(String error, String message) {
    }
}
