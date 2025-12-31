package com.company.library.application;

import static org.junit.jupiter.api.Assertions.assertSame;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.company.library.domain.model.LoanRef;
import com.company.library.ports.LibraryHostPort;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class LoanQueryServiceTest {

    @Mock
    private LibraryHostPort libraryHostPort;

    private LoanQueryService loanQueryService;

    @BeforeEach
    void setUp() {
        loanQueryService = new LoanQueryService(libraryHostPort);
    }

    @Test
    void listActiveLoansByUserDelegatesToHostPort() {
        List<LoanRef> response = List.of(new LoanRef("L1", "B1"));

        when(libraryHostPort.listActiveLoansByUser("user-1")).thenReturn(response);

        List<LoanRef> result = loanQueryService.listActiveLoansByUser("user-1");

        assertSame(response, result);
        verify(libraryHostPort).listActiveLoansByUser("user-1");
    }
}
