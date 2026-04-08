# Flow Templates and Authoring Rules

Status: active

## 1) Purpose

This file defines:
- standard template types;
- when to use each template;
- mandatory authoring rules for new docs;
- target destination paths for created documents.

## 2) Template Catalog (Current Folder)

### A. Development process playbook
- Template: `00_Standart_entw_prozess.md`
- Use when: defining how agents execute flow work block-by-block from `todo.md`.
- Output type: process guide.

### B. RFC / protocol style brief
- Template: `01_rfc_protocol_spec_style_for_ai_agents.md`
- Use when: writing strict normative requirements (`MUST/SHOULD/MAY`).
- Output type: implementation-ready requirement language.

### C. Flow specification methodology
- Template: `021_Flow_Specification_Methodology.md`
- Use when: documenting rationale for 11-section flow specs.
- Output type: reference/methodology doc.

### D. Canonical Flow spec (11 sections)
- Template: `02_Flow_Spec_Template.md`
- Use when: creating a new authoritative flow spec.
- Output type: `spec` document for one flow.

### E. Codex workflow packet (todo-block mode)
- Template: `03_CODEX_WORKFLOW_TASK_TEMPLATE.md`
- Use when: preparing execution packets where `todo.md` blocks are the primary implementation units.
- Output type: execution packet template.

### F. PROJECT_CONTEXT_CHIT protocol
- Template: `PROJECT_CONTEXT_CHIT_COMMIT.md`
- Use when: documenting checkpoint/changelog meta-protocol.
- Output type: protocol/reference doc.

## 3) Standard Document Types

1. Flow Spec (authoritative behavior):
- Destination: `docs/flows/flow-XX/spec/`
- Preferred name: `FLOW-XX_<SHORT_NAME>.md`

2. Flow TODO (authoritative execution plan):
- Destination: `docs/flows/flow-XX/todo/todo.md`
- Rule: this file MUST contain all implementation detail, checks, acceptance and reject criteria per block.
- Rule: by default, no separate task doc per TODO item.

3. Flow tasks folder (`docs/flows/flow-XX/tasks/`):
- Optional.
- Use only when explicitly requested by owner/reviewer for a special case.

4. Flow Runbook (operational execution guide):
- Destination: `docs/runbooks/runbook-flow-XX.md`
- Rule: each active flow SHOULD have one runbook with copy-pastable commands,
  expected results, and troubleshooting notes.

5. Methodology / Protocol / Process:
- methodology -> `021_Flow_Specification_Methodology.md`
- process -> `00_Standart_entw_prozess.md`
- protocol -> `PROJECT_CONTEXT_CHIT_COMMIT.md`

## 4) Mandatory Header for New Flow Docs

Every new flow doc MUST start with:
- title
- `Status: draft|active|in_progress|done|archived`
- `Updated` or `Last updated` with date (`YYYY-MM-DD`)
- short scope/context

For `todo.md`, each execution block MUST include:
- `Goal`
- `Scope`
- `Required tests/checks`
- `Acceptance criteria`
- `Reject conditions`

## 5) Authoring Rules (Must Follow)

1. No ambiguous wording:
- prefer deterministic statements.
- use MUST/SHOULD for testable behavior.

2. No hidden scope:
- include explicit out-of-scope list.

3. No orphan docs:
- link related spec/runbook files.

4. No undocumented completion:
- `done` status requires validation command(s) and observed result.

5. No legacy naming for new files:
- do not create ad-hoc names like `Flow_`, `_v2`, mixed-case random patterns.

## 6) Minimal Creation Checklist

Before creating/updating flow docs:
1. Confirm flow spec path (`docs/flows/flow-XX/spec/...`).
2. Ensure `docs/flows/flow-XX/todo/todo.md` exists.
3. Ensure flow runbook exists (`docs/runbooks/runbook-flow-XX.md`) or plan it as
   an explicit TODO block.
4. Put full executable criteria into TODO blocks (not separate per-point tasks).
5. Add/refresh links to runbooks and tests.
6. Keep naming consistent and stable.

---

If a flow-specific runbook is stricter, it may add rules but must not weaken these rules.
