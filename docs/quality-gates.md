# AutoLoop Quality Gates

This document defines the minimum gates for moving an AutoLoop task from `review` to `done`.

## Definition Of Done

A task can move to `done` only when:

- The worker report passes format checks.
- The work order has an owner, allowed scope, forbidden scope, stop condition, and acceptance commands.
- All acceptance commands were run, or every skipped command has a clear reason.
- Changed files stay within the allowed scope.
- No forbidden paths, credentials, private data, production systems, deployment behavior, or hardware operations were touched without approval.
- API, data model, security, deployment, runtime, or shared contract changes are recorded in a decision or gate item.
- Failed or not-run checks are reflected in `Not Verified` or `Risks`.
- `git diff --check` passes for the changed workspace when code or docs were edited.
- The coordinator has reviewed the report and updated the board.

## Evidence Levels For Hardware Or No-Device Work

Hardware-adjacent projects often need a local readiness pass before live device validation. Do not treat these evidence levels as task statuses. Keep task status simple, and record the evidence level in the worker report, integration review, or stage closeout.

Recommended terms:

- `local-readiness`: local tests, fake probes, in-memory probes, or review-only checks passed. This is not live hardware proof.
- `hardware-deferred`: hardware was unavailable or intentionally not touched.
- `live-smoke-required`: the next step must exercise real hardware, real transport, or an approved live path.
- `live-smoke-complete`: approved live smoke ran and produced reviewable evidence.

A local-readiness task can be accepted only as local readiness. If the product goal requires real hardware behavior, the coordinator must create or preserve a follow-up live-smoke work order.

## User Approval Gates

Stop and ask the user before proceeding when a task involves:

- Product or stage goal changes.
- Public behavior, API, data model, permission, security, deployment, or runtime changes.
- New heavy dependencies, cloud services, databases, system-level installs, or broad migrations.
- Real credentials, private data, hardware, field tests, production systems, releases, rollback, merge, or PR publication.
- Any change outside the allowed work-order scope.

## Coordinator Review Checklist

Before marking a task as `done`, the coordinator should check:

- Work order ID in the report matches the assigned task.
- Owner and workspace match the expected thread or worktree.
- Changed files are understandable and scoped.
- Verification commands have results and evidence.
- Contract impact is explicitly `yes` or `no`.
- Not verified items are acceptable for the next step.
- The next suggested step is consistent with the risks.
- Hardware/no-device evidence is not being mistaken for live smoke evidence.

## Integration Review Gate

For multi-owner work orders, a single worker report is not enough to close the task. The coordinator should run an integration review after all expected owner reports are available.

The integration review should check:

- Every expected owner returned one report.
- Every report references the same work order ID.
- Report results and next steps are internally consistent.
- Any `partial`, `blocked`, `rejected`, or `needs coordinator decision` result is held for coordinator action.
- Any API/data/security/deployment/runtime or shared-contract impact triggers user approval.
- Local readiness and live hardware proof are kept separate.

## What Lint Can And Cannot Prove

Lint scripts can prove that required fields and obvious consistency rules are present. They cannot prove the implementation is correct, safe, performant, or complete. Technical correctness still requires reading the diff and running the target project's checks.
