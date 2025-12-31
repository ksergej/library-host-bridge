package com.company.library;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(classes = com.company.library.loancommand.LoanCommandApplication.class)
class ContextLoadsTest {

    @Test
    void contextLoads() {
        // verifies that the Spring context starts with MQ configs present
    }
}
