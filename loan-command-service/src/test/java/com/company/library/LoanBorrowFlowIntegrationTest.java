package com.company.library;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.company.library.domain.model.Loan;
import com.company.library.adapters.mq.translator.LibraryMessageTranslator;
import com.company.library.gateway.CicsMqGatewayTemplate;
import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest(classes = com.company.library.loancommand.LoanCommandApplication.class)
@AutoConfigureMockMvc
class LoanBorrowFlowIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private CicsMqGatewayTemplate gateway;

    @MockBean
    private LibraryMessageTranslator translator;

    @Test
    void borrowBookFlowFromRestToGateway() throws Exception {
        byte[] requestPayload = "REQ".getBytes(StandardCharsets.UTF_8);
        byte[] responsePayload = "RESP".getBytes(StandardCharsets.UTF_8);
        Loan responseLoan = new Loan("loan-1", "user-1", "book-1");

        when(translator.toHostRequest(any(Loan.class))).thenReturn(requestPayload);
        when(gateway.callHost(any(), any(), any(), any())).thenReturn(responsePayload);
        when(translator.fromHostResponse(responsePayload)).thenReturn(responseLoan);

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

        verify(translator).toHostRequest(any(Loan.class));
        verify(gateway).callHost(requestPayload, "LIB.REQ.TEST", "LIB.REP.TEST", java.time.Duration.ofSeconds(5));
        verify(translator).fromHostResponse(responsePayload);
    }
}
