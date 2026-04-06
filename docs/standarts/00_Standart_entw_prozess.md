# Standard Dev Process (for Coding Agents) — RainbowTrainer

This document is the **canonical “how to work”** playbook for any coding agent in this repo (Codex, Claude, Cursor, etc.).
It describes the **required sequence** for implementing work in RainbowTrainer:

1) Read relevant Flow + TODO docs  
2) Create a task doc in `docs/flows_todo/tasks/` (using the template style)  
3) Implement the task  
4) Run tests / lint (as required)  
5) Save a full diff to `.tmp/diff/...`  
6) Commit

If you follow this file, your work will be predictable, reviewable, and easy to resume after restarts.

---

## 0) Non‑negotiable rules (project contracts)

### A) Do not edit TODO master files
- **Do NOT modify** any `PROJECT_TODO_*.md` / `*_TODO_*.md` files.
- Instead: create a **new task file** under `docs/flows_todo/tasks/`.

### B) “No magic words” policy (Enums)
- Any bounded set of values (status/type/mode/kind/error_code/etc.) **must** be an Enum:
  - Define in `src/app/enums.py`
  - Register in `src/app/enums_registry.py::_required_values()`
  - Add/adjust tests
- Do **not** introduce new string codes directly in code or prompts.

### C) Docs maintenance contract
- If you change **Flow 01** behavior → update `docs/runbooks/runbook-flow-01.md`
- If you change **Flow 02** behavior → update `docs/runbooks/runbook-flow-02.md`
- Any new test → add it to `docs/tests/tests-index.md` with a copy‑pastable command.

### D) Determinism & “no heuristics” (when specified)
Some Flow01 tasks explicitly require:
- Deterministic output (`same input -> same output`)
- **No heuristics** (only use explicit MusicXML data; do not infer missing mapping)
Follow the task file’s rules.

---

## 1) Required working sequence (always)

### Step 1 — Read required docs first

At minimum, read:
- `AGENTS.md`
- the Flow document(s) for the current scope (e.g. `docs/flows_todo/Flow_01_*.md`, `docs/flows_todo/Flow_02_*.md`)
- the relevant `docs/flows_todo/tasks/FLOWnn-*.md` if it already exists

If the user points you at a specific design doc (example: `FLOW01-P0-MidiTechniqueBends.md`) — **read that file first** and treat it as the source of truth.

### Step 2 — Create a task doc (before coding)

Before changing any code, create a task file:

`docs/flows_todo/tasks/<TASK_ID>.md`

The task doc must be self‑contained so another agent can pick it up later without re-reading the whole chat.

#### Task doc structure (required)

Use this structure (keep it short but complete):

```text
Task: <ID> — <short title>

Context:
<why we do this / what’s broken>

Read these files first:
- <file>
- <file>

Rules:
- Do NOT modify any PROJECT_TODO_*.md / *_TODO_*.md files.
- Diff workflow: save FULL diff to .tmp/diff/<timestamp-or-task-id>.diff; do NOT print diff hunks.
- After applying: run <tests> and show summary.
- (task-specific constraints, e.g. “No heuristics”, “Deterministic output”)

Goal:
<what should be true after finishing>

Requirements (implement exactly):
1) ...
2) ...

Tests (required):
<what to add/adjust>

Acceptance:
- <observable outcomes>
- <tests pass>
```

#### Example task doc (Flow01 MIDI)

```text
Task: FLOW01-P1-MidiProgramChange_SteelGuitar — Emit GM Program Change (Acoustic Guitar steel) in generated MIDI

Context:
External MIDI tools show “Acoustic Piano” because we don’t emit Program Change.

Read these files first:
- AGENTS.md
- docs/runbooks/runbook-flow-01.md
- src/rainbowtrainer/midi_builder.py

Rules:
- Do NOT modify any PROJECT_TODO_*.md / *_TODO_*.md files.
- Deterministic output.
- Diff workflow: save FULL diff to .tmp/diff/...; do NOT print diff hunks.
- After applying: TMPDIR=./.tmp PYTHONPATH=src pytest -q

Requirements:
1) Emit Program Change at tick=0 with program=25 (0-based GM).
2) Program Change must occur before first note-on at tick 0.
3) Applies to full/bg/solo.
4) Add unit test asserting presence of 0xC0 + 25.

Acceptance:
- Opening playback_solo.mid in GuitarPro shows steel guitar, not piano.
- pytest passes.
```

