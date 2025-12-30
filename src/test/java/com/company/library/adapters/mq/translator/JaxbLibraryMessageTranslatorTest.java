package com.company.library.adapters.mq.translator;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.company.library.host.schema.HostBorrowResponse;
import com.company.library.host.schema.HostLoan;
import com.company.library.host.schema.HostReturnResponse;
import com.company.library.host.schema.HostUser;
import com.company.library.domain.model.Loan;
import com.company.library.mapping.LoanHostMapper;
import jakarta.xml.bind.JAXBContext;
import jakarta.xml.bind.Marshaller;
import java.io.ByteArrayOutputStream;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mapstruct.factory.Mappers;

class JaxbLibraryMessageTranslatorTest {

    private JaxbLibraryMessageTranslator translator;

    @BeforeEach
    void setUp() throws Exception {
        LoanHostMapper mapper = Mappers.getMapper(LoanHostMapper.class);
        translator = new JaxbLibraryMessageTranslator(mapper);
    }

    @Test
    void toHostRequestShouldProduceXmlWithIds() {
        Loan loan = new Loan("L1", "U1", "B1");

        byte[] xml = translator.toHostRequest(loan);

        String xmlString = new String(xml);
        assertThat(xmlString).contains("<user>").contains("<id>U1</id>");
        assertThat(xmlString).contains("<book>").contains("<id>B1</id>");
    }

    @Test
    void fromHostResponseShouldMapBackToLoan() throws Exception {
        HostBorrowResponse response = new HostBorrowResponse();
        HostLoan hostLoan = new HostLoan();
        hostLoan.setLoanId("L2");
        HostUser hostUser = new HostUser();
        hostUser.setId("U2");
        hostLoan.setUser(hostUser);
        com.company.library.host.schema.HostBook hostBook = new com.company.library.host.schema.HostBook();
        hostBook.setId("B2");
        hostLoan.setBook(hostBook);
        response.setLoan(hostLoan);

        JAXBContext ctx = JAXBContext.newInstance(HostBorrowResponse.class);
        Marshaller marshaller = ctx.createMarshaller();
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        marshaller.marshal(new com.company.library.host.schema.ObjectFactory().createHostBorrowResponse(response), baos);

        Loan loan = translator.fromHostResponse(baos.toByteArray());

        assertThat(loan.getId()).isEqualTo("L2");
        assertThat(loan.getUserId()).isEqualTo("U2");
        assertThat(loan.getBookId()).isEqualTo("B2");
    }

    @Test
    void fromHostResponseShouldFailOnInvalidXml() {
        byte[] invalid = "<broken>".getBytes();

        assertThrows(IllegalStateException.class, () -> translator.fromHostResponse(invalid));
    }

    @Test
    void toHostReturnRequestShouldProduceXmlWithLoanId() {
        byte[] xml = translator.toHostReturnRequest("L10");

        String xmlString = new String(xml);
        assertThat(xmlString).contains("<loanId>L10</loanId>");
    }

    @Test
    void fromHostReturnResponseShouldMapBackToLoan() throws Exception {
        HostReturnResponse response = new HostReturnResponse();
        HostLoan hostLoan = new HostLoan();
        hostLoan.setLoanId("L3");
        HostUser hostUser = new HostUser();
        hostUser.setId("U3");
        hostLoan.setUser(hostUser);
        com.company.library.host.schema.HostBook hostBook = new com.company.library.host.schema.HostBook();
        hostBook.setId("B3");
        hostLoan.setBook(hostBook);
        response.setLoan(hostLoan);

        JAXBContext ctx = JAXBContext.newInstance(HostReturnResponse.class);
        Marshaller marshaller = ctx.createMarshaller();
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        marshaller.marshal(new com.company.library.host.schema.ObjectFactory().createHostReturnResponse(response), baos);

        Loan loan = translator.fromHostReturnResponse(baos.toByteArray());

        assertThat(loan.getId()).isEqualTo("L3");
        assertThat(loan.getUserId()).isEqualTo("U3");
        assertThat(loan.getBookId()).isEqualTo("B3");
    }

    @Test
    void fromHostReturnResponseShouldFailOnInvalidXml() {
        byte[] invalid = "<broken>".getBytes();

        assertThrows(IllegalStateException.class, () -> translator.fromHostReturnResponse(invalid));
    }
}
