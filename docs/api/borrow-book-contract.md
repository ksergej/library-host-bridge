# Borrow Book API Contract (Frontend Facing)

This document defines the REST contract for borrowing a book via the host bridge. It is the single source of truth for frontend developers calling `POST /api/loans/borrow`.

## Endpoint
- Method: `POST`
- Path: `/api/loans/borrow`
- Content-Type: `application/json`
- Accept: `application/json`
- Header `X-Correlation-Id` (optional):
  - If provided, the backend uses it for tracing and echoes it in the response header.
  - If absent, the backend generates a correlation id and returns it in the response header.

Authentication: not required (subject to future change).

## Request Body — BorrowBookRequest
JSON body with required, non-empty fields:

```json
{
  "userId": "string",   // Identifier of the user borrowing the book
  "bookId": "string"    // Identifier of the book to borrow
}
```

Example:
```json
{
  "userId": "user-123",
  "bookId": "book-456"
}
```

## Successful Response — LoanResponse (HTTP 200)
Body:

```json
{
  "id": "string",      // Loan identifier assigned by the host
  "userId": "string",  // User identifier
  "bookId": "string"   // Book identifier
}
```
`X-Correlation-Id` header is included (either from request or generated).

Example:

```json
{
  "id": "loan-789",
  "userId": "user-123",
  "bookId": "book-456"
}
```

## Error Responses — ErrorResponse
All errors share this shape:

```json
{
  "error": "STRING_CODE",
  "message": "Human readable message",
  "correlationId": "string or null"
}
```

Relevant error codes for this endpoint:

1) Validation error  
   - HTTP 400  
   - `error = "VALIDATION_ERROR"`  
   - Triggers when `userId` or `bookId` is missing/blank (or other basic validation issues).  
   - `message` contains a short description (e.g. “userId must not be blank”).  
   - `correlationId` echoes the request id or generated id.
   
   Example:
   
   ```json
   {
     "error": "VALIDATION_ERROR",
     "message": "userId must not be blank",
     "correlationId": "b8e6b8b3-5b4f-4b2a-9b8d-123456789abc"
   }
   ```

2) Host unavailable  
   - HTTP 503  
   - `error = "HOST_UNAVAILABLE"`  
   - Occurs when the library host (MQ/COBOL/DB2) cannot be reached or times out.  
   - `message` contains a brief reason (e.g. “Host down” / “Failed to call host”).  
   - `correlationId` echoes the request id or generated id.

   Example:
   
   ```json
   {
     "error": "HOST_UNAVAILABLE",
     "message": "Host down",
     "correlationId": "b8e6b8b3-5b4f-4b2a-9b8d-123456789abc"
   }
   ```

Note: Other unexpected errors may be mapped to 500 in the future if needed (not part of current contract).

## Behaviour
- Synchronous: the client receives a response only after the host/MQ call completes or fails.
- Idempotency: not strictly defined at this time.
- Correlation: `X-Correlation-Id` is propagated and returned for tracing; also forwarded internally to MQ as a JMS property.
- Frontend only needs to follow this REST contract; host-side MQ/COBOL details are internal.

## See also
- `docs/api/borrow-book-curl-examples.md` — ready-to-copy curl calls.
- `docs/frontend/borrowBookClient.ts` — minimal JS/TS fetch client example.
