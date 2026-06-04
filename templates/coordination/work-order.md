# Work Order

## Summary

- ID: `<T-XXX>`
- Owner: `<target owner or subagent>`
- Goal: `<one sentence>`
- Priority: `<low | normal | high>`
- Due / checkpoint: `<date or next report point>`
- Dispatch note: `none` or brief target / workspace / concurrency cue; this is not a complete manual dispatch instruction

## Context

- Project stage goal: `<stage goal>`
- Relevant board item: `<T-XXX>`
- Relevant decision / contract: `<D-XXX, contract link, or none>`
- Current known state: `<brief facts, not speculation>`

## Allowed Scope

- Files / modules allowed: `<exact paths or module names>`
- Behavior allowed to change: `<narrow behavior description>`
- Tests / fixtures allowed: `<exact paths or test areas>`

## Forbidden Scope

- Do not touch: `<files/modules/systems>`
- Do not change: `<contracts, public behavior, dependencies, deployment, credentials, or none>`
- Stop and report if: `<condition that requires coordinator or user decision>`

## Required Approach

- Skill / discipline: `<karpathy-baseline | karpathy-deep | systematic-debugging | review-only | other>`
- Implementation expectation: `<smallest acceptable change>`
- Contract handling: `<no contract change | pre-report contract impact | follow linked contract>`
- Secret / private data handling: `<redaction rule or none>`

## Work-Order Size Guidance

- A work order should be small enough for one owner, one worktree, and one reviewable evidence bundle.
- Do not split a tightly coupled feedback loop into separate micro-work-orders when the objective can only be proven by completing the loop together.
- Split work orders when owners, worktrees, risk levels, contract boundaries, or acceptance gates differ.
- Combine steps when they share the same owner, workspace, objective, risk envelope, and evidence gate, especially for edit-test-observe or deploy-start-trigger-observe-classify loops.
- Keep this as coordinator guidance only; do not add checker rules that try to infer correct work-order size.

## Acceptance Commands

Run the cheapest decisive checks that fit the task.

```powershell
<command 1>
<command 2>
```

Expected result:

- `<expected pass/fail signal>`

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
- If Summary `Result` is `done`, `check-report.ps1 -Strict` rejects `failed`, `not run`, and `not-run` verification results. Use `partial` or `blocked` when required checks failed or were not run.

Also include:

- Changed files.
- Verification commands and results.
- Contract impact.
- Remaining risk or unverified items.

`Dispatch note` is only a planning cue in this work order. The coordinator's final response must still provide a complete manual dispatch instruction block or a short `No dispatch` reason.
