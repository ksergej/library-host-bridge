package com.company.library.adapters.mq.translator;

import com.company.library.adapters.mq.LibraryMqAdapter;
import com.company.library.domain.model.LoanRef;
import com.company.library.host.schema.HostActiveLoansByUserRequest;
import com.company.library.host.schema.HostActiveLoansByUserResponse;
import com.company.library.host.schema.HostBorrowRequest;
import com.company.library.host.schema.HostBorrowResponse;
import com.company.library.host.schema.HostLoanRef;
import com.company.library.host.schema.HostReturnRequest;
import com.company.library.host.schema.HostReturnResponse;
import com.company.library.domain.model.Loan;
import com.company.library.host.schema.ObjectFactory;
import com.company.library.mapping.LoanHostMapper;
import jakarta.xml.bind.JAXBContext;
import jakarta.xml.bind.JAXBException;
import jakarta.xml.bind.Marshaller;
import jakarta.xml.bind.Unmarshaller;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.util.ArrayList;
import java.util.List;
import java.nio.charset.StandardCharsets;
import javax.xml.transform.stream.StreamSource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

@Component
public class JaxbLibraryMessageTranslator implements LibraryMessageTranslator {

    private final LoanHostMapper loanHostMapper;
    private final JAXBContext jaxbContext;
    private final ObjectFactory objectFactory = new ObjectFactory();
    private static final Logger log = LoggerFactory.getLogger(LibraryMqAdapter.class);

    public JaxbLibraryMessageTranslator(LoanHostMapper loanHostMapper) throws JAXBException {
        this.loanHostMapper = loanHostMapper;
        this.jaxbContext = JAXBContext.newInstance(
            HostBorrowRequest.class,
            HostBorrowResponse.class,
            HostActiveLoansByUserRequest.class,
            HostActiveLoansByUserResponse.class,
            HostReturnRequest.class,
            HostReturnResponse.class
        );
    }

    @Override
    public byte[] toHostRequest(Loan loan) {
        HostBorrowRequest request = loanHostMapper.toHostRequest(loan);
        try {
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            Marshaller marshaller = jaxbContext.createMarshaller();
            marshaller.marshal(objectFactory.createHostBorrowRequest(request), baos);
            return baos.toByteArray();
        } catch (JAXBException ex) {
            throw new IllegalStateException("Failed to marshal host request", ex);
        }
    }

    @Override
    public Loan fromHostResponse(byte[] responsePayload) {
        try {
            Unmarshaller unmarshaller = jaxbContext.createUnmarshaller();
            String xml = new String(responsePayload, StandardCharsets.UTF_8);

// Покажем первые/последние 200 символов
            log.debug("Host XML head:\n{}", xml.substring(0, Math.min(200, xml.length())));
            log.debug("Host XML tail:\n{}", xml.substring(Math.max(0, xml.length() - 200)));

// Быстрая проверка на NUL
            log.debug("Host XML contains NUL? {}", xml.indexOf('\u0000') >= 0);
            HostBorrowResponse response = unmarshaller.unmarshal(
                new StreamSource(new ByteArrayInputStream(responsePayload)),
                HostBorrowResponse.class
            ).getValue();
            return loanHostMapper.fromHostResponse(response);
        } catch (JAXBException ex) {
            log.error("Failed to unmarshal host response XML", ex);
            throw new IllegalStateException("Failed to unmarshal host response", ex);

        }
    }

    @Override
    public byte[] toHostReturnRequest(String loanId) {
        HostReturnRequest request = loanHostMapper.toHostReturnRequest(loanId);
        try {
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            Marshaller marshaller = jaxbContext.createMarshaller();
            marshaller.marshal(objectFactory.createHostReturnRequest(request), baos);
            return baos.toByteArray();
        } catch (JAXBException ex) {
            throw new IllegalStateException("Failed to marshal host return request", ex);
        }
    }

    @Override
    public Loan fromHostReturnResponse(byte[] responsePayload) {
        try {
            Unmarshaller unmarshaller = jaxbContext.createUnmarshaller();
            HostReturnResponse response = unmarshaller.unmarshal(
                new StreamSource(new ByteArrayInputStream(responsePayload)),
                HostReturnResponse.class
            ).getValue();
            return loanHostMapper.fromHostReturnResponse(response);
        } catch (JAXBException ex) {
            log.error("Failed to unmarshal host return response XML", ex);
            throw new IllegalStateException("Failed to unmarshal host return response", ex);
        }
    }

    @Override
    public byte[] toHostActiveLoansByUserRequest(String userId) {
        HostActiveLoansByUserRequest request = new HostActiveLoansByUserRequest();
        request.setUserId(userId);
        try {
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            Marshaller marshaller = jaxbContext.createMarshaller();
            marshaller.marshal(objectFactory.createHostActiveLoansByUserRequest(request), baos);
            return baos.toByteArray();
        } catch (JAXBException ex) {
            throw new IllegalStateException("Failed to marshal active loans request", ex);
        }
    }

    @Override
    public List<LoanRef> fromHostActiveLoansByUserResponse(byte[] responsePayload) {
        try {
            Unmarshaller unmarshaller = jaxbContext.createUnmarshaller();
            HostActiveLoansByUserResponse response = unmarshaller.unmarshal(
                new StreamSource(new ByteArrayInputStream(responsePayload)),
                HostActiveLoansByUserResponse.class
            ).getValue();
            List<LoanRef> loans = new ArrayList<>();
            if (response.getLoan() != null) {
                for (HostLoanRef hostLoan : response.getLoan()) {
                    loans.add(new LoanRef(hostLoan.getLoanId(), hostLoan.getBookId()));
                }
            }
            return loans;
        } catch (JAXBException ex) {
            log.error("Failed to unmarshal active loans response XML", ex);
            throw new IllegalStateException("Failed to unmarshal active loans response", ex);
        }
    }
}
