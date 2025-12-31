package com.company.library.loanquery;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication(scanBasePackages = "com.company.library")
public class LoanQueryApplication {

    public static void main(String[] args) {
        SpringApplication.run(LoanQueryApplication.class, args);
    }
}
