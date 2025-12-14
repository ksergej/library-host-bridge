package com.company.library.api.rest;

import com.company.library.api.rest.dto.BorrowBookRequest;
import com.company.library.api.rest.dto.LoanResponse;
import com.company.library.application.LoanAppService;
import com.company.library.mapping.LoanRestMapper;
import jakarta.validation.Valid;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/loans")
@Tag(name = "Loans", description = "Operations for borrowing books via host MQ/COBOL")
public class LoanController {

    private final LoanAppService loanAppService;
    private final LoanRestMapper loanRestMapper;

    public LoanController(LoanAppService loanAppService, LoanRestMapper loanRestMapper) {
        this.loanAppService = loanAppService;
        this.loanRestMapper = loanRestMapper;
    }

    @PostMapping("/borrow")
    @ResponseStatus(HttpStatus.OK)
    @Operation(
        summary = "Borrow a book",
        description = "Borrow book via host integration (MQ → COBOL/DB2)."
    )
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "Borrowed", content = @Content(schema = @Schema(implementation = LoanResponse.class))),
        @ApiResponse(responseCode = "400", description = "Validation error", content = @Content(schema = @Schema(implementation = com.company.library.api.rest.dto.ErrorResponse.class))),
        @ApiResponse(responseCode = "503", description = "Host unavailable", content = @Content(schema = @Schema(implementation = com.company.library.api.rest.dto.ErrorResponse.class)))
    })
    public LoanResponse borrow(@Valid @RequestBody BorrowBookRequest request) {
        return loanRestMapper.toResponse(
            loanAppService.borrowBook(loanRestMapper.toDomain(request))
        );
    }
}
