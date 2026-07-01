# Parallel Codex Workflow

AI-assisted development gets harder when several assistant threads, worktrees, or owner lanes run at the same time. AutoLoop keeps that work reviewable by making each loop explicit: what was asked, what changed, what was verified, what was not verified, and who can accept it.

## Problem

Parallel assistant work can lose important context:

- Scope: a worker may fix a nearby issue that was not part of the assigned task.
- Evidence: a passing local check may be mistaken for live, production, hardware, or end-to-end proof.
- Baseline: a worker may test against one commit while the integration branch moves.
- Acceptance: a coordinator may not know whether to accept, return, defer, or ask the user.

Chat history alone is a weak coordination record. It is easy to miss a forbidden path, a skipped check, a dirty worktree, or a report that no longer matches the work order.

## AutoLoop Flow

AutoLoop uses a small loop:

```text
work order -> worker report -> coordinator review / integration review -> closeout
```

1. The coordinator writes a work order with owner, scope, forbidden scope, acceptance commands, gate authority, and stop rules.
2. The worker executes only that work order and returns a worker report with changed files, verification, contract impact, not-verified items, risks, and next suggested step.
3. The coordinator reviews the report, compares it with the work order, checks evidence, and decides whether to accept, request rework, defer, or ask the user.
4. The board or closeout changes only after the coordinator has enough evidence.

The work order is the Loop Contract. The worker report is the Execution Record. Coordinator review or integration review is the Acceptance Decision.

## Minimal Example

Assume a project has three owner lanes:

- `app`: user-facing application code.
- `device`: local device adapter or simulator code.
- `docs`: public documentation.

The coordinator can open three separate work orders:

| Owner | Work order focus | Evidence expected |
| --- | --- | --- |
| `app` | Update a narrow UI behavior. | Focused tests and local smoke. |
| `device` | Add a simulator fixture. | Fixture test and no hardware claim. |
| `docs` | Improve onboarding copy. | Markdown review and repository verification. |

Each worker returns one report. If the files and contracts do not overlap, the coordinator can perform a Fast Integration Check: report completeness, scope consistency, owner coverage, basic dependency impact, and gate status.

If two reports touch the same shared API, config, schema, runtime path, release path, hardware path, or production path, the coordinator escalates to Deep Integration Review before acceptance.

## Efficiency Boundaries

AutoLoop should reduce coordination overhead, not create process for its own sake.

- Do not split one same-owner, same-worktree, same-risk feedback loop into micro-work-orders when one bounded work order can cover edit, test, observe, and repair.
- Do not make workers chase every unrelated `master` or `main` movement by default. Ask for refresh only when drift can invalidate the evidence.
- Keep worker evidence separate from coordinator final acceptance evidence. A report can prove local readiness while final merge, release, live smoke, or production acceptance remains coordinator-owned.
- Do not treat protocol checks as technical proof. They show report and coordination health, not product correctness.
- Do not use AutoLoop to bypass user gates for credentials, hardware, deployment, production, rollback, merge, or release.

## When This Helps

Use this workflow when a project has:

- Multiple assistant threads working at once.
- Several worktrees or owner lanes.
- Repeated confusion about what evidence is enough.
- Local readiness that must stay separate from live or production proof.
- A need to close stages without losing deferred items or user gates.

Avoid it for tiny one-off edits where a direct prompt and one test command are enough.
