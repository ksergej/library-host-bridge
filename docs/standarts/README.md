# Flow Templates and Authoring Rules

Status: draft (for review)

## 1) Purpose

This file defines:
- standard template types;
- when to use each template;
- mandatory authoring rules for new docs;
- target destination paths for created documents.

Use this file together with:
- `docs/project/documentation-governance.md`

## 2) Template Catalog (Current Folder)

### A. Development process playbook
- Template: `00_Standart_entw_prozess.md`
- Use when: writing/refreshing the agent execution process (read docs -> create task -> implement -> test -> diff -> commit).
- Output type: process guide.

### B. RFC / protocol style brief
- Template: `01_rfc_protocol_spec_style_for_ai_agents.md`
- Use when: preparing strict, normative task briefs with MUST/SHOULD/MAY rules.
- Output type: implementation-ready requirement spec.

### C. Flow specification methodology
- Template: `021_Flow_Specification_Methodology.md`
- Use when: documenting methodology and rationale for Flow spec structure.
- Output type: reference/methodology doc.

### D. Canonical Flow spec (11 sections)
- Template: `02_Flow_Spec_Template.md`
- Use when: creating a new flow spec from scratch.
- Output type: `spec` document for one flow.

### E. Codex workflow task packet
- Template: `03_CODEX_WORKFLOW_TASK_TEMPLATE.md`
- Use when: preparing execution packets for coding agents.
- Output type: task workflow packet / project ops template.

### F. PROJECT_CONTEXT_CHIT protocol
- Template: `PROJECT_CONTEXT_CHIT_COMMIT.md`
- Use when: documenting checkpoint/changelog meta-protocol.
- Output type: protocol/reference doc.

## 3) Standard Document Types and Which Template to Use

1. Flow Spec (authoritative flow behavior):
- Use: `02_Flow_Spec_Template.md`
- Destination: `docs/flows/flow-XX/spec/`
- Name format: `FLOWXX-Spec-<ShortName>.md`

2. Flow Task (implementation unit):
- Base style: task structure from `00_Standart_entw_prozess.md`
- Optional rigor overlay: sections from `01_rfc_protocol_spec_style_for_ai_agents.md`
- Destination: `docs/flows/flow-XX/tasks/`
- Name format: `FLOWXX-PY-<ShortName>.md`

3. Flow Todo/Roadmap/Addendum:
- Use: concise structure from `01_rfc_protocol_spec_style_for_ai_agents.md`
- Destination: `docs/flows/flow-XX/todo/`
- Name format:
  - `FLOWXX-Todo-<ShortName>.md`
  - `FLOWXX-Addendum-<ShortName>.md`

4. Methodology / Protocol / Process:
- Use:
  - methodology -> `021_Flow_Specification_Methodology.md`
  - process -> `00_Standart_entw_prozess.md`
  - protocol -> `PROJECT_CONTEXT_CHIT_COMMIT.md`
- Destination:
  - project-level: `docs/project/`
  - cross-flow shared: `docs/flows/_shared/`

## 4) Mandatory Header for New Docs

Every new flow doc MUST start with:
- title
- `Status: draft|in_progress|done|archived`
- `Last updated: YYYY-MM-DD`
- short scope/context

Task docs MUST also include:
- `Goal`
- `Requirements`
- `Acceptance`
- `Validation` (copy-pastable command list)

## 5) Authoring Rules (Must Follow)

1. No ambiguous wording:
- prefer deterministic statements.
- use MUST/SHOULD for testable behavior.

2. No hidden scope:
- include explicit out-of-scope list.

3. No orphan docs:
- link related task/spec/runbook files.

4. No undocumented completion:
- `done` status requires validation command(s) and observed result.

5. No legacy naming for new files:
- do not create `Flow_`, `FLOW_`, `_v2`, mixed-case ad-hoc names.
- use naming standard from `documentation-governance.md`.

## 6) Legacy Cleanup Rule

When editing old docs in `docs/flows_todo`:
1. rename to standard name;
2. move to `docs/flows/flow-XX/...`;
3. set `Status`;
4. add replacement link from old path during migration window.

## 7) Minimal Creation Checklist

Before creating any new doc:
1. Choose type (Spec / Task / Todo / Addendum / Methodology).
2. Select template from section 2.
3. Save into correct flow folder.
4. Apply naming standard.
5. Add required header + validation section.
6. Link related docs and tests.

---

If this file conflicts with a flow-specific runbook, the runbook may add stricter rules, but must not weaken these rules.
