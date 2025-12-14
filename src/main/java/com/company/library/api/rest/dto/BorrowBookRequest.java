package com.company.library.api.rest.dto;

import jakarta.validation.constraints.NotBlank;

public record BorrowBookRequest(
    @NotBlank(message = "userId must not be blank") String userId,
    @NotBlank(message = "bookId must not be blank") String bookId
) {
}
