Task: TEST-CATALOG — Create docs test catalog by area + enforce future updates

Read
- AGENTS.md
- PROJECT_CONTEXT.md
- PROJECT_Test_Scenarios_and_Acceptance.md (ported acceptance scenarios)
- Repo test sources:
  - backend/tests/** (pytest)
  - any other test dirs (e.g., frontend/**, infra/**) if present
Rules
- Do NOT modify any PROJECT_TODO_*.md.
- Do NOT add secrets to git.
- Before applying changes:
  - Write FULL diff to artifacts/diffs/full.diff
  - Paste artifacts/diffs/diff_stat.txt + artifacts/diffs/diff_files.txt
- After applying changes:
  - Run required commands and paste outputs.

Objective
Create a single, Owner-friendly catalog of all automated tests in the repo, grouped by area (backend/frontend/infra) and aligned with how we run tests in Docker for determinism. Enforce maintenance so the catalog stays up to date whenever tests change.

Requirements

1) Create a new Markdown document
- Path: docs/testing/TEST_CATALOG.md
- Content goal: list ALL current automated tests, grouped by project area:
  - Backend (pytest)
  - Frontend (if any tests exist; otherwise explicitly state “no automated tests yet”)
  - Infra / n8n / scripts (if any tests exist; otherwise explicitly state “none”)
- If the repo is expected to evolve to multi-service/module structure, add a short TODO note:
  “Will be regrouped by modules/services if/when the repo splits further.”

2) For each area section include
- How to run tests for that area (canonical commands)
  Backend MUST use Docker (deterministic):
  - docker compose run --rm backend python -m ruff check .
  - docker compose run --rm backend python -m ruff format --check .
  - docker compose run --rm backend python -m pytest -q
  - (if Alembic is relevant to tests) docker compose run --rm backend python -m alembic upgrade head
  Frontend: include the correct command(s) if tests exist (e.g., npm test), otherwise say “none”.
- A table with columns:
  - Test file / test id (e.g., backend/tests/test_x.py::test_y)
  - Type (unit / integration / e2e-smoke)
  - Purpose (1–2 sentences, derived from what the test asserts)
  - Expected result (plain-English pass criteria)

3) Derive “Purpose” from code
- Read each test and describe what it validates (endpoints, DB invariants, migrations, idempotency, etc.).
- Keep concise but specific.
Examples of good “Purpose”:
- “Asserts /uploads appears in OpenAPI schema (regression guard for python-multipart + route registration).”
- “Verifies alembic upgrade creates pilot_shakedown_runs and SELECT works.”

4) Add a “Maintenance” section at the bottom of docs/testing/TEST_CATALOG.md
- Rule: whenever a PR/commit adds/removes/renames tests, update this document in the same change.
- Include a short checklist:
  - Add/remove entries for changed tests
  - Ensure run commands remain correct
  - Keep Type/Purpose/Expected result accurate
  - Keep grouping consistent (Backend/Frontend/Infra)

5) Update AGENTS.md (minimal diff) to enforce maintenance
- Add one bullet under Golden Rules / Definition of Done (whichever exists):
  “If you add/remove/rename tests, update docs/testing/TEST_CATALOG.md accordingly.”

Acceptance Criteria (PASS)
- docs/testing/TEST_CATALOG.md exists and is valid Markdown.
- It lists every current automated test:
  - At minimum, all pytest tests under backend/tests/** (and any other pytest dirs if present)
  - Any frontend/infra tests if they exist
- Test run remains green:
  - docker compose run --rm backend python -m ruff check .
  - docker compose run --rm backend python -m ruff format --check .
  - docker compose run --rm backend python -m pytest -q

Required Commands (paste outputs)
- docker compose run --rm backend python -m ruff check .
- docker compose run --rm backend python -m ruff format --check .
- docker compose run --rm backend python -m pytest -q

Deliverables
- artifacts/diffs/full.diff (+ diff_stat.txt + diff_files.txt pasted)
- docs/testing/TEST_CATALOG.md with complete catalog + maintenance section
- AGENTS.md updated with the maintenance rule
- Command outputs pasted

