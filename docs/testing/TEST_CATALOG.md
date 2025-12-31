# Test Catalog

This document lists all automated tests in the repository, grouped by Maven module.

## Module: library-domain

Run:

```
mvn -pl library-domain -am test
```

No automated tests in this module yet.

| Test class (FQCN) | Type | Purpose | Expected result |
| --- | --- | --- | --- |

## Module: library-web-common

Run:

```
mvn -pl library-web-common -am test
```

| Test class (FQCN) | Type | Purpose | Expected result |
| --- | --- | --- | --- |
| com.company.library.api.rest.CorrelationIdFilterTest | unit | Verifies the filter uses an incoming correlation ID header or generates a UUID when missing, and always calls the filter chain. | Response contains the expected correlation ID header and the filter chain is invoked. |

## Module: library-host-connector

Run:

```
mvn -pl library-host-connector -am test
```

| Test class (FQCN) | Type | Purpose | Expected result |
| --- | --- | --- | --- |
| com.company.library.gateway.CicsMqGatewayTemplateTest | unit | Exercises MQ request/reply flow with a mocked JmsTemplate, including selector construction, timeout handling, and exception wrapping. | Successful calls return reply bytes and timeouts restore; timeout/transport errors throw the expected exceptions. |
| com.company.library.adapters.mq.LibraryMqAdapterTest | unit | Ensures the adapter delegates to the translator and gateway with configured queues/timeouts and wraps gateway errors. | Adapter returns translated results and throws LibraryHostUnavailableException on gateway errors/timeouts. |
| com.company.library.adapters.mq.translator.JaxbLibraryMessageTranslatorTest | unit | Validates JAXB marshalling/unmarshalling for borrow/return/active-loans flows and error handling on invalid XML. | XML contains expected fields, domain objects map correctly, and invalid XML raises IllegalStateException. |
| com.company.library.mapping.LoanHostMapperTest | unit | Verifies MapStruct mapping from domain Loan to host request IDs. | Host request contains the expected user and book IDs. |
| com.company.library.mq.HostXmlSamplesXsdValidationTest | integration | Validates the XML samples in docs against the host XSD schema. | All XML samples validate successfully against the XSD. |
| com.company.library.tools.HostXmlSampleGenerator | host/ansible | Generates host XML sample request/response files used in documentation. | Running the main method writes XML files under docs/mq/examples. |

## Module: loan-command-service

Run:

```
mvn -pl loan-command-service -am test
```

| Test class (FQCN) | Type | Purpose | Expected result |
| --- | --- | --- | --- |
| com.company.library.LoanBorrowFlowIntegrationTest | integration | Exercises the /api/loans/borrow flow through the Spring MVC stack while mocking MQ gateway and translator. | POST /api/loans/borrow returns expected JSON and the adapter path is invoked with configured queues/timeouts. |
| com.company.library.ContextLoadsTest | integration | Ensures the Spring Boot application context for the command service starts. | Application context loads without errors. |
| com.company.library.OpenApiDocsTest | integration | Verifies OpenAPI docs expose the borrow endpoint. | /v3/api-docs contains /api/loans/borrow and a POST operation. |
| com.company.library.api.rest.LoanControllerTest | slice | Validates borrow/return REST endpoints with WebMvcTest, including validation errors and host-unavailable responses. | Correct HTTP status codes and error payloads are returned for each scenario. |
| com.company.library.application.LoanAppServiceTest | unit | Ensures the command application service delegates to the LibraryHostPort for borrow/return. | Returned Loan matches the host port response and the port methods are invoked. |

## Module: loan-query-service

Run:

```
mvn -pl loan-query-service -am test
```

| Test class (FQCN) | Type | Purpose | Expected result |
| --- | --- | --- | --- |
| com.company.library.ContextLoadsTest | integration | Ensures the Spring Boot application context for the query service starts. | Application context loads without errors. |
| com.company.library.api.rest.LoanQueryControllerTest | slice | Validates /api/loans/by-user responses, including validation and host-unavailable cases. | Correct HTTP status codes and JSON payloads are returned for each scenario. |
| com.company.library.application.LoanQueryServiceTest | unit | Ensures the query service delegates to the LibraryHostPort. | Returned list matches the host port response and the port method is invoked. |

## Maintenance

Rule: whenever a task adds/removes/renames tests, update this document in the same PR/commit.

Checklist:
- Update the relevant module section and run command if it changed.
- Add/remove/rename table entries to match test classes.
- Keep Purpose and Expected result accurate to current assertions.
