# AutoLoop Anti-Patterns

This document lists common ways to misuse AutoLoop. Each item keeps the boundary clear: AutoLoop is a lightweight coordination protocol and evidence-gate toolkit, not an autonomous project manager.

## Treating Local Readiness As Live Proof

Problem: A worker report marked `local-readiness` is used to close a task that required live smoke, hardware, deployment, production, or end-to-end proof.

Why it hurts: Local tests, mocks, static checks, and dry-run scripts prove only the scope they exercised.

Use instead: Keep `local-readiness`, `hardware-deferred`, `live-smoke-required`, and `live-smoke-complete` distinct. Close live gates only with live evidence.

## Using Dispatch Note As The Full Handoff

Problem: The `Dispatch note` field in a work order is treated as the full instruction to a worker thread.

Why it hurts: The worker may miss the exact target thread, workspace, branch, report path, concurrency mode, allowed scope, forbidden scope, or registry context.

Use instead: Treat `Dispatch note` as a short planning cue. Use `templates/coordination/dispatch-instruction.md` for the full manual handoff block.

## Over-Splitting A Same-Boundary Feedback Loop

Problem: Edit, test, observe, and repair steps for the same owner, worktree, objective, risk envelope, contract boundary, and evidence gate are split into many micro-work-orders.

Why it hurts: The feedback loop becomes slower without improving safety, and reports stop proving the useful objective.

Use instead: Keep the loop in one bounded bundle with a clear manual loop budget, then stop when the budget is exceeded or a new blocker class appears.

## Making Allowed Scope Too Broad

Problem: `Allowed Scope` says only a broad module or subsystem and does not name concrete paths, files, or test areas.

Why it hurts: Workers and reviewers cannot tell whether a change stayed inside the intended boundary.

Use instead: Name the smallest useful files, directories, fixtures, commands, and behavior surface. Put unrelated areas in `Forbidden Scope`.

## Running Brownfield Checks Without Brownfield Mode

Problem: A mature project with historical worker reports runs aggregate coordination checks without `-Brownfield`.

Why it hurts: Old report-shape debt can be mistaken for a current active-task failure.

Use instead: Use `-Brownfield` for aggregate startup checks in mature projects. Keep focused `check-report.ps1 -Strict` for new or active reports.

## Dropping Deferred Items During Closeout

Problem: A stage closeout records completed work but omits deferred items, unverified gates, or user decisions needed before the next stage.

Why it hurts: Unfinished work silently disappears from coordination memory.

Use instead: Include deferred items, evidence levels, not-verified items, user gates, and next-stage entry conditions in `stage-closeout.md`.

## Binding Public Templates To Private Tools

Problem: Public templates require a specific private review tool, agent skill, plugin, hardware setup, or local path.

Why it hurts: Target projects cannot map their own review process to AutoLoop.

Use instead: Use tool-neutral fields such as `Review gate`, `Independent review`, `Commit authority`, and `Final acceptance owner`. Put project-specific mappings in the target project's own instructions.
