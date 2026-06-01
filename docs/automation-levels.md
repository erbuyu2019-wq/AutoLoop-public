# AutoLoop Automation Levels

AutoLoop treats automation as a set of explicit levels. The default product should stay at L0-L2 until a target project has enough checks and clear user gates.

| Level | Capability | Default Position |
| --- | --- | --- |
| L0 | Read-only status summaries and report completeness checks | Default and safe |
| L1 | Lint board, work orders, reports, and scope | Immediate target |
| L2 | Draft next steps and work orders without code changes | Allowed after L1 is useful |
| L3 | Execute low-risk tasks inside one worktree and allowed scope | Pilot only |
| L4 | Commit and open PR automatically, no merge | Optional and gated |
| L5 | Auto-merge, release, rollback | Out of default scope |

## L0: Read-Only Checks

L0 includes commands such as `status.ps1` and `check-report.ps1`. These commands may inspect files and git state, but they must not edit project files.

Use L0 for normal coordinator startup, stage closeout, and worker report review.

## L1: Lint And Consistency Checks

L1 validates whether work orders and reports are complete enough for a coordinator to review.

Examples:

- Required work-order fields are present.
- Required report sections are present.
- Report result and next-step values are from an allowed set.
- Obvious placeholder text has been replaced.
- Multi-owner integration reports cover every expected owner.

L1 does not prove technical correctness. It only catches consistency and protocol failures.

## L2: Drafting Assistance

L2 can draft next steps or work orders from existing status and coordination files. It may propose work, but it must not modify code.

Use L2 only after the coordinator has enough reliable status and lint output.

L2 examples:

- `prompts/draft-work-order.md`
- `prompts/suggest-next.md`

L2 must not update the board, assign work, dispatch a thread, or execute commands.

## L3: Scoped Execution Pilot

L3 may execute a low-risk task in one explicit worktree and allowed scope.

Required gates:

- Explicit user approval.
- No real credentials, private data, deployment, production system, or hardware operation.
- Required checks listed in the work order.
- Worker report returned for coordinator review.

See `docs/l3-pilot-rules.md` before attempting any L3 pilot.

## L4: Commit Or PR Automation

L4 may commit or open a PR after checks and user gates are satisfied. It must not merge.

Use L4 only when the target project has a GitHub workflow and the user explicitly approves the publish step.

## L5: Merge, Release, Rollback

L5 is not a default AutoLoop capability. Merge, release, rollback, production, and hardware decisions require explicit human approval and project-specific process.
