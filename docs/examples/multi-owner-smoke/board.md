# Coordination Board

Project: Multi-owner smoke example
Stage Goal: Verify local readiness across app, device, and workbench before a separate live smoke gate.
Last Updated: `2026-05-20`

## Owners

| Owner | Scope | Workspace / Thread | Notes |
| --- | --- | --- | --- |
| app | high-level control request and safe receipt evidence | `.worktrees/app` | no protocol commands or real credentials |
| device | protocol apply/readback readiness evidence | `.worktrees/device` | no live hardware access in this example |
| workbench | one-shot control entry and UI/API/store readiness evidence | `.worktrees/workbench` | no retained secrets |
| coordinator | integration review and user gates | root thread | accepts local readiness only |

## Tasks

Use only these statuses: `todo`, `doing`, `blocked`, `review`, `done`.

| ID | Status | Owner | Task | Allowed Scope | Blocker / Risk | Next Step |
| --- | --- | --- | --- | --- | --- | --- |
| T-EX-001 | done | coordinator | Review app, device, and workbench local-readiness reports | `docs/examples/multi-owner-smoke/` | none | Record local readiness and keep live smoke separate |
| T-EX-002 | blocked | coordinator | Run live hardware smoke after approval | live smoke evidence only after user approval | waiting for user-approved live hardware conditions | Request explicit user approval before replacing the guard command |

## Integration Notes

- Current integration order: app report -> device report -> workbench report -> coordinator integration review.
- Shared contract areas: none in this example.
- User decision needed: required before live hardware smoke, real credentials, deployment, production, merge, release, or rollback.

## Recent Updates

| Date | Update | Evidence |
| --- | --- | --- |
| `2026-05-20` | Example board records local readiness as distinct from live smoke proof. | `integration-review.md` |
