package com.company.library.api.rest.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;

public record LoansByUserRequest(
    @Schema(description = "User identifier") @NotBlank(message = "userId must not be blank") String userId
) {
}
