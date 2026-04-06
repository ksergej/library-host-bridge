# Flow_Spec_Template.md

> **Canonical Flow Specification Template**  
> Project type: **PILOT / Future SAAS Projects**  
> Purpose: Provide a **single, authoritative template** for writing  
> *Implementation‑Grade Flow Specifications (Sections 1–11)*  
> Audience: Humans, Codex, Claude, future agents

---

## How to Use This Template (Instruction for the Agent)

**Goal:**  
Fill out **all 11 sections** so that:
- the flow can be implemented **without guessing**,
- all runtime behavior is deterministic,
- failure, retries, and edge cases are explicit,
- the result is production‑grade, not conceptual.

**Rules:**
1. Do **not** skip sections.
2. Do **not** merge sections.
3. Be explicit rather than concise.
4. Prefer tables, enums, and rules over prose.
5. Assume PostgreSQL + Vault/filesystem unless stated otherwise.
6. Treat this document as the **single source of truth** for the flow.

---

# Flow <N>: <FLOW NAME>

> Status: Draft  
> Owner: <team / agent>  
> Related flows: <Flow X, Flow Y>  
> Last updated: <YYYY‑MM‑DD>

---

## 1. Purpose & Scope

### 1.1 Purpose
Explain **why this flow exists** and what problem it solves.

### 1.2 Scope (In‑Scope)
List everything explicitly handled by this flow.

### 1.3 Out of Scope
List what this flow intentionally does **not** handle (v1).

---

## 2. Actors & Components

### 2.1 Actors
List all human and system actors.

Example:
- User / Operator
- System (API)
- Background runner

### 2.2 Components
List technical components involved.

Example:
- Frontend
- FastAPI backend
- PostgreSQL
- Vault / filesystem
- External services (if any)

---

## 3. Preconditions / Assumptions

### 3.1 Preconditions
What must be true **before** the flow can start?

### 3.2 Assumptions
Design assumptions that simplify or constrain the flow.

### 3.3 Guard Rules
Explicit conditions under which the flow must refuse to operate.

---

## 4. Happy Path (Step‑by‑Step)

Describe the **standard successful execution path**.

Number every step.

Example:
1. Trigger received
2. Validation
3. Main action
4. Persistence
5. Terminal state

---

## 5. Alternate Paths

Enumerate **all non‑happy paths**.

For each alternate path:
- trigger
- system behavior
- resulting state

Examples:
- validation failure
- duplicate input
- concurrency conflict
- external dependency failure

---

## 6. State Machine

### 6.1 Primary Entity States
Define states for the main domain entity.

### 6.2 Secondary / Supporting States
Define states for sessions, jobs, runs, etc.

### 6.3 Allowed Transitions
Use tables or ASCII diagrams.

### 6.4 Invariants
Rules that must never be violated.

---

## 7. API Contracts

### 7.1 Common Rules
- schema_version
- correlation_id
- error semantics

### 7.2 Endpoints
For each endpoint:
- method + path
- request DTO
- response DTO
- error cases
- idempotency key

---

## 8. Persistence Map

### 8.1 PostgreSQL
Tables written/read and field‑level responsibility.

### 8.2 Vault / Filesystem
What files are read/written and when.

### 8.3 Derived Artifacts
Markdown, caches, previews, etc.

### 8.4 Source‑of‑Truth Rules
Explicit precedence rules.

---

## 9. Idempotency & Retry Rules

### 9.1 Idempotency Strategy
How duplicates are detected and absorbed.

### 9.2 Retry Semantics
Which errors retry, which do not.

### 9.3 Concurrency Rules
Locks, unique constraints, race handling.

---

## 10. Failure Modes & Observability

### 10.1 Failure Categories
Validation, concurrency, infra, data integrity.

### 10.2 System Response
Rollback behavior, error codes.

### 10.3 Observability
- structured logs
- audit_log events
- metrics

---

## 11. Exit Criteria

### 11.1 Functional Completion
What must work for the flow to be considered done.

### 11.2 Correctness Guarantees
State machine, idempotency, invariants.

### 11.3 Testability
Required happy‑path and edge‑case tests.

### 11.4 Explicit Non‑Goals
What is not required for completion.

---

## Final Acceptance Statement

> This flow is considered **DONE** when it can be implemented,
> tested, and operated without ambiguity, hidden state,
> or undocumented behavior.

---

End of Flow Spec Template.
