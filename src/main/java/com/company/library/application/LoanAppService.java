package com.company.library.application;

import com.company.library.domain.model.Loan;
import com.company.library.ports.LibraryHostPort;
import org.springframework.stereotype.Service;

@Service
public class LoanAppService {

    private final LibraryHostPort libraryHostPort;

    public LoanAppService(LibraryHostPort libraryHostPort) {
        this.libraryHostPort = libraryHostPort;
    }

    public Loan borrowBook(Loan loan) {
        return libraryHostPort.borrowBook(loan);
    }
}
