# AutoLoop Onboarding Modes

AutoLoop has two default onboarding modes. Pick the mode from the target project's current state instead of forcing one workflow everywhere.

## Greenfield / Light

Use this mode when the target project is early, has little coordination structure, or is not yet a git/worktree-based project.

Typical setup:

- Add a project-specific `AGENTS.md`.
- Add a short requirements or stage-goal document.
- Run `init-autoloop.ps1 -DryRun` first, then initialize coordination files after review.
- Start with a short `board.md`, explicit `gates.md`, one or two work orders, and worker reports.
- Accept `local-readiness` only when the evidence is local; use `live-smoke-complete` only after approved live or human-visible evidence exists.

This mode is useful when AutoLoop is establishing the first coordination skeleton for a project.

## Brownfield / Multi-Worktree

Use this mode when the target project already has history, long-lived branches, existing worktrees, or established owner lanes.

Typical setup:

- Do not migrate historical tasks into AutoLoop.
- Do not rewrite existing process or ownership rules.
- Attach AutoLoop to the current stage only.
- Use `status.ps1` to summarize the root and `.worktrees/*`.
- Keep one work order per current coordination need, and require one worker report per expected owner.
- Use `check-integration-review.ps1` before closing multi-owner work.
- Keep no-device readiness, local readiness, and live end-to-end proof separate.
- Use explicit `-Brownfield` on aggregate `check-coordination-state.ps1`, `summarize-coordination-state.ps1`, or `doctor.ps1` when historical worker reports predate the latest strict report shape. This keeps the historical debt visible as warnings; new or active reports still need focused `check-report.ps1 -Strict` before acceptance.

This mode is useful when AutoLoop acts as a shadow governance layer over an existing project.

## Shared Rules

- Start with `-DryRun` when initializing coordination files.
- Do not use `-Force` unless the target project's existing coordination files were reviewed.
- Keep L0-L2 as the default capability boundary.
- Do not operate real credentials, hardware, production systems, deployment, merge, release, or rollback without explicit user approval.
- Treat lint output as protocol evidence only. It does not prove technical correctness.

## Optional Integration Bring-up Mode

Use `integration-bringup` only when an active integration issue needs deploy/start/trigger/observe/classify steps to stay in one evidence chain. It is most useful for brownfield or multi-owner projects where repeated tiny work orders would lose the runtime topology, but it can be used in greenfield projects after the user approves the exact live or staging actions.

This mode is a work-order shape, not a new automation level. It must keep:

- one owner lane accountable for the bring-up loop;
- explicit allowed and forbidden actions;
- topology and evidence gates before more retries;
- stop rules after repeated failures or a new blocker class;
- separate evidence for command accepted, runtime state, data flow, user-visible outcome, and remaining gaps.

Do not use this mode to bypass user gates for credentials, hardware, deployment, rollback, production access, target-project writes, or L3 execution.
