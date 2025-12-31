package com.company.library.domain.model;

public class LoanRef {
    private final String loanId;
    private final String bookId;

    public LoanRef(String loanId, String bookId) {
        this.loanId = loanId;
        this.bookId = bookId;
    }

    public String getLoanId() {
        return loanId;
    }

    public String getBookId() {
        return bookId;
    }
}
