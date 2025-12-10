package com.company.library.adapters.mq;

import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.company.library.adapters.mq.translator.LibraryMessageTranslator;
import com.company.library.config.LibraryMqProperties;
import com.company.library.domain.model.Loan;
import com.company.library.gateway.CicsMqGatewayTemplate;
import com.company.library.gateway.HostCommunicationException;
import java.time.Duration;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class LibraryMqAdapterTest {

    @Mock
    private LibraryMessageTranslator translator;

    @Mock
    private CicsMqGatewayTemplate gateway;

    private LibraryMqAdapter adapter;
    private LibraryMqProperties properties;

    @BeforeEach
    void setUp() {
        properties = new LibraryMqProperties();
        properties.setRequestQueue("LIB.REQ");
        properties.setReplyQueue("LIB.REP");
        properties.setTimeout(Duration.ofSeconds(3));
        adapter = new LibraryMqAdapter(translator, gateway, properties);
    }

    @Test
    void borrowBookShouldTranslateAndCallGateway() {
        Loan input = new Loan("loan-1", "user-1", "book-1");
        Loan output = new Loan("loan-2", "user-2", "book-2");
        byte[] request = "req".getBytes();
        byte[] response = "resp".getBytes();

        when(translator.toHostRequest(input)).thenReturn(request);
        when(gateway.callHost(request, "LIB.REQ", "LIB.REP", Duration.ofSeconds(3))).thenReturn(response);
        when(translator.fromHostResponse(response)).thenReturn(output);

        Loan result = adapter.borrowBook(input);

        assertSame(output, result);
        verify(translator).toHostRequest(input);
        verify(gateway).callHost(request, "LIB.REQ", "LIB.REP", Duration.ofSeconds(3));
        verify(translator).fromHostResponse(response);
    }

    @Test
    void borrowBookPropagatesGatewayErrors() {
        Loan input = new Loan("loan-1", "user-1", "book-1");
        byte[] request = "req".getBytes();

        when(translator.toHostRequest(input)).thenReturn(request);
        when(gateway.callHost(request, "LIB.REQ", "LIB.REP", Duration.ofSeconds(3)))
            .thenThrow(new HostCommunicationException("fail"));

        assertThrows(HostCommunicationException.class, () -> adapter.borrowBook(input));
    }
}
