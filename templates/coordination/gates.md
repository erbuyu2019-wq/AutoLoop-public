# User Decision Gates

Only interrupt the user for material decisions. Routine implementation choices stay with the coordinator and worker within the approved scope.

## Must Ask User

Ask before continuing when any item below is true:

- Product goal or stage goal changes.
- Public behavior, API, data model, permission, security, or deployment behavior changes.
- Shared contract changes affect more than one owner or thread.
- Hardware wiring, field testing, production services, real credentials, or real private data are involved.
- New heavyweight dependency, database, cloud service, driver, or system-level install is introduced.
- Work requires merge, release, rollback, destructive cleanup, or branch/worktree role changes.
- Verification cannot be performed and the remaining risk affects acceptance.

## Coordinator Can Continue

The coordinator can continue without user approval when work stays inside the current work order and is limited to:

- Focused tests or fixtures.
- Documentation that does not change approved requirements.
- Runtime artifact cleanup created by the current task.
- Log redaction or safer error handling that preserves behavior.
- Local smoke hardening.
- Small UI or copy fixes that do not change product goals or data contracts.

## Gate Record Template

### G-XXX: `<short title>`

- Date: `<YYYY-MM-DD>`
- Trigger: `<which gate was hit>`
- Current task: `<T-XXX or none>`
- Impact: `<what changes if approved>`
- Risk if skipped: `<what can go wrong>`
- Recommendation: `<approve | reject | defer | ask for more design>`
- User decision: `<pending | approved | rejected | deferred>`
