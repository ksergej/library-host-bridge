package com.company.library.tools;

import com.company.library.host.schema.HostActiveLoansByUserRequest;
import com.company.library.host.schema.HostActiveLoansByUserResponse;
import com.company.library.host.schema.HostBook;
import com.company.library.host.schema.HostBorrowRequest;
import com.company.library.host.schema.HostBorrowResponse;
import com.company.library.host.schema.HostLoan;
import com.company.library.host.schema.HostLoanRef;
import com.company.library.host.schema.HostReturnRequest;
import com.company.library.host.schema.HostReturnResponse;
import com.company.library.host.schema.HostUser;
import com.company.library.host.schema.ObjectFactory;
import jakarta.xml.bind.JAXBContext;
import jakarta.xml.bind.Marshaller;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDate;
import javax.xml.datatype.DatatypeFactory;

public final class HostXmlSampleGenerator {

    private HostXmlSampleGenerator() {
    }

    public static void main(String[] args) throws Exception {
        Path outputDir = Path.of("docs/mq/examples");
        Files.createDirectories(outputDir);

        JAXBContext context = JAXBContext.newInstance(
            HostBorrowRequest.class,
            HostBorrowResponse.class,
            HostActiveLoansByUserRequest.class,
            HostActiveLoansByUserResponse.class,
            HostReturnRequest.class,
            HostReturnResponse.class
        );
        Marshaller marshaller = context.createMarshaller();
        marshaller.setProperty(Marshaller.JAXB_FORMATTED_OUTPUT, Boolean.TRUE);

        ObjectFactory factory = new ObjectFactory();

        HostBorrowRequest request = new HostBorrowRequest();
        request.setUser(buildUser());
        request.setBook(buildBook());
        request.setRequestedDueDate(toXmlDate(LocalDate.of(2025, 1, 31)));

        HostBorrowResponse response = new HostBorrowResponse();
        HostLoan loan = new HostLoan();
        loan.setLoanId("L000000001");
        loan.setUser(buildUser());
        loan.setBook(buildBook());
        loan.setBorrowDate(toXmlDate(LocalDate.of(2025, 1, 1)));
        loan.setDueDate(toXmlDate(LocalDate.of(2025, 1, 15)));
        loan.setStatus("ACTIVE");
        response.setLoan(loan);
        response.setStatus("OK");
        response.setMessage("Loan created");

        HostReturnRequest returnRequest = new HostReturnRequest();
        returnRequest.setLoanId("L000000001");

        HostReturnResponse returnResponse = new HostReturnResponse();
        HostLoan returnLoan = new HostLoan();
        returnLoan.setLoanId("L000000001");
        returnLoan.setUser(buildUser());
        returnLoan.setBook(buildBook());
        returnLoan.setBorrowDate(toXmlDate(LocalDate.of(2025, 1, 1)));
        returnLoan.setDueDate(toXmlDate(LocalDate.of(2025, 1, 15)));
        returnLoan.setReturnDate(toXmlDate(LocalDate.of(2025, 1, 10)));
        returnLoan.setStatus("RETURNED");
        returnResponse.setLoan(returnLoan);
        returnResponse.setStatusCode("OK");
        returnResponse.setMessage("Loan returned");

        HostActiveLoansByUserRequest activeRequest = new HostActiveLoansByUserRequest();
        activeRequest.setUserId("U000000001");

        HostActiveLoansByUserResponse activeResponse = new HostActiveLoansByUserResponse();
        activeResponse.setStatusCode("OK");
        activeResponse.setMessage("Active loans returned");
        activeResponse.setUserId("U000000001");
        HostLoanRef ref1 = new HostLoanRef();
        ref1.setLoanId("L000000101");
        ref1.setBookId("B000000777");
        activeResponse.getLoan().add(ref1);
        HostLoanRef ref2 = new HostLoanRef();
        ref2.setLoanId("L000000102");
        ref2.setBookId("B000000778");
        activeResponse.getLoan().add(ref2);

        write(outputDir.resolve("host-borrow-request.xml"), marshaller, factory.createHostBorrowRequest(request));
        write(outputDir.resolve("host-borrow-response.xml"), marshaller, factory.createHostBorrowResponse(response));
        write(outputDir.resolve("host-return-request.xml"), marshaller, factory.createHostReturnRequest(returnRequest));
        write(outputDir.resolve("host-return-response.xml"), marshaller, factory.createHostReturnResponse(returnResponse));
        write(outputDir.resolve("host-active-loans-by-user-request.xml"), marshaller, factory.createHostActiveLoansByUserRequest(activeRequest));
        write(outputDir.resolve("host-active-loans-by-user-response.xml"), marshaller, factory.createHostActiveLoansByUserResponse(activeResponse));
    }

    private static HostUser buildUser() {
        HostUser user = new HostUser();
        user.setId("user-123");
        user.setName("Jane Reader");
        user.setEmail("jane.reader@example.com");
        return user;
    }

    private static HostBook buildBook() {
        HostBook book = new HostBook();
        book.setId("book-456");
        book.setTitle("Domain-Driven Design");
        book.setAuthor("Eric Evans");
        return book;
    }

    private static javax.xml.datatype.XMLGregorianCalendar toXmlDate(LocalDate date) throws Exception {
        return DatatypeFactory.newInstance().newXMLGregorianCalendar(date.toString());
    }

    private static void write(Path path, Marshaller marshaller, Object element) throws Exception {
        try (OutputStream out = Files.newOutputStream(path)) {
            marshaller.marshal(element, out);
        }
    }
}
