package com.company.library.api.rest;

import com.company.library.infrastructure.correlation.CorrelationIdService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class CorrelationIdFilter extends OncePerRequestFilter {

    static final String HEADER_NAME = "X-Correlation-Id";

    private final CorrelationIdService correlationIdService;

    public CorrelationIdFilter(CorrelationIdService correlationIdService) {
        this.correlationIdService = correlationIdService;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
        throws ServletException, IOException {
        String incoming = request.getHeader(HEADER_NAME);
        String correlationId = (incoming == null || incoming.isBlank())
            ? correlationIdService.ensureCorrelationId()
            : incoming;
        correlationIdService.setCorrelationId(correlationId);
        response.setHeader(HEADER_NAME, correlationId);
        try {
            filterChain.doFilter(request, response);
        } finally {
            correlationIdService.clear();
        }
    }
}
