# Modules and Maven Commands

## Overview

This document describes the current Maven modules, their responsibilities, and the practical Maven commands for building, testing, and running them. It also includes copy/paste smoke scenarios and CI-friendly commands.

## Modules List

| Module name | Type | Main responsibilities | Depends on |
| --- | --- | --- | --- |
| library-domain | library jar | Pure domain model and ports (no Spring). | none |
| library-web-common | library jar | Shared web concerns (correlation ID, error responses, exception handling, OpenAPI config). | library-domain |
| library-host-connector | library jar | MQ gateway/adapter, JAXB translator, MapStruct host mapping, MQ config/properties, XSD contract. | library-domain, library-web-common |
| loan-command-service | Spring Boot app | Command endpoints for borrow/return, command application service. | library-domain, library-host-connector, library-web-common |
| loan-query-service | Spring Boot app | Query endpoint for active loans by user, query application service. | library-domain, library-host-connector, library-web-common |
| host-library-infra | infra | COBOL/JCL/DB2/Ansible assets for z/OS host. | n/a |

## Commands by Module

### library-domain

Build:

```
mvn -pl library-domain -am package
```

Unit tests:

```
mvn -pl library-domain -am test
```

Run app:

Not applicable (library module).

Integration tests (Failsafe):

Not configured yet.

### library-web-common

Build:

```
mvn -pl library-web-common -am package
```

Unit tests:

```
mvn -pl library-web-common -am test
```

Run app:

Not applicable (library module).

Integration tests (Failsafe):

Not configured yet.

### library-host-connector

Build:

```
mvn -pl library-host-connector -am package
```

Unit tests:

```
mvn -pl library-host-connector -am test
```

Run app:

Not applicable (library module).

Integration tests (Failsafe):

Not configured yet.

### loan-command-service

Build:

```
mvn -pl loan-command-service -am package
```

Unit tests:

```
mvn -pl loan-command-service -am test
```

Run app:

```
mvn -pl loan-command-service -am spring-boot:run
```

Run app with profile (example):

```
mvn -pl loan-command-service -am spring-boot:run -Dspring-boot.run.profiles=xplore
```

Integration tests (Failsafe):

Not configured yet.

### loan-query-service

Build:

```
mvn -pl loan-query-service -am package
```

Unit tests:

```
mvn -pl loan-query-service -am test
```

Run app:

```
mvn -pl loan-query-service -am spring-boot:run
```

Run app with profile (example):

```
mvn -pl loan-query-service -am spring-boot:run -Dspring-boot.run.profiles=xplore
```

Integration tests (Failsafe):

Not configured yet.

### host-library-infra

Build:

Not applicable (infra module).

Unit tests:

Not applicable (infra module).

Run app:

Not applicable (infra module).

Integration tests (Failsafe):

Not configured yet.

## Smoke Scenarios

### loan-command-service

Start:

```
mvn -pl loan-command-service -am spring-boot:run
```

Happy path (borrow):

```
curl -i -X POST http://localhost:8080/api/loans/borrow \
  -H 'Content-Type: application/json' \
  -d '{"userId":"user-1","bookId":"book-1"}'
```

Expected: HTTP 200 with JSON body containing `id`, `userId`, and `bookId`.

Error path (validation):

```
curl -i -X POST http://localhost:8080/api/loans/borrow \
  -H 'Content-Type: application/json' \
  -d '{"bookId":"book-1"}'
```

Expected: HTTP 400 with JSON body containing `error=VALIDATION_ERROR` and a non-empty `correlationId`.

Stop the app with Ctrl+C. Logs appear in the console where `spring-boot:run` is executed.

### loan-query-service

Start:

```
mvn -pl loan-query-service -am spring-boot:run
```

Happy path (active loans by user):

```
curl -i -X POST http://localhost:8080/api/loans/by-user \
  -H 'Content-Type: application/json' \
  -d '{"userId":"user-1"}'
```

Expected: HTTP 200 with JSON body containing `userId` and a `loans` array.

Error path (validation):

```
curl -i -X POST http://localhost:8080/api/loans/by-user \
  -H 'Content-Type: application/json' \
  -d '{}'
```

Expected: HTTP 400 with JSON body containing `error=VALIDATION_ERROR` and a non-empty `correlationId`.

Stop the app with Ctrl+C. Logs appear in the console where `spring-boot:run` is executed.

## CI-Friendly Commands

```
mvn -U test
mvn -U -DskipTests package
```

Failsafe is not configured yet, so `mvn -U verify` is not listed here.

## Maintenance

If a task adds/removes/renames modules, changes app main classes, or changes test strategy (Surefire/Failsafe), update this document in the same PR/commit.

Checklist:
- Update the modules table (name, type, responsibilities, dependencies).
- Update module command sections (build/test/run).
- Update smoke scenarios if endpoints or ports change.
- Update CI-friendly commands if test strategy changes.
