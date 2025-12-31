package com.company.library.application;

import com.company.library.domain.model.LoanRef;
import com.company.library.ports.LibraryHostPort;
import java.util.List;
import org.springframework.stereotype.Service;

@Service
public class LoanQueryService {

    private final LibraryHostPort libraryHostPort;

    public LoanQueryService(LibraryHostPort libraryHostPort) {
        this.libraryHostPort = libraryHostPort;
    }

    public List<LoanRef> listActiveLoansByUser(String userId) {
        return libraryHostPort.listActiveLoansByUser(userId);
    }
}
