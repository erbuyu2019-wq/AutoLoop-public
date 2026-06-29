# Dispatch Instruction

Use this block when a coordinator has prepared or recommended a work order and needs a clear handoff into the target worker thread or owner lane. This is a manual handoff contract only; it does not rank tasks, assign owners automatically, send messages automatically, discover threads, lock worktrees, control Codex Desktop threads, or update `thread-registry.md`.

Coordinator output invariant: whenever a coordinator creates or recommends a work order, its final response must include either a complete `Dispatch instruction` block or a short `No dispatch` reason explaining why no worker should be started. A `Dispatch note` inside a work order is only a planning hint; it is not a complete multi-thread handoff by itself.

Dispatch channel options:

- `manual-copy`: default portable fallback. The coordinator outputs a complete block for the user to copy into the recipient thread.
- `codex-cross-thread-send`: optional acceleration when the current Codex App environment supports sending content to another thread. Do not name or require a specific private tool; still record the recipient thread label and manual-copy fallback.
- `external-handoff`: file, issue, Obsidian note, report, or other external handoff path. Record the handoff path and target owner; the external artifact is not the current coordination state source unless the project explicitly says so.

## Template

```text
Dispatch instruction
- Dispatch channel: [manual-copy | codex-cross-thread-send | external-handoff]
- Send to / Recipient thread: [thread label / owner lane / human label]
- Workspace / worktree: [workspace path]
- Branch: [branch]
- Work order: [path]
- Expected report: [path]
- Concurrency: [exclusive-write | shared-read-only | report-only | ask-user]
- Granularity decision: [bounded bundle | split work orders | report-only | integration-bringup | no dispatch] - [short reason]
- Integration baseline policy: [dispatch-base acceptable | refresh-before-merge | batch-baseline | current-integration required | not applicable] - [short reason]
- File boundary: [key allowed / forbidden scope]
- Registry: [suggested row update, or none]
- Fallback: [manual-copy block | external handoff path | ask-user]
- Send receipt: [not sent | sent by coordinator | user copied | external handoff written]
- Startup sentence: Execute this work order as an AutoLoop worker; restate the boundary before editing files.
```

Keep `Send to / Recipient thread` separate from `Workspace / worktree`; one worktree may have more than one relevant thread. If the coordinator cannot safely identify the target thread, workspace, or concurrency mode, use `ask-user` and `Send receipt: not sent`.

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
- Dispatch channel: manual-copy
- Send to / Recipient thread: AutoLoop / docs developer / manual-dispatch-instruction
- Workspace / worktree: [workspace path]
- Branch: master
- Work order: docs/coordination/work-orders/T-XXX-manual-docs-change.md
- Expected report: docs/coordination/reports/T-XXX-worker-report.md
- Concurrency: exclusive-write
- Granularity decision: bounded bundle - same docs owner, workspace, objective, risk envelope, and evidence gate.
- Integration baseline policy: not applicable - docs-only change on the current checkout.
- File boundary: Only edit docs/templates/prompts/report files listed in the work order Allowed Scope; do not edit scripts, checkers, tests, or target projects.
- Registry: none
- Fallback: manual-copy block above
- Send receipt: not sent
- Startup sentence: Execute this work order as an AutoLoop worker; restate the boundary before editing files.
```

```text
Dispatch instruction
- Dispatch channel: external-handoff
- Send to / Recipient thread: Project / coordinator reviewer / report-check
- Workspace / worktree: [workspace path]
- Branch: main
- Work order: docs/coordination/work-orders/T-YYY-report-review.md
- Expected report: docs/coordination/reports/T-YYY-worker-report.md
- Concurrency: shared-read-only
- Granularity decision: report-only - current need is evidence review, not implementation.
- Integration baseline policy: dispatch-base acceptable - review branch-local evidence first; coordinator owns final integration proof.
- File boundary: Read-only check of board, work-order, report, and git state; do not edit product code, credentials, deployment config, or board status.
- Registry: If a relevant row exists, report suggested status; do not edit registry directly.
- Fallback: manual-copy block if the external handoff path is unavailable
- Send receipt: external handoff written
- Startup sentence: Execute this work order as an AutoLoop worker; restate the boundary before editing files.
```
