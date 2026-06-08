# Dispatch Instruction

Use this block when a coordinator has prepared or recommended a work order and needs the user to copy a clear handoff into the target worker thread. This is a manual handoff only; it does not rank tasks, assign owners automatically, lock worktrees, control Codex Desktop threads, or update `thread-registry.md`.

Coordinator output invariant: whenever a coordinator creates or recommends a work order, its final response must include either a complete `Dispatch instruction` block or a short `No dispatch` reason explaining why no worker should be started. A `Dispatch note` inside a work order is only a planning hint; it is not a complete multi-thread handoff by itself.

## Template

```text
Dispatch instruction
- Send to: [thread label / owner lane]
- Workspace: [workspace path]
- Branch: [branch]
- Work order: [path]
- Expected report: [path]
- Concurrency: [exclusive-write | shared-read-only | report-only | ask-user]
- File boundary: [key allowed / forbidden scope]
- Registry: [suggested row update, or none]
- Startup sentence: Execute this work order as an AutoLoop worker; restate the boundary before editing files.
```

## Concurrency Modes

- `exclusive-write`: default for code, tests, OpenSpec, board, or project-state edits; do not share a worktree with another writer.
- `shared-read-only`: read-only review, audit, status check, or evidence inspection.
- `report-only`: worker-report or coordination-record correction only; no product code edits.
- `ask-user`: coordinator cannot safely choose the target thread, workspace, or sharing mode.

## No Dispatch

Use a short no-dispatch line only when no worker should be started from the current coordinator response.

```text
No dispatch: [reason no worker should be started now]
```

## Examples

```text
Dispatch instruction
- Send to: AutoLoop / docs developer / manual-dispatch-instruction
- Workspace: [workspace path]
- Branch: master
- Work order: docs/coordination/work-orders/T-XXX-manual-docs-change.md
- Expected report: docs/coordination/reports/T-XXX-worker-report.md
- Concurrency: exclusive-write
- File boundary: Only edit docs/templates/prompts/report files listed in the work order Allowed Scope; do not edit scripts, checkers, tests, or target projects.
- Registry: none
- Startup sentence: Execute this work order as an AutoLoop worker; restate the boundary before editing files.
```

```text
Dispatch instruction
- Send to: Project / coordinator reviewer / report-check
- Workspace: [workspace path]
- Branch: main
- Work order: docs/coordination/work-orders/T-YYY-report-review.md
- Expected report: docs/coordination/reports/T-YYY-worker-report.md
- Concurrency: shared-read-only
- File boundary: Read-only check of board, work-order, report, and git state; do not edit product code, credentials, deployment config, or board status.
- Registry: If a relevant row exists, report suggested status; do not edit registry directly.
- Startup sentence: Execute this work order as an AutoLoop worker; restate the boundary before editing files.
```
