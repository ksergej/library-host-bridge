package com.company.library.api.rest;

import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.company.library.application.LoanAppService;
import com.company.library.domain.model.Loan;
import com.company.library.mapping.LoanRestMapperImpl;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(controllers = LoanController.class)
@Import({LoanRestMapperImpl.class, GlobalExceptionHandler.class})
class LoanControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private LoanAppService loanAppService;

    @Test
    void postBorrowShouldReturnLoanResponse() throws Exception {
        Loan domainResponse = new Loan("loan-1", "user-1", "book-1");

        when(loanAppService.borrowBook(org.mockito.ArgumentMatchers.any(Loan.class))).thenReturn(domainResponse);

        mockMvc.perform(post("/api/loans/borrow")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "userId": "user-1",
                          "bookId": "book-1"
                        }
                        """))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").value("loan-1"))
            .andExpect(jsonPath("$.userId").value("user-1"))
            .andExpect(jsonPath("$.bookId").value("book-1"));

        verify(loanAppService).borrowBook(org.mockito.ArgumentMatchers.argThat(
            loan -> loan.getUserId().equals("user-1") && loan.getBookId().equals("book-1")
        ));
    }

    @Test
    void postBorrowWhenHostUnavailableReturnsServiceUnavailable() throws Exception {
        when(loanAppService.borrowBook(org.mockito.ArgumentMatchers.any(Loan.class)))
            .thenThrow(new com.company.library.ports.LibraryHostUnavailableException("Host down"));

        mockMvc.perform(post("/api/loans/borrow")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "userId": "user-1",
                          "bookId": "book-1"
                        }
                        """))
            .andExpect(status().isServiceUnavailable())
            .andExpect(jsonPath("$.error").value("HOST_UNAVAILABLE"))
            .andExpect(jsonPath("$.message").value("Host down"));
    }
}
