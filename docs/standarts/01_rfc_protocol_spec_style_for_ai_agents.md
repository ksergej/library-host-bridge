# RFC / Protocol-Spec Style Task Brief for AI Coding Agents (Markdown Guide)

> **Scope:** Writing *task specifications* for AI agents (e.g., Codex, Claude Code, ChatGPT) in a rigorous “RFC / protocol specification” style to reduce ambiguity and improve delivery quality.

---

## 1. What “RFC / Protocol Specification Style” Means Here

An **RFC-style task brief** is a structured, implementation-ready document that:

- Defines **scope**, **terminology**, **normative requirements**, and **acceptance criteria**.
- Uses explicit **constraints** and **edge cases** instead of implied assumptions.
- Separates **normative** statements (what must be done) from **informative** guidance (helpful context).
- Minimizes “interpretation gaps” when an AI agent executes the task.

This style is especially effective for AI coding agents because it reduces:
- Hidden assumptions
- Underspecified behavior
- Missing test expectations
- Integration surprises

---

## 2. Normative Keywords (Use Like RFC 2119/8174)

Use these keywords consistently to encode requirement strength:

- **MUST**: mandatory; failure is a bug.
- **MUST NOT**: forbidden.
- **SHOULD**: recommended; acceptable to deviate only with good reason.
- **SHOULD NOT**: discouraged.
- **MAY**: optional.
- **REQUIRED** / **OPTIONAL**: synonyms in many contexts, but prefer MUST/MAY.

**Rule:** Every requirement that can be tested should be written using MUST/MUST NOT/SHOULD.

---

## 3. Document Anatomy (Recommended Sections)

A good RFC-style task brief usually includes:

1. **Title**
2. **Status / Metadata**
3. **Abstract**
4. **Motivation / Problem Statement**
5. **Goals**
6. **Non-Goals**
7. **Scope**
8. **Assumptions**
9. **Terminology**
10. **Functional Requirements**
11. **Non-Functional Requirements**
12. **Interfaces / Contracts** (API, CLI, file formats, webhooks)
13. **Edge Cases**
14. **Observability** (logs/metrics/traces)
15. **Security / Privacy**
16. **Testing Requirements**
17. **Acceptance Criteria**
18. **Rollout / Migration Plan**
19. **Risks & Mitigations**
20. **Appendix** (examples, reference snippets)

You do not need all sections every time, but the **core** ones (Goals, Non-Goals, Requirements, Tests, Acceptance Criteria) are strongly recommended.

---

## 4. The Core Principle: Make the Agent’s “Implicit Work” Explicit

AI agents often guess. Your job is to remove the need to guess by specifying:

- **Inputs** and **outputs** (including shape, types, defaults)
- **Success** and **failure** modes
- **What not to change**
- **Test evidence** expected (files, commands, snapshots)
- **Where the code lives** and how to run it

If something matters, it MUST appear in the spec.

---

## 5. Task Brief Template (Copy/Paste)

Use this template as a starting point. Replace bracketed items.

```md
# [TASK-ID] [Short Task Title]

## Status
- Owner: [team/person]
- Target branch: [main/dev/...]
- Deadline: [optional]
- Related issues/PRs: [links]
- Affected components: [backend/frontend/infra/...]
- Compatibility: [versions, environments]

## Abstract
This document specifies the work required to [one-sentence outcome]. The agent MUST implement [summary] and MUST provide [tests/evidence].

## Motivation / Problem Statement
- Current behavior: [what happens today]
- Why it’s a problem: [impact]
- Desired behavior: [what should happen]

## Goals
- G1: ...
- G2: ...

## Non-Goals
- NG1: ...
- NG2: ...

## Scope
In-scope:
- ...
Out-of-scope:
- ...

## Assumptions
- A1: ...
- A2: ...

## Terminology
- **[Term]**: definition.
- **MUST/SHOULD/MAY**: normative keywords as used in this doc.

## Requirements

### Functional Requirements
- FR1: The system MUST ...
- FR2: The system MUST ...
- FR3: The system SHOULD ...

### Non-Functional Requirements
- NFR1: The implementation MUST NOT increase p95 latency by more than [x].
- NFR2: The solution MUST be backward compatible with [x].

## Interfaces / Contracts
### API / Webhook / CLI
- Endpoint/Command: ...
- Request: ...
- Response: ...
- Error codes: ...
- Idempotency: ...
- Backward compatibility: ...

## Edge Cases
- EC1: ...
- EC2: ...

## Observability
- Logs: MUST log [fields] at [level] when [condition].
- Metrics: SHOULD expose [metric] for [purpose].

## Security / Privacy
- SEC1: MUST validate ...
- SEC2: MUST NOT log secrets.

## Testing Requirements
- TR1: MUST add unit tests for ...
- TR2: MUST add integration test for ...
- TR3: MUST document how to run tests.

## Acceptance Criteria
- AC1: ...
- AC2: ...
- AC3: ...

## Rollout / Migration Plan
- Step 1: ...
- Step 2: ...
- Rollback: ...

## Deliverables
- D1: Code changes in ...
- D2: Tests in ...
- D3: Updated docs in ...
```

