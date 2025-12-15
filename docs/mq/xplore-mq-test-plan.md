# Xplore MQ / Host Integration — Test Plan (Design)

## 1. Environment assumptions
- IBM Z Xplore host provides IBM MQ queues for the library system.
- Request/reply queues exist (names TBD; placeholders below).
- The Java app (library-host-bridge) reaches MQ over network (host/port/channel/queue-manager).

## 2. Profiles and configuration
- Use Spring profile `xplore`.
- MQ connection properties come from `application-xplore.yml` (placeholders):
  - `mq.connection.host`, `port`, `channel`, `queue-manager`, `user`, `password`.
- Real credentials/secrets must be supplied via environment variables or external config (not committed).

## 3. Manual smoke tests
1) Start the app with the Xplore profile:

   ```
   java -jar target/library-host-bridge-0.0.1-SNAPSHOT.jar \
     --spring.profiles.active=xplore
   ```
2) Send a borrow request (example from docs/api/borrow-book-curl-examples.md):

   ```
   curl -X POST "http://localhost:8080/api/loans/borrow" \
     -H "Content-Type: application/json" \
     -H "Accept: application/json" \
     -d '{"userId":"user-123","bookId":"book-456"}'
   ```
3) Observe logs:
   - Outbound MQ call with CorrelationId property.
   - If host responds, HTTP 200 with LoanResponse.
   - On timeout/unavailability, HTTP 503 with ErrorResponse.

## 4. Future automated tests (not enabled by default)
- Potential `@SpringBootTest` suite guarded by:
  - `@ActiveProfiles("xplore")`
  - Conditional flag/env var to require real MQ.
- Tests would:
  - Use real ConnectionFactory/JmsTemplate for IBM MQ.
  - Send a borrow request end-to-end and assert host reply or timeout handling.
- Such tests must be excluded from default CI to avoid external dependency failures.
