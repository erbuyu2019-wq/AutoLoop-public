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
- Loop budget: `<none | short timebox | small fix-test cycle budget | stop after named blocker>`
- Integration baseline policy: `<dispatch-base acceptable | refresh-before-merge | batch-baseline | current-integration required | not applicable> - <short reason>`
- Dispatch channel: `<manual-copy | codex-cross-thread-send | external-handoff | not applicable> - <fallback or handoff note>`
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

## Integration Baseline Guidance

- Use `dispatch-base acceptable` when branch-local readiness against the dispatch/base commit is enough for the worker; the coordinator owns final integration verification.
- Use `refresh-before-merge` when one bounded refresh and revalidation is expected near acceptance, but workers should not repeatedly rebase and rerun expensive checks after unrelated integration-branch movement.
- Use `batch-baseline` when the coordinator defines one shared baseline for a group of ready branches and reviews the batch together.
- Use `current-integration required` only for high-risk work, overlapping files, shared contracts, config, schemas, tests, runtime or deployment behavior, release, hardware, production paths, or explicit user/coordinator requirements.
- Workers should record the dispatch/base commit, verified branch HEAD, observed integration branch when relevant, and drift status in the worker report.
- Workers do not chase every `master` or `main` movement by default. The coordinator performs drift-impact review before requesting expensive refresh work.
- Request a worker refresh only when drift can invalidate evidence through overlapping files, shared contracts, schemas, config, tests, runtime/deployment behavior, release/hardware/production paths, or explicit current-integration proof.
- Branch-local worker evidence and coordinator final integration-branch evidence are separate layers. The coordinator records final integration proof after merge, batch receive, push, or report-only boundary.
- This is human coordination guidance only; do not add checker-enforced freshness rules, automatic merge queues, automatic branch locking, automatic task selection, or automatic dispatch.

## Report-Only HEAD Drift Guidance

- A worker report or report-only correction may move `HEAD` after implementation/code verification was captured.
- That report-only movement is not, by itself, a reason to ask the worker to refresh the report again or rerun expensive checks.
- Coordinator acceptance owns final `HEAD`, integration branch, divergence, status, and log evidence after the last report-only commit, merge, push, or acceptance boundary.
- If only report text changed after verification, mark it as report-only drift and keep implementation/code evidence separate from final acceptance evidence.
- Request worker refresh only when material drift can invalidate implementation evidence, such as overlapping files, shared contracts, schemas, config, tests, runtime/deployment behavior, release/hardware/production paths, explicit current-integration proof, or a work-order requirement.
- Do not require amend as the default. Amend report-only corrections only when the branch is local, unpublished, worker-owned, and has no shared-history risk.
- This is human coordination guidance only; do not add checker-enforced git freshness, automatic amend/rebase behavior, automatic refresh rules, or history rewriting.

## Coordinator Final Git Evidence Guidance

- `uncommitted implementation package`: if source, tests, work order, or worker report are still uncommitted and the work order permits worker commits, returning to the worker to commit the current package is normal.
- `clean committed package with stale report evidence`: if the branch/worktree is clean, required checks passed, the package is committed, and only the worker report's `HEAD`, integration-branch, divergence, or recent-log evidence is stale, coordinator final git evidence capture is the default acceptance path.
- `dirty worktree or post-verification source/test changes`: if source, tests, config, runtime behavior, or other implementation files changed after verification, return to the worker for repair or revalidation.
- `material integration drift`: if drift can invalidate evidence through overlapping files, shared contracts, schemas, config, tests, runtime/deployment behavior, release, hardware, production paths, explicit current-integration proof, or a work-order requirement, request a bounded refresh or coordinator/user decision.
- When the coordinator has repository/worktree access, run final git evidence checks directly instead of requesting a worker refresh solely to make the worker report include final `HEAD`.
- If the coordinator cannot access the worker worktree, ask for one concise final git-state handoff rather than a full report rewrite, unless material drift or failed checks require worker repair.
- Label worker-side earlier git evidence as `implementation/code evidence` or `pre-report-commit evidence`, and label coordinator-side final checks as `coordinator final acceptance evidence`.
- This is human coordination guidance only; do not add checker-enforced freshness, automatic amend/rebase behavior, branch locks, merge queues, target-project operations, or history rewriting.

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

Dispatch channel is human handoff guidance only. Use `manual-copy` as the portable default and fallback; use `codex-cross-thread-send` only as optional acceleration when the current environment supports it without naming or requiring a specific private tool; use `external-handoff` only when the handoff path and target owner are explicit. Dispatch channel fields do not authorize automatic sending, thread discovery, registry mutation, checker-enforced dispatch records, thread locking, merge queues, or Codex Desktop thread control.
