package com.company.library.mapping;

import com.company.library.api.rest.dto.BorrowBookRequest;
import com.company.library.api.rest.dto.LoanResponse;
import com.company.library.domain.model.Loan;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface LoanRestMapper {

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "userId", source = "userId")
    @Mapping(target = "bookId", source = "bookId")
    Loan toDomain(BorrowBookRequest request);

    LoanResponse toResponse(Loan loan);
}
