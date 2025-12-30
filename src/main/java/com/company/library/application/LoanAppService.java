package com.company.library.application;

import com.company.library.domain.model.Loan;
import com.company.library.domain.model.LoanRef;
import com.company.library.ports.LibraryHostPort;
import java.util.List;
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

    public Loan returnBook(String loanId) {
        return libraryHostPort.returnBook(loanId);
    }

    public List<LoanRef> listActiveLoansByUser(String userId) {
        return libraryHostPort.listActiveLoansByUser(userId);
    }
}
