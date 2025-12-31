package com.company.library.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI libraryHostBridgeOpenAPI() {
        return new OpenAPI()
            .info(new Info()
                .title("Library Host Bridge API")
                .version("0.1.0")
                .description("REST facade for library host (borrow book via MQ/COBOL/DB2)")
            );
    }
}
