# Work Order

## Summary

- ID: `<T-XXX>`
- Owner: `<target owner or subagent>`
- Goal: `<one sentence>`
- Priority: `<low | normal | high>`
- Due / checkpoint: `<date or next report point>`
- Granularity decision: `<bounded bundle | split work orders | report-only | integration-bringup | no dispatch> - <short reason>`
- Fast lane: `<yes | no> - <short reason>`
- Evidence value: `<direct product proof | runtime proof | integration proof | proxy evidence | planning evidence> - <short reason>`
- Planning depth: `<implementation/proof next | user decision | no dispatch | more planning justified> - <short reason>`
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

- Execution discipline: `<baseline implementation | deep investigation | systematic debugging | review-only | project-defined>`
- Implementation expectation: `<smallest acceptable change>`
- Contract handling: `<no contract change | pre-report contract impact | follow linked contract>`
- Secret / private data handling: `<redaction rule or none>`

## Gate Authority

- Review gate: `<none | project-defined | external>`
- Independent review: `<not required | worker-authorized | coordinator-owned | required-before-commit>`
- Commit authority: `<no commit | local branch commit allowed | report-only commit allowed | coordinator-only>`
- Final acceptance owner: `<worker | coordinator | user>`

These fields describe who owns review, commit, and final acceptance gates. They do not grant automatic execution, review routing, commit, merge, release, deployment, or acceptance authority by themselves. Concrete project review mechanisms belong in the target project's instructions or issued work order, not in AutoLoop's reusable template.

## Work-Order Size Guidance

- Treat the issued work order as the loop contract for one bounded AutoLoop loop. Existing fields carry the contract: `Summary` names goal and owner, `Allowed Scope` and `Forbidden Scope` define the boundary, `Required Approach` defines execution discipline, `Gate Authority` defines review/commit/acceptance ownership, `Acceptance Commands` define evidence, stop-and-report conditions define interruption points, and `Required Return Report` defines the evidence return path.
- A loop may continue only while it stays inside that contract. Stop and report when scope, security, data, credential, hardware, deployment, production, rollback, or verification assumptions change.
- Make the granularity decision before drafting or dispatching. This is a human coordinator judgment, not a checker-enforced schema.
- A work order should be small enough for one owner, one worktree, and one reviewable evidence bundle.
- Default to one bounded bundle when the owner, workspace or worktree, objective, risk envelope, contract boundary, and evidence gate are the same.
- Do not split a tightly coupled feedback loop into separate micro-work-orders when the objective can only be proven by completing the loop together; the work order should close a useful feedback chain, not only one mechanical action.
- Useful feedback chains include `edit-test-observe`, `hypothesis-fix-verify`, `deploy-start-trigger-observe-classify`, and `evidence-refresh-review`.
- Split work orders only when owners, workspaces or worktrees, risk levels, contract boundaries, acceptance gates, user approval requirements, or evidence types differ enough that one report would blur responsibility or safety.
- Keep boundaries strict: allowed files, forbidden systems, credentials, hardware, production, deployment, rollback, destructive actions, contract impacts, and stop rules are not flexible.
- Inside approved low-risk local scope, allow reasonable edit-test iterations, harmless retries, and local test reruns needed to satisfy acceptance commands.
- Do not default to one-shot or one-attempt wording for ordinary local implementation or docs work; reserve explicit one-attempt limits for live hardware, target-device mutation, real credentials, deployment, production, release, rollback, destructive actions, irreversible state, or an explicit user/work-order requirement.
- For debugging or integration loops, prefer a timebox or small fix-test cycle budget over micro-work-orders when the same evidence gate proves the loop.
- State manual loop budgets in plain language when useful, such as a short timebox, a small fix-test cycle budget, or a stop after a named blocker class appears. Budgets are coordinator guidance, not automatic retry behavior or checker-enforced counting.
- Keep this as coordinator guidance only; do not add checker rules that try to infer correct work-order size.
- Fast lane applies only when no active board, gate, OpenSpec, or work-order rule requires a separate user decision.
- Low-risk same-boundary work should usually include implementation, local verification, and report in one bounded bundle.
- Repeated planning or proxy evidence should move toward implementation/proof, a user decision, or explicit no-dispatch reasoning.
- Evidence-value classification does not weaken strict report validation, stop rules, or high-risk gates.

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
- Gate authority status, including any deferred project-defined or external review gate.
- Remaining risk or unverified items.

`Dispatch note` is only a planning cue in this work order. The coordinator's final response must still provide a complete manual dispatch instruction block or a short `No dispatch` reason.
