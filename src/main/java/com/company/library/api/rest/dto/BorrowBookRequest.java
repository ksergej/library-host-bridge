package com.company.library.api.rest.dto;

import jakarta.validation.constraints.NotBlank;
import io.swagger.v3.oas.annotations.media.Schema;

public record BorrowBookRequest(
    @Schema(description = "User identifier") @NotBlank(message = "userId must not be blank") String userId,
    @Schema(description = "Book identifier") @NotBlank(message = "bookId must not be blank") String bookId
) {
}