---

## 6. Writing Requirements That Are Actually Testable

Bad requirement (vague):
- “Handle errors gracefully.”

Better (testable):
- “If the upstream request returns HTTP 503, the system MUST retry up to 3 times with exponential backoff starting at 250ms, and MUST return HTTP 503 if all retries fail.”

Checklist for testable requirements:
- Can you write a unit/integration test for it?
- Does it specify *when* it happens?
- Does it specify the *observable output* (status code/log/event/file)?
- Does it specify bounds (counts, limits, timeouts)?

---

## 7. Mandatory Elements for AI-Agent Task Specs

These items dramatically increase “first-pass correctness”:

### 7.1 Constraints (MUST NOT touch / MUST preserve)
Examples:
- “The agent MUST NOT change database schema.”
- “The agent MUST preserve public function signatures.”
- “The agent MUST NOT introduce new dependencies.”

### 7.2 Evidence of Completion
Examples:
- “Agent MUST provide `pytest` output showing all tests pass.”
- “Agent MUST update OpenAPI schema and include snapshot diff.”

### 7.3 Acceptance Criteria With Concrete Signals
Examples:
- “`GET /health` returns `200` with JSON body `{status: 'ok'}`.”
- “A new unit test fails on old code and passes on new code.”

### 7.4 Non-Goals
Non-goals protect you from scope creep.
- “Do not refactor unrelated modules.”
- “Do not migrate to a new logging library.”

---

## 8. Specifying Work for Codebases: Extra Fields That Matter

### 8.1 Repo and Execution Context
- Directory: `services/api/`
- Language/runtime: Python 3.11
- Test command: `make test` or `pytest -q`
- Lint: `ruff check .`

### 8.2 File/Module Targets
- “Modify `src/webhooks/handler.py`.”
- “Add tests in `tests/test_webhook_handler.py`.”

### 8.3 Definition of Done (DoD)
A practical DoD:
- All tests pass
- New tests added for new behavior
- No linter violations
- Docs updated (if applicable)
- Backward compatibility preserved (if required)

---

## 9. How to Specify Interfaces (API / Webhook / File Format)

### 9.1 API Endpoint Spec Pattern
Provide a “contract block”:

- **Method/Path:** `POST /v1/runs`
- **Request Headers:**
  - `Content-Type: application/json` (MUST)
  - `X-Request-Id` (SHOULD)
- **Request Body:** JSON object:
  - `run_id` (string, REQUIRED, non-empty)
  - `status` (string, REQUIRED, enum: `started|succeeded|failed`)
  - `ts` (RFC3339 timestamp string, REQUIRED)
- **Response:**
  - `200 OK` with `{ "ok": true }`
- **Errors:**
  - `400` if validation fails
  - `409` if duplicate `run_id` and status conflict

### 9.2 Versioning and Backward Compatibility
Specify compatibility rules explicitly:
- “The implementation MUST accept both legacy payload `{"body": {...}}` and new flat payload `{...}` until 2026-06-01.”
- “The implementation MUST emit only the new format.”

---

## 10. Edge Cases to Always Consider (AI Agents Often Miss These)

- Empty strings vs missing fields
- Null vs missing
- Unexpected enum values
- Duplicate events / retries / idempotency keys
- Partial failures (one step succeeds, next fails)
- Timeouts and cancellation
- Pagination boundaries
- Unicode / encoding issues
- Clock skew (timestamps)
- Backward compatibility with old clients

---

## 11. Observability Requirements (Keep It Minimal But Useful)

Good observability is not “log everything”; it’s “log the right things”:

- Correlation ID: MUST log `run_id` or `request_id`
- One line per request: SHOULD log method/path/status/duration
- Errors: MUST log error category and sanitized context

