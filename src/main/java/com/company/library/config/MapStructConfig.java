package com.company.library.config;

import com.company.library.mapping.LoanHostMapper;
import com.company.library.mapping.LoanRestMapper;
import org.mapstruct.factory.Mappers;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class MapStructConfig {

    @Bean
    public LoanRestMapper loanRestMapper() {
        return Mappers.getMapper(LoanRestMapper.class);
    }

    @Bean
    public LoanHostMapper loanHostMapper() {
        return Mappers.getMapper(LoanHostMapper.class);
    }
}
