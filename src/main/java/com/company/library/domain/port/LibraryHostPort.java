package com.company.library.domain.port;

import com.company.library.domain.model.Book;
import com.company.library.domain.model.Loan;
import com.company.library.domain.model.User;

import java.util.List;

public interface LibraryHostPort {
    User registerUser(String name);
    Loan borrowBook(String userId, String bookId);
    Loan returnBook(String userId, String bookId);
    List<Book> searchBooks(String query);
}
