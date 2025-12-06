package com.company.library.infrastructure.cicsmq.translator;

import com.company.library.domain.model.Book;
import com.company.library.domain.model.Loan;
import com.company.library.domain.model.User;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.util.List;

@Component
public class LibraryMessageTranslator {

    public byte[] toRequest(String operationName, Object payload) {
        String text = switch (operationName) {
            case "REGISTER_USER" -> "REG:" + payload;
            case "BORROW_BOOK" -> {
                BorrowPayload p = (BorrowPayload) payload;
                yield "BORROW:" + p.userId() + ":" + p.bookId();
            }
            case "RETURN_BOOK" -> {
                BorrowPayload p = (BorrowPayload) payload;
                yield "RETURN:" + p.userId() + ":" + p.bookId();
            }
            case "SEARCH_BOOKS" -> "SEARCH:" + payload;
            default -> throw new IllegalArgumentException("Unknown operation " + operationName);
        };
        return text.getBytes(StandardCharsets.UTF_8);
    }

    public Object fromResponse(String operationName, byte[] bytes) {
        String text = new String(bytes, StandardCharsets.UTF_8);
        return switch (operationName) {
            case "REGISTER_USER" -> new User("U1", "John Doe");
            case "BORROW_BOOK" -> new Loan("L1", "U1", "B1");
            case "RETURN_BOOK" -> new Loan("L1", "U1", "B1");
            case "SEARCH_BOOKS" -> List.of(new Book("B1", "1984", "Orwell"));
            default -> throw new IllegalArgumentException("Unknown operation " + operationName);
        };
    }

    public record BorrowPayload(String userId, String bookId) {}
}
