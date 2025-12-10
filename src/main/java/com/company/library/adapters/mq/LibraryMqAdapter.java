package com.company.library.adapters.mq;

import com.company.library.adapters.mq.translator.LibraryMessageTranslator;
import com.company.library.config.LibraryMqProperties;
import com.company.library.domain.model.Loan;
import com.company.library.gateway.CicsMqGatewayTemplate;
import com.company.library.ports.LibraryHostPort;
import org.springframework.stereotype.Component;

/**
 * MQ adapter implementing LibraryHostPort via CicsMqGatewayTemplate.
 */
@Component
public class LibraryMqAdapter implements LibraryHostPort {

    private final LibraryMessageTranslator translator;
    private final CicsMqGatewayTemplate gateway;
    private final LibraryMqProperties properties;

    public LibraryMqAdapter(LibraryMessageTranslator translator,
                            CicsMqGatewayTemplate gateway,
                            LibraryMqProperties properties) {
        this.translator = translator;
        this.gateway = gateway;
        this.properties = properties;
    }

    @Override
    public Loan borrowBook(Loan loan) {
        byte[] requestPayload = translator.toHostRequest(loan);
        byte[] responsePayload = gateway.callHost(
            requestPayload,
            properties.getRequestQueue(),
            properties.getReplyQueue(),
            properties.getTimeout()
        );
        return translator.fromHostResponse(responsePayload);
    }
}
