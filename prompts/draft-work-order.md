# Draft Work Order Prompt

Use this prompt when the coordinator wants a draft work order. This is L2 drafting assistance only.

```text
You are helping draft an AutoLoop work order. Work in read-only mode.

Inputs to read:

1. `docs/coordination/board.md`
2. `docs/coordination/decision-log.md`
3. `docs/coordination/gates.md`
4. the relevant current reports or stage closeout, if referenced by the user

Task:

- Draft one work order for the task or owner I name.
- Use the fields from `docs/coordination/work-order.md`.
- Treat the issued work order as the loop contract for one bounded AutoLoop loop. Map existing fields to contract roles instead of adding a new required section: `Summary` names goal and owner, `Allowed Scope` and `Forbidden Scope` define the boundary, `Required Approach` defines execution discipline, `Acceptance Commands` define evidence, stop-and-report conditions define interruption points, and `Required Return Report` defines the evidence return path.
- Make a `Granularity Gate` decision before drafting: `bounded bundle`, `split work orders`, `report-only`, `integration-bringup`, or `no dispatch`, and include a short reason.
- Choose the work-order mode explicitly: `standard`, `report-only`, or `integration-bringup`.
- Apply Efficiency Guardrails before drafting:
  - Fast Lane: if the task is one owner, one worktree, one objective, the same risk envelope, the same contract boundary, the same evidence gate, and no active board, gate, OpenSpec, or work-order rule requires a separate user decision, prefer one bounded bundle for implementation, local verification, and report.
  - Evidence Value: classify the intended evidence as `direct product proof`, `runtime proof`, `integration proof`, `proxy evidence`, or `planning evidence`.
  - Planning Depth: if recent work for the same objective has spent two or more consecutive tasks on planning or proxy evidence, prefer a bounded implementation/proof work order, a user-decision summary, or a clear `no dispatch` reason instead of another planning/proxy task.
  - Keep this as coordinator judgment only; do not add checker rules or require exhaustive history counting.
- Keep scope narrow and owner-specific.
- Right-size the work order: it should be small enough for one owner, one worktree, and one reviewable evidence bundle.
- Default to one bounded bundle when the owner, workspace or worktree, objective, risk envelope, contract boundary, and evidence gate are the same.
- Do not split a tightly coupled feedback loop into separate micro-work-orders when the objective can only be proven by completing the loop together; the work order should close a useful feedback chain, not only one mechanical action.
- Useful feedback chains include `edit-test-observe`, `hypothesis-fix-verify`, `deploy-start-trigger-observe-classify`, and `evidence-refresh-review`.
- Split work orders only when owners, workspaces or worktrees, risk levels, contract boundaries, acceptance gates, user approval requirements, or evidence types differ enough that one report would blur responsibility or safety.
- Keep work-order size guidance as coordinator judgment only; do not add or imply checker rules that infer correct size.
- Keep hard boundaries strict: allowed files, forbidden systems, credentials, hardware, production, deployment, rollback, destructive actions, contract impacts, and stop rules are not flexible.
- Inside approved low-risk local scope, allow reasonable edit-test iterations, harmless retries, and local test reruns needed to satisfy acceptance commands.
- Do not default to one-shot or one-attempt wording for ordinary local implementation or docs work.
- Use explicit one-attempt limits only for live hardware, target-device mutation, real credentials, deployment, production, release, rollback, destructive actions, irreversible state, or an explicit user/work-order requirement.
- Prefer a bounded manual loop budget over micro-work-orders when an approved debugging or integration loop must keep edit/deploy/start/trigger/observe/classify steps together.
- State manual loop budgets in plain language when useful, such as a short timebox, a small fix-test cycle budget, or a stop after a named blocker class appears. Do not imply automatic retry behavior or checker-enforced budget counting.
- State that the loop may continue only while it stays inside its work-order contract, and must stop when scope, security, data, credential, hardware, deployment, production, rollback, or verification assumptions change.
- Include allowed scope, forbidden scope, stop conditions, acceptance commands, dispatch note, and required return report.
- Use `standard` for one bounded implementation, documentation, review, or report task.
- Use `report-only` for evidence refreshes, readiness audits, investigations, and closeouts that must not edit product/runtime files.
- Use `integration-bringup` only when deploy/start/trigger/observe/classify steps need to stay in one manual evidence chain; base it on `templates/coordination/integration-bringup-work-order.md`.
- For `integration-bringup`, require objective reclassification, runtime topology, allowed and forbidden actions, stop rules, and an evidence matrix that separates command accepted, runtime state, data flow, user-visible outcome, and remaining gaps.
- `integration-bringup` must not imply automatic execution, automatic retry, automatic task/report discovery, automatic dispatch, board writes, registry mutation, L3 authority, hardware access, credential use, deployment, rollback, production access, or target-project writes.
- Treat `Dispatch note` as a planning cue only. It is not a complete manual handoff and does not replace the coordinator's final `派发指令` block or `No dispatch` reason.
- In `Required Return Report`, list these exact worker-report headings: `Summary`, `Changed Scope`, `Verification`, `Contract Impact`, `Not Verified`, `Risks`, and `Next Suggested Step`.
- In `Required Return Report`, list the strict checked values: Summary `Result` must be `done`, `partial`, `blocked`, or `rejected`; Summary `Evidence level` must be `local-readiness`, `hardware-deferred`, `live-smoke-required`, `live-smoke-complete`, or `not applicable`; `Next Suggested Step` must be `continue`, `review`, `needs coordinator decision`, `needs user decision`, or `blocked`.
- State that a `done` report must not contain `failed`, `not run`, or `not-run` results in the `Verification` table.
- For report-only work orders, evidence refreshes, or likely report-only corrections, require the worker report to label git evidence as `implementation/code evidence`, `pre-report-commit evidence`, or `coordinator final acceptance evidence`.
- Do not force a worker report to include its own future report-only commit. If the report changes HEAD after verification, coordinator final acceptance git evidence belongs to coordinator acceptance or closeout after the last commit, merge, push, or report-only boundary.
- Include conditional amend wording only when useful: amend a report-only correction into the latest local commit only if the branch is local, unpublished, worker-owned, and has no shared-history risk; otherwise use a separate report-only commit or leave final git evidence to the coordinator.
- If the request triggers a user gate, do not draft an execution work order. Output a user-decision summary instead.

Output:

## Draft Work Order

- ID:
- Owner:
- Mode:
- Granularity decision:
- Fast lane:
- Evidence value:
- Planning depth:
- Goal:
- Dispatch note:
- Allowed Scope:
- Forbidden Scope:
- Required Approach:
- Acceptance Commands:
- Stop And Report If:
- Required Return Report:

## User Decision Needed

- `<none or decision summary>`

Constraints:

- Do not edit files.
- Do not update the board.
- Do not assign or dispatch the work.
- Do not execute commands.
- Do not expand the task beyond the board or user request.
- Do not treat lint success as technical correctness.
- Do not keep drafting more proxy-only or planning-only work when implementation/proof, a user decision, or no dispatch is the better next step.
- Do not invent weaker worker-report headings or summary values than the strict checker accepts.
```
