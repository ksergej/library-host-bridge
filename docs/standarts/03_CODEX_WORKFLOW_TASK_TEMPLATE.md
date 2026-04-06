 CODEX WORKFLOW PACKET — Template (Project: library-host-bridge)

> This is a **copy/paste-ready** packet for Codex work in this repo.
> Use it for each task to keep changes predictable and reviewable.

---

## 1) Required files Codex must read first

1. `AGENTS.md`  
2. `PROJECT_CONTEXT.md`  
3. `PROJECT_TODO_*.md`

**Rule:** Codex must not modify `PROJECT_TODO_*.md`.  
**Rule:** `AGENTS.md` may be updated **only** when a task explicitly includes “enforce maintenance” or similar.

---

## 2) Standard Definition of Done for every task

1. **Before applying:** show **FULL diff** of all touched files (new + modified + deleted).
2. **After applying:** run from repo root:
   ```bash
   mvn -U test
   ```
   and paste the **summary** (tests run / failures / errors / skipped + BUILD SUCCESS/FAILURE).
3. Keep packages stable unless the task explicitly requires package changes.
4. No secrets committed. Use `*.example.yml` + local overrides and `.gitignore`.

---

## 3) Canonical documentation paths (must stay in sync)

- Tests catalog (by module): `docs/testing/TEST_CATALOG.md`  *(P21.1)*
- Modules + MVN commands runbook: `docs/runbooks/MODULES_AND_MVN_COMMANDS.md` *(P21.2)*
- Root README: `README.md` *(P21.3)*
- Host smoke + IntelliJ debug runbook: `docs/runbooks/HOST_SMOKE_AND_DEBUG.md` *(P21.4)*

---

## 4) Documentation tasks (P21.*)

### 4.1 Task: P21.1-TEST-CATALOG

**Goal:** Create a single Markdown catalog of all automated tests, grouped by Maven module, with purpose + expected result.

**Spec (must include):**
- Path: `docs/testing/TEST_CATALOG.md`
- For each module section:
  - How to run that module’s tests:
    ```bash
    mvn -pl <module> -am test
    ```
  - A table:
    - Test class (FQCN)
    - Type (unit / slice / integration / host/ansible)
    - Purpose (1–2 sentences, derived from asserts/mocks/requests)
    - Expected result (pass criteria)
- “Maintenance” section: update this doc whenever tests change.
- Enforce maintenance in `AGENTS.md` (minimal diff):
  - “If tests change, update `docs/testing/TEST_CATALOG.md`.”

---

### 4.2 Task: P21.2-MODULE-RUNBOOK

**Goal:** Document all modules + all practical `mvn` commands to build/test/run them for smoke/integration.

**Spec (must include):**
- Path: `docs/runbooks/MODULES_AND_MVN_COMMANDS.md`
- Sections:
  1) Overview  
  2) Modules list (table: module, type, responsibilities, depends on)  
  3) Commands by module:
     - Build: `mvn -pl <module> -am package`
     - Unit tests: `mvn -pl <module> -am test`
     - Run service module:
       ```bash
       mvn -pl <service-module> -am -DskipTests spring-boot:run -Dspring-boot.run.profiles=xplore
       ```
     - If Failsafe is configured: document `mvn verify`, otherwise add note “Not configured yet”.
  4) Smoke scenarios (copy/paste):
     - start command + 1–3 curl calls per service + expected 200/400/503
  5) CI-friendly commands (root):
     - `mvn -U test`
     - `mvn -U -DskipTests package`
     - `mvn -U verify` (if used)
- “Maintenance” section + checklist.
- Enforce maintenance in `AGENTS.md` (minimal diff):
  - “If modules/run/test commands change, update `docs/runbooks/MODULES_AND_MVN_COMMANDS.md`.”

---

### 4.3 Task: P21.3-ROOT-README

**Goal:** Create/update root `README.md` with architecture overview + how to build/test/run + host/infra quickstart.

**Spec (must include):**
- Architecture overview (Spring Boot ⇄ MQ ⇄ z/OS COBOL ⇄ DB2) + ASCII diagram
- Modules table (name/type/responsibility/one command)
- Prerequisites (Java/Maven)
- Build & Test commands (root + per-module examples)
- Run locally:
  - command service + query service
  - profiles example (`xplore`)
  - secret handling (no committed passwords)
- API quickstart (curl for borrow/return/by-user)
- Host/Infra quickstart (where `host-library-infra/` is + Ansible smoke command)
- Docs index
- Security note + incident response basics
- “Maintenance” section
- Enforce maintenance in `AGENTS.md` (minimal diff):
  - “If modules/endpoints/commands/workflows change, update `README.md`.”

---

### 4.4 Task: P21.4-HOST-SMOKE-AND-DEBUG-RUNBOOK

**Goal:** A runbook for real host smoke/integration testing, with two variants:
1) Maven (terminal)
2) IntelliJ IDEA Debug

**Spec (must include):**
- Path: `docs/runbooks/HOST_SMOKE_AND_DEBUG.md`
- Variant 1 — Maven:
  - Reactor note: run from repo root
  - Start each service module in separate terminal:
    ```bash
    mvn -pl <service-module> -am -DskipTests spring-boot:run -Dspring-boot.run.profiles=xplore
    ```
- Variant 2 — IntelliJ Debug:
  - Run/Debug config + active profile “xplore”
  - Optional remote attach (JDWP) steps
  - Suggested breakpoints (controller → app → adapter → translator → gateway)
- Common host preconditions checklist:
  - host listener/job waiting on request queue
  - DB2 schema/data loaded (if required)
  - MQ queues exist and match app config
  - Correlation rule reminder: CorrelId=MsgId lives in MQMD
  - No secrets in git
- Curl smoke verification:
  - borrow / return / by-user with X-Correlation-Id header
  - expected 200 and one error example (400/503)
- “Maintenance” section + checklist
- Enforce maintenance in `AGENTS.md` (minimal diff):
  - “If host smoke/debug workflow changes, update `docs/runbooks/HOST_SMOKE_AND_DEBUG.md`.”

---

## 5) Copy/paste task skeleton (use for any future task)

```text
Task: <ID> — <short title>

Read AGENTS.md, PROJECT_CONTEXT.md, PROJECT_TODO_*.md.
Rules:
- Do NOT modify PROJECT_TODO_*.md.
- Before applying show FULL diff of all touched files.
- After applying run mvn -U test from repo root and show results.

Requirements:
1) <requirement>
2) <requirement>
3) <requirement>

Acceptance:
- mvn -U test passes.
- <extra acceptance criteria>
```

---

## 6) Multi-module command quick reference

- Run all tests in reactor:
  ```bash
  mvn -U test
  ```
- Run a single module + its dependencies:
  ```bash
  mvn -pl <module> -am test
  ```
- Run a service module (single app process):
  ```bash
  mvn -pl <service-module> -am -DskipTests spring-boot:run -Dspring-boot.run.profiles=xplore
  ```

---

## 7) Changelog

- Updated template to include P21.1–P21.4 documentation tasks and their exact target paths.
