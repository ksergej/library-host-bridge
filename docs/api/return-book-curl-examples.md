# Return Book API — Curl Examples

Ready-to-copy curl snippets for `POST /api/loans/return`. Replace `http://localhost:8080` with your base URL.

## Headers (common)
- `Content-Type: application/json`
- `Accept: application/json`
- `X-Correlation-Id` (optional; if omitted, backend generates one and echoes it)

## a) Successful return
```bash
curl -i -X POST "http://localhost:8080/api/loans/return" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "X-Correlation-Id: frontend-demo-123" \
  -d '{
    "loanId": "loan-789"
  }'
```

Expected HTTP 200 JSON (example):

```json
{
  "id": "loan-789",
  "userId": "user-123",
  "bookId": "book-456"
}
```
Response header: `X-Correlation-Id: frontend-demo-123` (or generated if not provided).

## b) Validation error (400 VALIDATION_ERROR)
Invalid payload example (empty loanId):

```bash
curl -i -X POST "http://localhost:8080/api/loans/return" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "loanId": ""
  }'
```

Possible HTTP 400 JSON (example):

```json
{
  "error": "VALIDATION_ERROR",
  "message": "loanId must not be blank",
  "correlationId": "generated-or-echoed-id"
}
```

## c) Host unavailable (503 HOST_UNAVAILABLE)
You can’t force this with curl alone, but a typical request is the same as success:

```bash
curl -i -X POST "http://localhost:8080/api/loans/return" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "loanId": "loan-789"
  }'
```

Example HTTP 503 JSON when host is down:

```json
{
  "error": "HOST_UNAVAILABLE",
  "message": "Host down",
  "correlationId": "generated-or-echoed-id"
}
```
