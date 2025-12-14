package com.company.library.api.rest;

import static org.assertj.core.api.Assertions.assertThat;

import com.company.library.infrastructure.correlation.CorrelationIdService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

class CorrelationIdFilterTest {

    private CorrelationIdService correlationIdService;
    private CorrelationIdFilter filter;

    @BeforeEach
    void setUp() {
        correlationIdService = new CorrelationIdService();
        filter = new CorrelationIdFilter(correlationIdService);
    }

    @Test
    void usesExistingCorrelationIdFromHeader() throws ServletException, IOException {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.addHeader(CorrelationIdFilter.HEADER_NAME, "abc-123");
        MockHttpServletResponse response = new MockHttpServletResponse();

        FilterChain chain = Mockito.mock(FilterChain.class);

        filter.doFilter(request, response, chain);

        assertThat(correlationIdService.getCurrentCorrelationId()).isNull();
        assertThat(response.getHeader(CorrelationIdFilter.HEADER_NAME)).isEqualTo("abc-123");
        Mockito.verify(chain).doFilter(Mockito.any(HttpServletRequest.class), Mockito.any(HttpServletResponse.class));
    }

    @Test
    void generatesCorrelationIdWhenMissing() throws ServletException, IOException {
        MockHttpServletRequest request = new MockHttpServletRequest();
        MockHttpServletResponse response = new MockHttpServletResponse();
        FilterChain chain = Mockito.mock(FilterChain.class);

        filter.doFilter(request, response, chain);

        String headerValue = response.getHeader(CorrelationIdFilter.HEADER_NAME);
        assertThat(headerValue).isNotBlank();
        assertThat(UUID.fromString(headerValue)).isNotNull();
        Mockito.verify(chain).doFilter(Mockito.any(HttpServletRequest.class), Mockito.any(HttpServletResponse.class));
    }
}
