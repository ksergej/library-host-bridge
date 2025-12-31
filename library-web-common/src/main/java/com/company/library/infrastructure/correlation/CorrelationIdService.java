package com.company.library.infrastructure.correlation;

import java.util.UUID;
import org.slf4j.MDC;
import org.springframework.stereotype.Component;

@Component
public class CorrelationIdService {

    private static final String CORRELATION_ID_KEY = "correlationId";

    public String getCurrentCorrelationId() {
        return MDC.get(CORRELATION_ID_KEY);
    }

    public String ensureCorrelationId() {
        String current = getCurrentCorrelationId();
        if (current == null || current.isBlank()) {
            current = UUID.randomUUID().toString();
            setCorrelationId(current);
        }
        return current;
    }

    public void setCorrelationId(String correlationId) {
        MDC.put(CORRELATION_ID_KEY, correlationId);
    }

    public void clear() {
        MDC.remove(CORRELATION_ID_KEY);
    }
}
