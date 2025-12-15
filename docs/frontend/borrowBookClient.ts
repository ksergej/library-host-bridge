export interface BorrowBookRequest {
  userId: string;
  bookId: string;
}

export interface LoanResponse {
  id: string;
  userId: string;
  bookId: string;
}

export interface ErrorResponse {
  error: string;
  message: string;
  correlationId: string | null;
}

export async function borrowBook(
  baseUrl: string,
  request: BorrowBookRequest,
  correlationId?: string
): Promise<LoanResponse> {
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    Accept: "application/json",
  };
  if (correlationId) {
    headers["X-Correlation-Id"] = correlationId;
  }

  const response = await fetch(`${baseUrl}/api/loans/borrow`, {
    method: "POST",
    headers,
    body: JSON.stringify(request),
  });

  const text = await response.text();
  const contentType = response.headers.get("content-type") || "";
  const isJson = contentType.includes("application/json");
  const parsed = isJson && text ? JSON.parse(text) : null;

  if (response.ok) {
    return parsed as LoanResponse;
  }

  const error: ErrorResponse = parsed ?? {
    error: "UNKNOWN_ERROR",
    message: text || "Unknown error",
    correlationId: null,
  };
  throw error;
}

// Example usage:
// borrowBook("http://localhost:8080", { userId: "user-123", bookId: "book-456" }, "frontend-demo-123")
//   .then(console.log)
//   .catch(err => console.error("Borrow failed", err));
