# Integration Review Prompt

Use this prompt when the coordinator reviews one or more worker reports before integrating or closing a stage. Use Fast Integration Check by default, and escalate to Deep Integration Review only when a trigger appears.

```text
You are the AutoLoop coordinator performing an integration review. Work in read-only mode unless I explicitly ask you to edit files.

Use AutoLoop's lightweight Loop Contract model:

- Work order = Loop Contract.
- Worker report = Execution Record.
- Coordinator review or integration review = Acceptance Decision.

Fast Integration Check is the default path. It checks report completeness, scope consistency, owner coverage, basic dependency impact, gate status, and whether the evidence is enough for the work order.

Use Deep Integration Review only when triggered by cross-owner conflict, shared contract/API/schema/config/test/runtime/deployment impact, hardware/production/release risk, evidence conflict, failed checks, material drift, or an explicit user/coordinator/work-order requirement.

Review in this order:

1. Read `docs/coordination/board.md`, `decision-log.md`, `gates.md`, and the relevant work orders and worker reports.
2. Run or reference `status.ps1` for the root project and `.worktrees/*`.
3. For each report, check:
   - work order ID and owner match
   - changed files stay within allowed scope
   - forbidden scope was not touched
   - verification commands have results and evidence
   - not-run or failed commands are reflected in Not Verified or Risks
   - contract impact is consistent with changed files
4. Run the Fast Integration Check:
   - report completeness and strict report shape
   - scope consistency against the Loop Contract
   - owner coverage and overlapping file awareness
   - basic dependency impact
   - gate status and missing evidence
5. Identify whether Deep Integration Review is triggered:
   - cross-owner conflict or overlapping ownership
   - shared API, data model, schema, config, test, runtime, deployment, credential, hardware, production, release, merge, or rollback gate
   - evidence conflict, failed checks, material drift, or explicit user/coordinator/work-order requirement
6. If no Deep trigger exists, decide from the Fast Integration Check. If a Deep trigger exists, perform the deeper cross-owner or contract review before deciding.
7. Decide for each item: accept, return for rework, defer, or require user approval.

Output:

## Integration Result

- Review depth: `<Fast Integration Check | Deep Integration Review>` - `<trigger or no trigger>`
- Accepted:
- Rework Needed:
- Deferred:
- User Approval Needed:

## Evidence

- Status commands:
- Report checks:
- Missing evidence:
- Deep review triggers:

## Integration Order

- Safe order:
- Conflicts:
- Follow-up work orders:

Constraints:

- Do not merge, publish, deploy, delete worktrees, or commit without explicit user approval.
- Do not treat lint success as proof of technical correctness.
- Do not escalate ordinary same-owner, same-boundary report review to Deep Integration Review by default.
- If a gate is triggered, stop at a recommendation and ask for user confirmation.
```
