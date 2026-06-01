# Active Thread Registry

Use this optional registry when a project has multiple active coordinator or worker threads and the coordinator needs a compact manual view of who is working where. Single-thread projects can omit it.

The registry is coordinator-owned by default. It records execution context only; `board.md` remains the task source of truth. Do not use this file to rank tasks, assign owners, dispatch Codex threads, control Codex Desktop, or infer task completion.

## Active Entries

| Thread label | Owner | Work order | Workspace / worktree | Branch | Registry status | Last seen | Expected report | Boundary notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `<manual label>` | `<owner>` | `<T-XXX>` | `<path>` | `<branch>` | `<planned|active|waiting-coordinator|waiting-user|review|stale|closed>` | `<YYYY-MM-DD HH:MM local>` | `<docs/coordination/reports/...>` | `<allowed scope, gates, or no-go notes>` |

## Registry Status Values

- `planned`: thread or owner lane is expected but not yet active.
- `active`: worker has accepted the work order and is inside allowed scope.
- `waiting-coordinator`: worker needs coordinator review or clarification.
- `waiting-user`: worker or coordinator is blocked by a user gate.
- `review`: worker report has been returned and needs coordinator review.
- `stale`: coordinator manually marked the entry as outdated or no longer trusted.
- `closed`: work has been accepted, superseded, or explicitly abandoned.

## Update Rules

- Keep entries short and factual: owner, work order, workspace/worktree, branch, manual status, last seen, expected report, and boundary notes.
- Do not store private chat excerpts, full prompts, credentials, captures, hardware data, production data, or generated runtime artifacts.
- Worker threads should usually report the row that needs updating in their worker report.
- Worker threads may edit this registry directly only when their work order explicitly allows it.
- Coordinator updates are manual. Do not populate this file from automatic thread discovery or Codex Desktop session scans.

## Closeout

When an entry is no longer current, manually set it to `stale` or `closed` and add a short reason in `Boundary notes`.

Do not delete rows only to hide unfinished work. Prefer a visible `stale` or `closed` row until the coordinator has compressed the stage or confirmed the context is no longer useful.
