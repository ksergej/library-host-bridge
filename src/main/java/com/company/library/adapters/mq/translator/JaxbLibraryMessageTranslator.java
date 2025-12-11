package com.company.library.adapters.mq.translator;

import com.company.library.host.schema.HostBorrowRequest;
import com.company.library.host.schema.HostBorrowResponse;
import com.company.library.domain.model.Loan;
import com.company.library.host.schema.ObjectFactory;
import com.company.library.mapping.LoanHostMapper;
import jakarta.xml.bind.JAXBContext;
import jakarta.xml.bind.JAXBException;
import jakarta.xml.bind.Marshaller;
import jakarta.xml.bind.Unmarshaller;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import javax.xml.transform.stream.StreamSource;
import org.springframework.stereotype.Component;

@Component
public class JaxbLibraryMessageTranslator implements LibraryMessageTranslator {

    private final LoanHostMapper loanHostMapper;
    private final JAXBContext jaxbContext;
    private final ObjectFactory objectFactory = new ObjectFactory();

    public JaxbLibraryMessageTranslator(LoanHostMapper loanHostMapper) throws JAXBException {
        this.loanHostMapper = loanHostMapper;
        this.jaxbContext = JAXBContext.newInstance(HostBorrowRequest.class, HostBorrowResponse.class);
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
            HostBorrowResponse response = unmarshaller.unmarshal(
                new StreamSource(new ByteArrayInputStream(responsePayload)),
                HostBorrowResponse.class
            ).getValue();
            return loanHostMapper.fromHostResponse(response);
        } catch (JAXBException ex) {
            throw new IllegalStateException("Failed to unmarshal host response", ex);
        }
    }
}
