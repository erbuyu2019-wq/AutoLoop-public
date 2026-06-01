# Stage Closeout

Use this file when a coordinator closes a stage or prepares the next stage. It is a compression artifact: keep the active board short, and move stage-level conclusions here.

## Summary

- Stage: `<stage name or ID>`
- Stage goal: `<one-sentence goal>`
- Closeout date: `<YYYY-MM-DD>`
- Coordinator: `<owner or thread>`
- Result: `<accepted | hold | blocked | needs user approval>`

## Completed Tasks

| Task ID | Owner | Result | Accepted Evidence Level | Evidence |
| --- | --- | --- | --- | --- |
| `<task>` | `<owner>` | `<done, partial, blocked, rejected>` | `<local-readiness, hardware-deferred, live-smoke-required, live-smoke-complete, not applicable>` | `<report, command, commit, or review link>` |

## Not Verified

- `<item not verified, or none>`

## User Gates

- `<gate requiring user approval, or none>`

## Deferred Items

| Item | Reason | Suggested Entry Point |
| --- | --- | --- |
| `<deferred item>` | `<why deferred>` | `<next work order or gate>` |

## Verification Summary

| Command / Review | Result | Evidence |
| --- | --- | --- |
| `<command or review>` | `<passed, failed, not run>` | `<short evidence>` |

## Next Stage Entry

- Next stage goal: `<one-sentence next goal>`
- First candidate work order: `<task ID or file>`
- Required user decision before starting: `<decision, or none>`

## Notes

- Do not mark local readiness as live smoke proof.
- Keep any real credential, hardware, deployment, production, merge, release, or rollback action behind an explicit user gate.
