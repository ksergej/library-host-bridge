package com.company.library.adapters.mq;

import com.company.library.adapters.mq.translator.LibraryMessageTranslator;
import com.company.library.config.LibraryMqProperties;
import com.company.library.domain.model.Loan;
import com.company.library.gateway.CicsMqGatewayTemplate;
import com.company.library.gateway.HostCommunicationException;
import com.company.library.gateway.HostTimeoutException;
import com.company.library.ports.LibraryHostPort;
import com.company.library.ports.LibraryHostUnavailableException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * MQ adapter implementing LibraryHostPort via CicsMqGatewayTemplate.
 */
@Component
public class LibraryMqAdapter implements LibraryHostPort {

    private static final Logger log = LoggerFactory.getLogger(LibraryMqAdapter.class);

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
        try {
            byte[] requestPayload = translator.toHostRequest(loan);
            if (log.isDebugEnabled()) {
                log.debug("Sending loan request to host via MQ");
            }
            byte[] responsePayload = gateway.callHost(
                requestPayload,
                properties.getRequestQueue(),
                properties.getReplyQueue(),
                properties.getTimeout()
            );
            if (log.isDebugEnabled()) {
                log.debug("Received loan response from host via MQ");
            }
            return translator.fromHostResponse(responsePayload);
        } catch (HostTimeoutException ex) {
            throw new LibraryHostUnavailableException("Host timeout while borrowing book", ex);
        } catch (HostCommunicationException ex) {
            throw new LibraryHostUnavailableException("Host communication failed while borrowing book", ex);
        }
    }
}
