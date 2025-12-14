package com.company.library.api.rest.dto;

public record ErrorResponse(String error, String message, String correlationId) {
}
