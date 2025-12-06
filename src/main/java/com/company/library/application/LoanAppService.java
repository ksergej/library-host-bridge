package com.company.library.application;

import com.company.library.domain.model.Loan;
import com.company.library.domain.port.LibraryHostPort;
import org.springframework.stereotype.Service;

@Service
public class LoanAppService {

    private final LibraryHostPort libraryHostPort;

    public LoanAppService(LibraryHostPort libraryHostPort) {
        this.libraryHostPort = libraryHostPort;
    }

    public Loan borrowBook(String userId, String bookId) {
        return libraryHostPort.borrowBook(userId, bookId);
    }

    public Loan returnBook(String userId, String bookId) {
        return libraryHostPort.returnBook(userId, bookId);
    }
}
