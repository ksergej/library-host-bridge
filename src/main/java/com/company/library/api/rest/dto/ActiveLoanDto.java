package com.company.library.api.rest.dto;

import io.swagger.v3.oas.annotations.media.Schema;

public record ActiveLoanDto(
    @Schema(description = "Loan identifier") String loanId,
    @Schema(description = "Book identifier") String bookId
) {
}
