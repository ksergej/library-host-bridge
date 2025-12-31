package com.company.library.api.rest;

import com.company.library.api.rest.dto.ActiveLoanDto;
import com.company.library.api.rest.dto.LoansByUserRequest;
import com.company.library.api.rest.dto.LoansByUserResponse;
import com.company.library.application.LoanQueryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/loans")
@Tag(name = "Loans", description = "Query operations for listing active loans via host MQ/COBOL")
public class LoanQueryController {

    private final LoanQueryService loanQueryService;

    public LoanQueryController(LoanQueryService loanQueryService) {
        this.loanQueryService = loanQueryService;
    }

    @PostMapping("/by-user")
    @ResponseStatus(HttpStatus.OK)
    @Operation(
        summary = "List active loans by user",
        description = "List active loans via host integration (MQ → COBOL/DB2)."
    )
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "Active loans", content = @Content(schema = @Schema(implementation = LoansByUserResponse.class))),
        @ApiResponse(responseCode = "400", description = "Validation error", content = @Content(schema = @Schema(implementation = com.company.library.api.rest.dto.ErrorResponse.class))),
        @ApiResponse(responseCode = "503", description = "Host unavailable", content = @Content(schema = @Schema(implementation = com.company.library.api.rest.dto.ErrorResponse.class)))
    })
    public LoansByUserResponse listActiveLoansByUser(@Valid @RequestBody LoansByUserRequest request) {
        List<ActiveLoanDto> loans = loanQueryService.listActiveLoansByUser(request.userId()).stream()
            .map(loan -> new ActiveLoanDto(loan.getLoanId(), loan.getBookId()))
            .toList();
        return new LoansByUserResponse(request.userId(), loans);
    }
}
