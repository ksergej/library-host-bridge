# Host Smoke and Debug Runbook

This runbook targets developers running real host smoke/integration tests against z/OS from the local multi-module repo.

## Preconditions (Both Variants)

1) Host listener is running and waiting for request messages (COBOL batch/JCL on z/OS).
2) DB2 schema and test data are loaded if required by the host flow.
3) MQ queues exist and match application config (request/reply names).
4) MQ correlation rule reminder: CorrelId = MsgId in MQMD (COBOL copies MQMD-MSGID to MQMD-CORRELID, clears MQMD-MSGID; Java reads JMSMessageID and selects by JMSCorrelationID).
5) No secrets in git. Use local overrides, environment variables, and `*.example.yml` files.

## Variant 1 — Maven (terminal)

Run from repo root (Maven reactor).

1) Run all unit tests:

```
mvn -U test
```

2) Start each Spring Boot service (separate terminals), with the `xplore` profile:

```
mvn -pl loan-command-service -am -DskipTests spring-boot:run -Dspring-boot.run.profiles=xplore
```

```
mvn -pl loan-query-service -am -DskipTests spring-boot:run -Dspring-boot.run.profiles=xplore
```

If you run from inside a module directory, install the reactor deps once, then start from that module:

```
mvn -pl loan-command-service -am -DskipTests install

mvn -f loan-command-service/pom.xml -DskipTests spring-boot:run \
  -Dspring-boot.run.profiles=xplore \
  -Dspring-boot.run.mainClass=com.company.library.loancommand.LoanCommandApplication
```
```
mvn -pl loan-query-service -am -DskipTests install

mvn -f loan-query-service/pom.xml -DskipTests spring-boot:run \
  -Dspring-boot.run.profiles=xplore \
  -Dspring-boot.run.mainClass=com.company.library.loanquery.LoanQueryApplication
```

If you run both services at once, pass a different port for the second app, for example:

```
mvn -f loan-query-service/pom.xml -DskipTests spring-boot:run \
  -Dspring-boot.run.profiles=xplore \
  -Dspring-boot.run.mainClass=com.company.library.loanquery.LoanQueryApplication \
  -Dspring-boot.run.arguments="--server.port=8081"
```

Note: `spring-boot:run` may invoke test-compile before starting.

3) Optional: build only (no run):

```
mvn -pl loan-command-service -am -DskipTests package
```

```
mvn -pl loan-query-service -am -DskipTests package
```

## Variant 2 — IntelliJ IDEA Debug

1) Create or edit a Run/Debug configuration for the Spring Boot module:
   - Module: `loan-command-service` (or `loan-query-service`).
   - Main class: the module’s `@SpringBootApplication`.
   - Active profiles: set to `xplore`.

2) Start the configuration in Debug mode.

3) Optional: remote debug attach (if app is started outside IntelliJ):
   - Start the JVM with JDWP, e.g.:

```
export MAVEN_OPTS="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005"
mvn -pl loan-command-service -am -DskipTests spring-boot:run -Dspring-boot.run.profiles=xplore
```

   - In IntelliJ: create “Remote JVM Debug” config pointing to localhost:5005.

4) Breakpoint suggestions (typical flow):
   - Controller → Service → Adapter → Translator → Gateway.

## Smoke Verification (curl)

Borrow (200):

```
curl -i -X POST http://localhost:8080/api/loans/borrow \
  -H 'Content-Type: application/json' \
  -H 'X-Correlation-Id: smoke-corr-1' \
  -d '{"userId":"user-1","bookId":"book-1"}'
```

Expected: HTTP 200 with JSON body containing `id`, `userId`, `bookId`.

Borrow (400 example - missing userId):

```
curl -i -X POST http://localhost:8080/api/loans/borrow \
  -H 'Content-Type: application/json' \
  -H 'X-Correlation-Id: smoke-corr-2' \
  -d '{"bookId":"book-1"}'
```

Expected: HTTP 400 with JSON body containing `error=VALIDATION_ERROR` and non-empty `correlationId`.

Return (200):

```
curl -i -X POST http://localhost:8080/api/loans/return \
  -H 'Content-Type: application/json' \
  -H 'X-Correlation-Id: smoke-corr-3' \
  -d '{"loanId":"loan-1"}'
```

Expected: HTTP 200 with JSON body containing `id`, `userId`, `bookId`.

Return (503 example - host unavailable):

```
curl -i -X POST http://localhost:8080/api/loans/return \
  -H 'Content-Type: application/json' \
  -H 'X-Correlation-Id: smoke-corr-4' \
  -d '{"loanId":"loan-1"}'
```

Expected: HTTP 503 with JSON body containing `error=HOST_UNAVAILABLE` and non-empty `correlationId`.

By-user (200):

```
curl -i -X POST http://localhost:8080/api/loans/by-user \
  -H 'Content-Type: application/json' \
  -H 'X-Correlation-Id: smoke-corr-5' \
  -d '{"userId":"user-1"}'
```

Expected: HTTP 200 with JSON body containing `userId` and a `loans` array.

By-user (400 example - missing userId):

```
curl -i -X POST http://localhost:8080/api/loans/by-user \
  -H 'Content-Type: application/json' \
  -H 'X-Correlation-Id: smoke-corr-6' \
  -d '{}'
```

Expected: HTTP 400 with JSON body containing `error=VALIDATION_ERROR` and non-empty `correlationId`.

## Maintenance

If a task changes module names, endpoints, ports, profiles, MQ property keys, Ansible host deploy paths, or smoke commands, update this doc in the same PR/commit.

Checklist:
- Update module list and mvn -pl commands.
- Update curl examples and expected responses.
- Update IntelliJ Run/Debug steps and profile names.
- Update any host/infra prerequisites or paths.
