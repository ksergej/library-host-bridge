package com.company.library.api.controller;

import com.company.library.api.dto.BorrowBookRequest;
import com.company.library.api.dto.ReturnBookRequest;
import com.company.library.application.LoanAppService;
import com.company.library.domain.model.Loan;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/loans")
public class LoanController {

    private final LoanAppService loanAppService;

    public LoanController(LoanAppService loanAppService) {
        this.loanAppService = loanAppService;
    }

    @PostMapping("/borrow")
    public Loan borrow(@RequestBody BorrowBookRequest request) {
        return loanAppService.borrowBook(request.userId(), request.bookId());
    }

    @PostMapping("/return")
    public Loan giveBack(@RequestBody ReturnBookRequest request) {
        return loanAppService.returnBook(request.userId(), request.bookId());
    }
}
