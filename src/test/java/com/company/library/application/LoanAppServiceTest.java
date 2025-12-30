package com.company.library.application;

import static org.junit.jupiter.api.Assertions.assertSame;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.company.library.domain.model.Loan;
import com.company.library.domain.model.LoanRef;
import java.util.List;
import com.company.library.ports.LibraryHostPort;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class LoanAppServiceTest {

    @Mock
    private LibraryHostPort libraryHostPort;

    private LoanAppService loanAppService;

    @BeforeEach
    void setUp() {
        loanAppService = new LoanAppService(libraryHostPort);
    }

    @Test
    void borrowBookDelegatesToHostPort() {
        Loan request = new Loan(null, "user-1", "book-1");
        Loan response = new Loan("loan-1", "user-1", "book-1");

        when(libraryHostPort.borrowBook(request)).thenReturn(response);

        Loan result = loanAppService.borrowBook(request);

        assertSame(response, result);
        verify(libraryHostPort).borrowBook(request);
    }

    @Test
    void returnBookDelegatesToHostPort() {
        Loan response = new Loan("loan-1", "user-1", "book-1");

        when(libraryHostPort.returnBook("loan-1")).thenReturn(response);

        Loan result = loanAppService.returnBook("loan-1");

        assertSame(response, result);
        verify(libraryHostPort).returnBook("loan-1");
    }

    @Test
    void listActiveLoansByUserDelegatesToHostPort() {
        List<LoanRef> response = List.of(new LoanRef("L1", "B1"));

        when(libraryHostPort.listActiveLoansByUser("user-1")).thenReturn(response);

        List<LoanRef> result = loanAppService.listActiveLoansByUser("user-1");

        assertSame(response, result);
        verify(libraryHostPort).listActiveLoansByUser("user-1");
    }
}