### Step 3 — Implement the task (minimal, focused diff)

Implementation guidance:
- Fix the root cause; avoid “surface” patches.
- Prefer small helpers over long functions.
- Use type hints for public functions.
- Keep changes within scope; don’t refactor unrelated code.

#### Example (small code snippet)

Adding a MIDI Program Change (illustrative):

```py
def _encode_program_change(program: int) -> bytes:
    clamped = max(0, min(127, int(program)))
    return bytes([0xC0 | DEFAULT_CHANNEL, clamped])
```

### Step 4 — Test & validate

#### Backend (Flow01) standard commands

From repo root:

```bash
source .venv/bin/activate
PYTHONPATH=src TMPDIR=./.tmp pytest -q
ruff check .
ruff format .
```

If `pytest` cannot find imports, ensure:
- You are in the repo root
- You set `PYTHONPATH=src`

If a task adds tests, update:
- `docs/tests/tests-index.md`

#### Frontend (Flow02) standard commands

```bash
cd apps/web
npm test
```

If there are no tests, add a small manual smoke checklist to the runbook and verify it.

### Step 5 — Save full diff to `.tmp/diff/...` (required)

Do **not** paste diff hunks into chat output. Instead:

```bash
mkdir -p .tmp/diff
ts=$(date +%Y%m%dT%H%M%S)
diff_path=".tmp/diff/<TASK_ID>_${ts}.diff"
git diff > "$diff_path"
echo "$diff_path"
git diff --name-only
```

If you want the exact committed diff:

```bash
git add <files...>
git diff --cached > "$diff_path"
git diff --cached --name-only
```

### Step 6 — Commit

Commit after:
- Tests pass
- Runbooks (if needed) updated
- `docs/tests/tests-index.md` updated (if tests were added/changed)
- Diff is saved in `.tmp/diff/...`

Commit message convention (examples):
- `FLOW01-P0-TabStaffTechnicalMerge`
- `FLOW01-P0-MidiTechniqueBends`
- `FLOW02-P1-LeftHandedFretboardMirror`

---

## 2) Review workflow (how to handle reviewer comments)

When the user pastes review comments:
1) Copy the comments into your plan (P1/P2 etc.)
2) Fix P1 items first (correctness / broken behavior)
3) Add/adjust tests that would have caught the issue
4) Update runbooks if behavior changed
5) Save diff → run tests → commit

Example fixes:
- Playback clock stalls because RAF loop bails early → make clock derived from AudioContext time and ensure update loop starts deterministically.
- Fetch hits Next instead of backend → use `NEXT_PUBLIC_API_BASE_URL` and/or rewrites.
- Timeline fetch failure leaves stale UI state → clear markers on error.

---

## 3) Flow‑specific notes (practical)

### Flow 01 (backend): artifacts and determinism
- Artifacts live under: `storage/{document_id}/artifacts/`
- `timeline.json` is the canonical derived representation.
- MIDI artifacts:
  - `playback_full.mid`
  - `playback_bg.mid`
  - `playback_solo.mid`
- If the task changes artifact generation rules, ensure the endpoint behavior remains consistent and tests cover regeneration/invalidation rules.

### Flow 02 (frontend): authoritative clock contract
- `currentTimeMs` is the single source of truth.
- UI may use `requestAnimationFrame` for redraws, but time must be derived from AudioContext (no drift).
- If you change UI behavior, update `docs/runbooks/runbook-flow-02.md` and add smoke checks.

---

## 4) Common pitfalls (what to avoid)

- Committing `node_modules/` or other build artifacts.
- Adding new string codes without Enum registration.
- Forgetting to update runbooks after changing flow behavior.
- Adding tests without registering them in `docs/tests/tests-index.md`.
- “Heuristic” guitar mapping when the task explicitly forbids it.
- Printing diffs in the chat (use `.tmp/diff/...` instead).

---

## 5) Quick checklist (copy/paste)

```text
[ ] Read AGENTS.md + relevant Flow doc(s)
[ ] Create task doc in docs/flows_todo/tasks/
[ ] Implement minimal code changes
[ ] Add/adjust tests (+ update docs/tests/tests-index.md)
[ ] Update runbook-flow-01/02 if needed
[ ] Save FULL diff to .tmp/diff/<task>_<ts>.diff (don’t paste hunks)
[ ] Run: PYTHONPATH=src TMPDIR=./.tmp pytest -q (and ruff)
[ ] Commit
```

