package com.company.library.mapping;

import static org.assertj.core.api.Assertions.assertThat;

import com.company.library.domain.model.Loan;
import org.junit.jupiter.api.Test;
import org.mapstruct.factory.Mappers;

class LoanHostMapperTest {

    private final LoanHostMapper mapper = Mappers.getMapper(LoanHostMapper.class);

    @Test
    void toHostRequestMapsIds() {
        Loan loan = new Loan("L1", "U1", "B1");

        var hostRequest = mapper.toHostRequest(loan);

        assertThat(hostRequest.getUser().getId()).isEqualTo("U1");
        assertThat(hostRequest.getBook().getId()).isEqualTo("B1");
    }
}
