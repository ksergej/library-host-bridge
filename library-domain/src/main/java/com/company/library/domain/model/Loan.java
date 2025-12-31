package com.company.library.domain.model;

public class Loan {
    private final String id;
    private final String userId;
    private final String bookId;

    public Loan(String id, String userId, String bookId) {
        this.id = id;
        this.userId = userId;
        this.bookId = bookId;
    }

    public String getId() {
        return id;
    }

    public String getUserId() {
        return userId;
    }

    public String getBookId() {
        return bookId;
    }
}
