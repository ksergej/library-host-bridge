package com.company.library.ports;

import com.company.library.domain.model.Loan;

/**
 * Port for communicating with library host (z/OS via MQ).
 */
public interface LibraryHostPort {

    Loan borrowBook(Loan loan);
}
