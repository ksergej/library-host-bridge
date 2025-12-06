package com.company.library.infrastructure.cicsmq.adapter;

import com.company.library.domain.model.Book;
import com.company.library.domain.model.Loan;
import com.company.library.domain.model.User;
import com.company.library.domain.port.LibraryHostPort;
import com.company.library.infrastructure.cicsmq.gateway.CicsMqGatewayTemplate;
import com.company.library.infrastructure.cicsmq.translator.LibraryMessageTranslator;
import com.company.library.infrastructure.tracing.CorrelationIdFactory;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.stereotype.Component;

import jakarta.jms.JMSException;
import java.util.List;

@Component
public class LibraryMqAdapter extends CicsMqGatewayTemplate implements LibraryHostPort {

    private final LibraryMessageTranslator translator;

    public LibraryMqAdapter(JmsTemplate jmsTemplate,
                            CorrelationIdFactory correlationIdFactory,
                            LibraryMessageTranslator translator) {
        super(jmsTemplate, correlationIdFactory);
        this.translator = translator;
    }

    @Override
    public User registerUser(String name) {
        return execute("REGISTER_USER", name);
    }

    @Override
    public Loan borrowBook(String userId, String bookId) {
        return execute("BORROW_BOOK", new LibraryMessageTranslator.BorrowPayload(userId, bookId));
    }

    @Override
    public Loan returnBook(String userId, String bookId) {
        return execute("RETURN_BOOK", new LibraryMessageTranslator.BorrowPayload(userId, bookId));
    }

    @Override
    public List<Book> searchBooks(String query) {
        return execute("SEARCH_BOOKS", query);
    }

    @SuppressWarnings("unchecked")
    @Override
    protected <T> T doCall(String operationName,
                           String correlationId,
                           Object payload) throws JMSException {

        byte[] requestBytes = translator.toRequest(operationName, payload);
        String requestQueue = "LIB.REQ." + operationName;
        String replyQueue = "LIB.REP." + operationName;
        byte[] responseBytes = sendAndReceiveBytes(requestQueue, replyQueue, requestBytes, correlationId);
        return (T) translator.fromResponse(operationName, responseBytes);
    }
}
