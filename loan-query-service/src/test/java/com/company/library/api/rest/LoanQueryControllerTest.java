package com.company.library.api.rest;

import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.company.library.application.LoanQueryService;
import com.company.library.domain.model.LoanRef;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(controllers = LoanQueryController.class)
@ContextConfiguration(classes = com.company.library.loanquery.LoanQueryApplication.class)
@Import({GlobalExceptionHandler.class, com.company.library.infrastructure.correlation.CorrelationIdService.class})
class LoanQueryControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private LoanQueryService loanQueryService;

    @Test
    void postByUserShouldReturnActiveLoans() throws Exception {
        List<LoanRef> loans = List.of(
            new LoanRef("L1", "B1"),
            new LoanRef("L2", "B2")
        );

        when(loanQueryService.listActiveLoansByUser("user-1")).thenReturn(loans);

        mockMvc.perform(post("/api/loans/by-user")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "userId": "user-1"
                        }
                        """))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.userId").value("user-1"))
            .andExpect(jsonPath("$.loans[0].loanId").value("L1"))
            .andExpect(jsonPath("$.loans[0].bookId").value("B1"))
            .andExpect(jsonPath("$.loans[1].loanId").value("L2"))
            .andExpect(jsonPath("$.loans[1].bookId").value("B2"));

        verify(loanQueryService).listActiveLoansByUser("user-1");
    }

    @Test
    void postByUserWhenHostUnavailableReturnsServiceUnavailable() throws Exception {
        when(loanQueryService.listActiveLoansByUser("user-1"))
            .thenThrow(new com.company.library.ports.LibraryHostUnavailableException("Host down"));

        mockMvc.perform(post("/api/loans/by-user")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "userId": "user-1"
                        }
                        """))
            .andExpect(status().isServiceUnavailable())
            .andExpect(jsonPath("$.error").value("HOST_UNAVAILABLE"))
            .andExpect(jsonPath("$.message").value("Host down"))
            .andExpect(jsonPath("$.correlationId").isNotEmpty());
    }

    @Test
    void postByUserWithMissingUserIdReturnsBadRequest() throws Exception {
        mockMvc.perform(post("/api/loans/by-user")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                        }
                        """))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.error").value("VALIDATION_ERROR"))
            .andExpect(jsonPath("$.message").isNotEmpty())
            .andExpect(jsonPath("$.correlationId").isNotEmpty());
    }
}
