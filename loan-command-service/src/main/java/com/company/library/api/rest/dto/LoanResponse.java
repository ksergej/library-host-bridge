package com.company.library.api.rest.dto;

import io.swagger.v3.oas.annotations.media.Schema;

public record LoanResponse(
    @Schema(description = "Loan identifier") String id,
    @Schema(description = "User identifier") String userId,
    @Schema(description = "Book identifier") String bookId
) {
}
