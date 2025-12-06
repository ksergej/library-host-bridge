package com.company.library.infrastructure.tracing;

import java.util.UUID;

public class CorrelationIdFactory {

    public String newId() {
        return "LIB-" + UUID.randomUUID();
    }
}
