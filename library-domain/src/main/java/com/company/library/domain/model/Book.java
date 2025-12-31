package com.company.library.domain.model;

public class Book {
    private final String id;
    private final String title;
    private final String author;

    public Book(String id, String title, String author) {
        this.id = id;
        this.title = title;
        this.author = author;
    }

    public String getId() { return id; }
    public String getTitle() { return title; }
    public String getAuthor() { return author; }
}
