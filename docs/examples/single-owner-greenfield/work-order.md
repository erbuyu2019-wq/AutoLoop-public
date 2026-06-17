# Work Order

## Summary

- ID: `T-EX-SO-001`
- Owner: `docs`
- Goal: Add a short project README section for a greenfield utility.
- Priority: `normal`
- Due / checkpoint: `next report`
- Granularity decision: `bounded bundle - one owner, one workspace, one small documentation objective, and one local evidence gate`
- Fast lane: `yes - docs-only local work with no user gate`
- Evidence value: `direct product proof - the documentation file and report can be checked directly`
- Planning depth: `implementation/proof next - no additional planning is needed`
- Loop budget: `none`
- Dispatch note: `docs owner in the current workspace; not a complete dispatch instruction`

## Context

- Project stage goal: `Create the first coordination loop for a greenfield utility.`
- Relevant board item: `T-EX-SO-001`
- Relevant decision / contract: `none`
- Current known state: `The target project has just been initialized with AutoLoop coordination files.`

## Allowed Scope

- Files / modules allowed: `README.md`, `docs/coordination/reports/T-EX-SO-001-worker-report.md`
- Behavior allowed to change: `documentation wording only`
- Tests / fixtures allowed: `AutoLoop report and work-result checks`

## Forbidden Scope

- Do not touch: `source code, dependencies, credentials, deployment files, production data, hardware, release files, or git history`
- Do not change: `public API, data model, security behavior, runtime behavior, deployment behavior, or automation level`
- Stop and report if: `the work requires code changes, credentials, deployment, live systems, or a user decision`

## Required Approach

- Execution discipline: `baseline implementation`
- Implementation expectation: `make the smallest documentation change and return a strict worker report`
- Contract handling: `no contract change`
- Secret / private data handling: `do not include credentials, private data, or machine-specific paths`

## Gate Authority

- Review gate: `none`
- Independent review: `not required`
- Commit authority: `no commit`
- Final acceptance owner: `coordinator`

## Work-Order Size Guidance

- Keep implementation, local verification, and the worker report in one bounded loop.
- Do not split this into separate planning, edit, and report-only work orders.

## Acceptance Commands

Run from the AutoLoop repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\check-work-order.ps1 -WorkOrderPath docs\examples\single-owner-greenfield\work-order.md
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\check-report.ps1 -ReportPath docs\examples\single-owner-greenfield\reports\worker-report.md -Strict
```

Expected result:

- Both checks return `Result: PASS`.

## Required Return Report

Return the result using `worker-report.md` with these exact top-level headings:

- `Summary`
- `Changed Scope`
- `Verification`
- `Contract Impact`
- `Not Verified`
- `Risks`
- `Next Suggested Step`

For `check-report.ps1 -Strict`, use only these checked values:

- Summary `Result`: `done`, `partial`, `blocked`, or `rejected`.
- Summary `Evidence level`: `local-readiness`, `hardware-deferred`, `live-smoke-required`, `live-smoke-complete`, or `not applicable`.
- `Next Suggested Step`: `continue`, `review`, `needs coordinator decision`, `needs user decision`, or `blocked`.

Also include changed files, verification commands and results, contract impact, gate authority status, and remaining risk.
