package com.company.library.ports;

import com.company.library.domain.model.Loan;
import com.company.library.domain.model.LoanRef;
import java.util.List;

/**
 * Port for communicating with library host (z/OS via MQ).
 */
public interface LibraryHostPort {

    Loan borrowBook(Loan loan);

    Loan returnBook(String loanId);

    List<LoanRef> listActiveLoansByUser(String userId);
}
