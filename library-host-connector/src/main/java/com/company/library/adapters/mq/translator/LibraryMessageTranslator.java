package com.company.library.adapters.mq.translator;

import com.company.library.domain.model.Loan;
import com.company.library.domain.model.LoanRef;
import java.util.List;

/**
 * Translates between domain Loan and host MQ payload.
 */
public interface LibraryMessageTranslator {

    byte[] toHostRequest(Loan loan);

    Loan fromHostResponse(byte[] responsePayload);

    byte[] toHostReturnRequest(String loanId);

    Loan fromHostReturnResponse(byte[] responsePayload);

    byte[] toHostActiveLoansByUserRequest(String userId);

    List<LoanRef> fromHostActiveLoansByUserResponse(byte[] responsePayload);
}
