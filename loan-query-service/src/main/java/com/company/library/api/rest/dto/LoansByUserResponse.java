package com.company.library.api.rest.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.List;

public record LoansByUserResponse(
    @Schema(description = "User identifier") String userId,
    @Schema(description = "Active loans") List<ActiveLoanDto> loans
) {
}
