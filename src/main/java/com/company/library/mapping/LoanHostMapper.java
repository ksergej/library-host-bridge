package com.company.library.mapping;

import com.company.library.host.schema.HostBorrowRequest;
import com.company.library.host.schema.HostBorrowResponse;
import com.company.library.host.schema.HostLoan;
import com.company.library.host.schema.HostReturnRequest;
import com.company.library.host.schema.HostReturnResponse;
import com.company.library.domain.model.Loan;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface LoanHostMapper {

    @Mapping(target = "user.id", source = "userId")
    @Mapping(target = "book.id", source = "bookId")
    @Mapping(target = "requestedDueDate", ignore = true)
    HostBorrowRequest toHostRequest(Loan loan);

    @Mapping(target = "id", source = "loan.loanId")
    @Mapping(target = "userId", source = "loan.user.id")
    @Mapping(target = "bookId", source = "loan.book.id")
    Loan fromHostResponse(HostBorrowResponse response);

    @Mapping(target = "loanId", source = "loanId")
    HostReturnRequest toHostReturnRequest(String loanId);

    @Mapping(target = "id", source = "loan.loanId")
    @Mapping(target = "userId", source = "loan.user.id")
    @Mapping(target = "bookId", source = "loan.book.id")
    Loan fromHostReturnResponse(HostReturnResponse response);

    @Mapping(target = "id", source = "loanId")
    @Mapping(target = "userId", source = "user.id")
    @Mapping(target = "bookId", source = "book.id")
    Loan fromHostLoan(HostLoan hostLoan);
}
