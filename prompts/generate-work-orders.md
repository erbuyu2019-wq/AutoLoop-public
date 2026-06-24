# Generate Work Orders Prompt

Use this prompt when the coordinator needs to turn board items into short work orders for long-lived threads or temporary subagents.

```text
Generate the next batch of executable work orders based on the current `docs/coordination/board.md`, `decision-log.md`, `gates.md`, and git/worktree state.

Requirements:

1. Generate work orders only for tasks with status `todo`, tasks whose `blocked` state has been cleared, or tasks that need rework after `review`.
2. Every work order must use the fields from `docs/coordination/work-order.md`.
3. Every work order must make these items explicit:
   - owner
   - goal
   - allowed change scope
   - forbidden scope
   - whether contract changes are allowed
   - review gate ownership
   - independent review ownership
   - commit authority
   - final acceptance owner
   - acceptance commands
   - stop-and-report conditions
   - `Loop budget` as `none` or a manual timebox / small fix-test cycle budget when useful
   - `Integration baseline policy` as `dispatch-base acceptable`, `refresh-before-merge`, `batch-baseline`, `current-integration required`, or `not applicable`
4. Keep each work order short and specific. Do not output long design notes.
5. If a task triggers `gates.md`, do not generate an execution work order. Generate a user-decision summary instead.
6. Apply the Granularity Gate before drafting each work order:
   - Decide `bounded bundle`, `split work orders`, `report-only`, `integration-bringup`, or `no dispatch`.
   - Include a short reason for the decision.
   - Use `no dispatch` when the safe next step is coordinator review, a user decision, or more evidence rather than worker execution.
7. Apply Efficiency Guardrails before drafting:
   - Fast Lane: if the task is one owner, one worktree, one objective, the same risk envelope, the same contract boundary, the same evidence gate, and no active board, gate, OpenSpec, or work-order rule requires a separate user decision, prefer one bounded bundle for implementation, local verification, and report.
   - Evidence Value: classify the intended evidence as `direct product proof`, `runtime proof`, `integration proof`, `proxy evidence`, or `planning evidence`.
   - Planning Depth: if recent work for the same objective has spent two or more consecutive tasks on planning or proxy evidence, prefer a bounded implementation/proof work order, a user-decision summary, or a clear `no dispatch` reason instead of another planning/proxy task.
   - Keep this as coordinator judgment only; do not add checker rules or require exhaustive history counting.
8. Right-size each work order:
   - It should be small enough for one owner, one worktree, and one reviewable evidence bundle.
   - Default to one bounded bundle when the owner, workspace or worktree, objective, risk envelope, contract boundary, and evidence gate are the same.
   - Do not split a tightly coupled feedback loop into separate micro-work-orders when the objective can only be proven by completing the loop together; the work order should close a useful feedback chain, not only one mechanical action.
   - Useful feedback chains include `edit-test-observe`, `hypothesis-fix-verify`, `deploy-start-trigger-observe-classify`, and `evidence-refresh-review`.
   - Split work orders only when owners, workspaces or worktrees, risk levels, contract boundaries, acceptance gates, user approval requirements, or evidence types differ enough that one report would blur responsibility or safety.
   - Treat this as coordinator guidance only; do not invent checker rules that infer correct work-order size.
9. Preserve bounded execution latitude:
   - Keep allowed scope, forbidden scope, stop rules, credentials, hardware, production, deployment, rollback, destructive actions, and contract-impact boundaries strict.
   - Treat the issued work order as the loop contract for one bounded loop; existing fields define the goal/owner, boundary, approach, evidence, stop points, and return report.
   - Do not default to one-shot or one-attempt limits for low-risk local docs, implementation, edit-test, or observe loops.
   - Use explicit one-attempt limits only for live hardware, target-device mutation, real credentials, deployment, production, release, rollback, destructive actions, irreversible state, or an explicit user/work-order requirement.
   - Prefer a timebox or small fix-test cycle budget over micro-work-orders when an approved debugging or integration loop must keep edit/deploy/start/trigger/observe/classify steps together.
   - Stop the loop when the manual budget is exceeded, a new blocker class appears, or scope, security, data, credential, hardware, deployment, production, rollback, or verification assumptions change.
10. For report-only work orders, evidence refreshes, or likely report-only corrections:
   - Require worker reports to label git evidence as `implementation/code evidence`, `pre-report-commit evidence`, or `coordinator final acceptance evidence`.
   - Do not force the worker report to include its own future report-only commit; coordinator final acceptance git evidence is captured after the last commit, merge, push, or report-only boundary.
   - Mention amend only as conditional: it is acceptable only when the branch is local, unpublished, worker-owned, and has no shared-history risk.
11. Use tool-neutral gate authority fields:
   - `Review gate: none | project-defined | external`
   - `Independent review: not required | worker-authorized | coordinator-owned | required-before-commit`
   - `Commit authority: no commit | local branch commit allowed | report-only commit allowed | coordinator-only`
   - `Final acceptance owner: worker | coordinator | user`
   - Do not name or require a specific private review tool unless the target project's instructions or the user explicitly provide it.
   - If a worker may lack authority for a project-defined or external review gate, tell the worker to complete allowed local work and report the deferred gate to coordinator acceptance or user decision instead of blocking indefinitely.
12. For parallel branch acceptance:
   - Default to `dispatch-base acceptable` when branch-local readiness against the dispatch/base commit is enough and the coordinator will own final integration proof.
   - Use `refresh-before-merge` for one bounded refresh/revalidation near acceptance, not unlimited rebases after unrelated `master` or `main` movement.
   - Use `batch-baseline` when several ready branches share a coordinator-defined acceptance baseline.
   - Use `current-integration required` only for high-risk work, overlapping files, shared contracts, config, schemas, tests, runtime/deployment behavior, release, hardware, production paths, or explicit requirements.
   - Require worker reports to record dispatch/base commit, verified branch HEAD, observed integration branch when relevant, and drift status.
   - Do not add checker-enforced freshness rules, automatic branch locking, automatic merge queues, automatic task selection, or automatic dispatch.

Output format:

## Work Order <T-XXX>

- Owner:
- Granularity decision:
- Fast lane:
- Evidence value:
- Planning depth:
- Loop budget:
- Integration baseline policy:
- Goal:
- Allowed Scope:
- Forbidden Scope:
- Required Approach:
- Gate Authority:
- Acceptance Commands:
- Stop and Report If:
- Return Report:

## Needs User Confirmation

- `<none or gate summary>`

Constraints:

- Do not expand task scope beyond the board.
- Do not pack one large cross-owner task into a single work order. Split it into owner-scoped deliverables.
- Do not over-fragment a single-owner feedback loop when the evidence only makes sense after the loop completes.
- Do not use one-shot wording as a generic safety substitute; safety comes from exact boundaries, stop rules, and evidence gates.
- For subagent work orders, prefer short exploration, review, test coverage, or narrow fixes.
- Do not keep generating proxy-only or planning-only work when the remaining safe next step is implementation/proof, a user decision, or no dispatch.
- Do not bind AutoLoop work orders to a specific review mechanism or private local route in reusable prompt text.
```