Avoid:
- Logging secrets
- Huge payload dumps (unless explicitly required)

---

## 12. Testing Requirements: Specify the Shape of the Test

When you ask for tests, specify:
- Test type: unit / integration / e2e
- Failure on old code: test MUST fail before changes
- Assertions: exact fields, exact behavior
- Fixtures and mocks: allowed vs forbidden

Example:
- “Add a unit test that sends legacy payload `{"body": {"run_id": "x", ...}}` and asserts the handler returns normalized flat JSON.”
- “The test MUST assert keys exist at top level: `run_id`, `status`, `ts`.”

---

## 13. Common Anti-Patterns (What to Avoid)

- “Make it better.”
- “Fix the bug.” (without describing reproduction)
- “Optimize performance.” (without constraints/metrics)
- “Refactor as needed.” (invites scope creep)
- “Use best practices.” (too broad)

Instead:
- Define a measurable outcome
- Define exact behavior and tests
- Define forbidden changes

---

## 14. Example: Full RFC-Style Task Brief (AI Agent)

Below is an example task brief you can adapt.

```md
# TASK-P0.7A Normalize Webhook Payload and Enforce Flat Contract

## Status
- Target branch: main
- Affected components: n8n workflows + backend webhook handler
- Compatibility: MUST accept legacy and new payloads during transition

## Abstract
The system currently receives webhook events where the payload is inconsistently nested.
The agent MUST implement a normalization step and enforce a flat payload contract end-to-end.

## Motivation / Problem Statement
- Current behavior: Some clients send `{ "body": { ... } }`, others send `{ ... }`.
- Problem: Downstream steps fail due to missing keys at expected locations.
- Desired behavior: All internal processing uses a *flat* JSON object with keys at top-level.

## Goals
- G1: A normalization component produces a consistent flat payload.
- G2: Backend validates and logs minimal context for debugging.
- G3: Tests prove both legacy and new payloads are accepted.

## Non-Goals
- NG1: Do not redesign the entire workflow.
- NG2: Do not add new external dependencies.

## Terminology
- **Flat payload**: JSON object where `run_id`, `status`, `ts` exist at top-level.
- **Legacy payload**: JSON object where data may be nested under `body` or `body.body`.

## Functional Requirements
- FR1: The normalization step MUST convert any of these inputs:
  - `$json.body.body`
  - `$json.body`
  - `$json`
  into a single flat object.
- FR2: After normalization, the object MUST contain `run_id`, `status`, `ts` at top-level.
- FR3: Backend MUST reject payloads missing `run_id` with HTTP 400.
- FR4: Backend MUST log `{run_id, status}` at INFO for all accepted requests.

## Non-Functional Requirements
- NFR1: The change MUST be backward compatible for 30 days.
- NFR2: The solution MUST NOT log full request bodies.

## Testing Requirements
- TR1: Add unit test verifying legacy nested payload becomes flat.
- TR2: Add unit test verifying missing run_id yields 400.

## Acceptance Criteria
- AC1: A request with legacy payload returns 200 and is processed.
- AC2: A request with flat payload returns 200 and is processed.
- AC3: Tests pass: `pytest -q`.
```

---

## 15. Quick Checklist: “Ready to Hand to an Agent?”

Before you hand the task off, verify:

- [ ] Goals and Non-Goals are stated
- [ ] Requirements use MUST/SHOULD/MAY
- [ ] Input/output contracts are explicit
- [ ] Edge cases are listed
- [ ] Forbidden changes are listed
- [ ] Test requirements are concrete
- [ ] Acceptance criteria are measurable
- [ ] “How to run” commands exist (tests/lint/build)

---

## 16. Suggested Workflow When Collaborating With an AI Agent

1. Write the RFC-style brief.
2. Ask the agent to restate the plan as:
   - Files to change
   - Tests to add
   - Risks / open questions
3. Have the agent implement in small commits.
4. Require evidence:
   - Test output
   - Diff summary
   - Any migration notes

---

## 17. Minimal “One-Page” Version (If You Need It)

If you’re in a rush, these sections are the minimum viable set:

- Abstract
- Goals / Non-Goals
- Requirements (functional + constraints)
- Interfaces / Contracts
- Testing Requirements
- Acceptance Criteria

---

## 18. License / Notes

This guide is intended as a practical writing aid. If you already use internal templates, align naming and structure with your organization’s standards.
