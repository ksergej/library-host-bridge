package com.company.library.api.rest.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;

public record ReturnBookRequest(
    @Schema(description = "Loan identifier") @NotBlank(message = "loanId must not be blank") String loanId
) {
}
