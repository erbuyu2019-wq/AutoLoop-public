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
   - acceptance commands
   - stop-and-report conditions
4. Keep each work order short and specific. Do not output long design notes.
5. If a task triggers `gates.md`, do not generate an execution work order. Generate a user-decision summary instead.
6. Right-size each work order:
   - It should be small enough for one owner, one worktree, and one reviewable evidence bundle.
   - Do not split a tightly coupled feedback loop into separate micro-work-orders when the objective can only be proven by completing the loop together.
   - Split work orders when owners, worktrees, risk levels, contract boundaries, or acceptance gates differ.
   - Combine steps when they share the same owner, workspace, objective, risk envelope, and evidence gate, especially for edit-test-observe or deploy-start-trigger-observe-classify loops.
   - Treat this as coordinator guidance only; do not invent checker rules that infer correct work-order size.
7. Preserve bounded execution latitude:
   - Keep allowed scope, forbidden scope, stop rules, credentials, hardware, production, deployment, rollback, destructive actions, and contract-impact boundaries strict.
   - Do not default to one-shot or one-attempt limits for low-risk local docs, implementation, edit-test, or observe loops.
   - Use explicit one-attempt limits only for live hardware, target-device mutation, real credentials, deployment, production, release, rollback, destructive actions, irreversible state, or an explicit user/work-order requirement.
   - Prefer a bounded manual loop budget over micro-work-orders when an approved debugging or integration loop must keep edit/deploy/start/trigger/observe/classify steps together.

Output format:

## Work Order <T-XXX>

- Owner:
- Goal:
- Allowed Scope:
- Forbidden Scope:
- Required Approach:
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
```
