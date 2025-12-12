package com.company.library.api.rest;

import com.company.library.api.rest.dto.BorrowBookRequest;
import com.company.library.api.rest.dto.LoanResponse;
import com.company.library.application.LoanAppService;
import com.company.library.mapping.LoanRestMapper;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/loans")
public class LoanController {

    private final LoanAppService loanAppService;
    private final LoanRestMapper loanRestMapper;

    public LoanController(LoanAppService loanAppService, LoanRestMapper loanRestMapper) {
        this.loanAppService = loanAppService;
        this.loanRestMapper = loanRestMapper;
    }

    @PostMapping("/borrow")
    @ResponseStatus(HttpStatus.OK)
    public LoanResponse borrow(@RequestBody BorrowBookRequest request) {
        return loanRestMapper.toResponse(
            loanAppService.borrowBook(loanRestMapper.toDomain(request))
        );
    }
}
