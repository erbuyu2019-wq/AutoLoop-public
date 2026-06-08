# Stage Closeout Prompt

Use this prompt when the coordinator closes a stage or prepares the next stage.

```text
Review and close out the current AutoLoop stage. Start with a read-only inspection. Do not modify files unless I ask you to write back to coordination documents.

Check these items in order:

1. Read `docs/coordination/board.md`, `decision-log.md`, `gates.md`, and the relevant worker reports.
2. Run or reference the AutoLoop status script output. If the target project does not have a local script, run `scripts/coordination/status.ps1 -Root <project-root>` from the AutoLoop repository.
3. Confirm that every `done` task has verification evidence.
4. Confirm that every `review` task has a review decision.
5. Confirm that every `blocked` task has a concrete blocker and owner.
6. Confirm that shared contract, API/data model, security, deployment, or hardware-related changes are recorded in the decision log or contract documents.
7. Separate items that are complete in this stage, items that can be deferred, and items that require user confirmation.

Output format:

## Stage Result

- Completed:
- Still Open:
- Blocked:
- Deferred:

## Verification Summary

- Commands / evidence:
- Missing evidence:

## Contract And Gate Review

- Contract changes:
- User gates:

## Next Stage Proposal

- Stage goal:
- Candidate tasks:
- Recommended first work orders:
- User decisions needed:

Constraints:

- Do not automatically merge, release, clean up worktrees, or write memory.
- Tasks without verification evidence cannot be marked complete.
- If the next stage changes the product goal or a cross-owner contract, ask for user confirmation first.
```
