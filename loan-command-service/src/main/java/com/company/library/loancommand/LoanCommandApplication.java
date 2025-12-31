package com.company.library.loancommand;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication(scanBasePackages = "com.company.library")
public class LoanCommandApplication {

    public static void main(String[] args) {
        SpringApplication.run(LoanCommandApplication.class, args);
    }
}
