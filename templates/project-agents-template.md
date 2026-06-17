# <Project Name> Working Agreements

Use this as a starting point for a target project's `AGENTS.md` when adopting AutoLoop. Replace placeholders before use.

## AutoLoop Coordination

- AutoLoop root: `<path-to-autoloop-checkout>`
- Default automation level: `L0-L2`
- Coordination files: `docs/coordination/`
- Work orders: `docs/coordination/work-orders/`
- Worker reports: `docs/coordination/reports/`
- User gates: `docs/coordination/gates.md`

AutoLoop checks are protocol evidence only. They do not prove technical correctness, deployed behavior, live hardware behavior, production readiness, or release readiness by themselves.

## Owner Lanes

| Owner | Scope | Workspace / Thread | Notes |
| --- | --- | --- | --- |
| `<owner>` | `<scope>` | `<workspace or thread>` | `<notes>` |

## Hard Boundaries

- Do not merge, release, deploy, roll back, or publish without an explicit user decision.
- Do not use real credentials, private data, hardware, production systems, deployment targets, or generated runtime artifacts unless a work order and user gate explicitly allow that action.
- Do not treat a worker report as accepted until the coordinator has reviewed scope, verification, contract impact, not-verified items, risks, and required gates.
- Do not edit `docs/coordination/board.md`, `docs/coordination/thread-registry.md`, or other coordinator-owned state unless the work order explicitly allows it.

## Review And Commit Authority

- Review gate: `<none | project-defined | external>`
- Independent review: `<not required | worker-authorized | coordinator-owned | required-before-commit>`
- Commit authority: `<no commit | local branch commit allowed | report-only commit allowed | coordinator-only>`
- Final acceptance owner: `<worker | coordinator | user>`

If a worker lacks authority for a project-defined or external gate, the worker should finish the allowed local work, run allowed checks, and report the deferred gate instead of blocking indefinitely or fabricating review evidence.

## Standard Verification

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <AutoLoopRoot>\scripts\coordination\check-board.ps1 -BoardPath docs\coordination\board.md
powershell -NoProfile -ExecutionPolicy Bypass -File <AutoLoopRoot>\scripts\coordination\check-report.ps1 -ReportPath docs\coordination\reports\<report>.md -Strict
powershell -NoProfile -ExecutionPolicy Bypass -File <AutoLoopRoot>\scripts\coordination\check-work-order.ps1 -WorkOrderPath docs\coordination\work-orders\<work-order>.md
```
