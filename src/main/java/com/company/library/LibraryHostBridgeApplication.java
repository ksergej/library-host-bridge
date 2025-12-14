package com.company.library;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan
public class LibraryHostBridgeApplication {
    public static void main(String[] args) {
        SpringApplication.run(LibraryHostBridgeApplication.class, args);
    }
}
