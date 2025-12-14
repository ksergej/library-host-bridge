package com.company.library.api.rest.dto;

import io.swagger.v3.oas.annotations.media.Schema;

public record ErrorResponse(
    @Schema(description = "Error code") String error,
    @Schema(description = "Human-readable error message") String message,
    @Schema(description = "Correlation id for tracing, if available") String correlationId
) {
}
