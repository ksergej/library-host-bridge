package com.company.library.adapters.mq.translator;

import com.company.library.domain.model.Loan;

/**
 * Translates between domain Loan and host MQ payload.
 */
public interface LibraryMessageTranslator {

    byte[] toHostRequest(Loan loan);

    Loan fromHostResponse(byte[] responsePayload);
}
