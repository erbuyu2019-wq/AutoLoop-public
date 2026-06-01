# L3 Pilot Rules

L3 is a controlled execution pilot, not a default AutoLoop mode. Use it only when L0-L2 evidence is already reliable and the user explicitly approves the specific task.

## Required Conditions

- The user explicitly approves this exact L3 task.
- One work order exists and names one owner.
- One worktree or workspace is named in the work order.
- The task is low risk and has narrow allowed scope.
- The task does not require real credentials, private data, hardware, production systems, deployment changes, releases, merges, rollbacks, or live smoke.
- Acceptance commands are listed before execution starts.
- The worker returns a `worker-report.md` style report.
- The coordinator reviews the report before the task can close.

## Hard Stops

Stop and ask the user before continuing if any of these appear:

- Scope expands beyond the work order.
- API, data model, security, deployment, runtime, or shared-contract behavior changes.
- Real credentials, private data, hardware, production systems, or live field conditions are needed.
- The worker cannot run the required checks.
- The task needs more than one owner or worktree.

## Allowed Output

An L3 worker may:

- make the scoped edit authorized by the work order;
- run the listed checks;
- report changed files, verification, not-verified items, risks, and next suggested step.

An L3 worker must not:

- choose a new task;
- edit the board without coordinator approval;
- merge, release, deploy, roll back, or publish;
- operate hardware or real credentials;
- claim live smoke proof unless a user-approved live smoke work order exists and was completed.

## Coordinator Review

The coordinator must treat the L3 report as evidence, not as automatic closure. Close the task only after checking:

- report format passes;
- changed files match allowed scope;
- required checks ran or skipped checks have a reason;
- no user gate was crossed;
- local readiness is not being mistaken for live proof.
