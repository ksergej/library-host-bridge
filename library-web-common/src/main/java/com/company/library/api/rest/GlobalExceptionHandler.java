package com.company.library.api.rest;

import com.company.library.api.rest.dto.ErrorResponse;
import com.company.library.infrastructure.correlation.CorrelationIdService;
import com.company.library.ports.LibraryHostUnavailableException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private final CorrelationIdService correlationIdService;

    public GlobalExceptionHandler(CorrelationIdService correlationIdService) {
        this.correlationIdService = correlationIdService;
    }

    @ExceptionHandler(LibraryHostUnavailableException.class)
    public ResponseEntity<ErrorResponse> handleHostUnavailable(LibraryHostUnavailableException ex) {
        ErrorResponse body = new ErrorResponse("HOST_UNAVAILABLE", ex.getMessage(), correlationIdService.getCurrentCorrelationId());
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(body);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidation(MethodArgumentNotValidException ex) {
        BindingResult bindingResult = ex.getBindingResult();
        String message = bindingResult.getFieldErrors().stream()
            .findFirst()
            .map(error -> String.format("Validation failed for field '%s': %s", error.getField(), error.getDefaultMessage()))
            .orElse("Validation error");
        ErrorResponse body = new ErrorResponse("VALIDATION_ERROR", message, correlationIdService.getCurrentCorrelationId());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(body);
    }
}
