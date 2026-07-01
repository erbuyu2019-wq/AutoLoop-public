# AutoLoop Versus Agent Runtime

AutoLoop is a coordination protocol, not an execution platform. It can complement agent runtimes, project-management tools, durable spec systems, and normal chat workflows, but it does not replace them.

## AutoLoop vs Agent Runtime Or Daemon

An agent runtime or daemon runs tasks, calls tools, schedules work, or controls execution.

AutoLoop does not do that by default. It provides human-readable work orders, worker reports, review prompts, protocol checks, and evidence boundaries. It does not automatically select tasks, dispatch agents, control Codex Desktop threads, run background jobs, operate hardware, deploy, merge, or release.

Use AutoLoop with an agent runtime when you want a reviewable contract around what the runtime or assistant is allowed to do, what evidence it must return, and when a human or coordinator gate is required.

## AutoLoop vs Project Management Tool

A project-management tool usually stores backlog items, assignees, schedules, comments, dashboards, and status history.

AutoLoop is smaller. It keeps coordination state close to the repository:

- `board.md` for current-stage task state.
- work orders for scoped assignments.
- worker reports for evidence returns.
- closeout notes for stage compression.
- checks that lint coordination artifacts.

It is not a database, kanban service, calendar, notification system, or portfolio dashboard. A team can still use an issue tracker or project tool as the broader source of planning truth.

## AutoLoop vs Durable Requirements Or Spec Systems

A durable requirements system captures product behavior, API contracts, data models, permissions, security flows, or architecture decisions.

AutoLoop does not replace those artifacts. It coordinates execution against the current task boundary and evidence gate. When a change needs durable requirements, public behavior changes, API/data-model changes, permission/security changes, or architecture review, use the target project's requirements or spec system and reference it from the work order.

AutoLoop works best when the spec answers "what should be true" and the work order answers "what bounded loop should this worker execute now."

## AutoLoop vs Chat-Only Coordination

Chat-only coordination is fast, but it can lose important evidence:

- Which files were allowed or forbidden.
- Which checks actually ran.
- Whether local readiness was confused with live proof.
- Which user gate or acceptance owner still applies.
- Whether follow-up work is a repair, a new task, or a coordinator decision.

AutoLoop keeps those details in repository artifacts that can be reviewed, linted, and closed out. It is still lightweight: Markdown first, PowerShell checks second, human acceptance last.

## When To Combine Tools

AutoLoop can sit beside other systems:

| Existing tool | Keep using it for | Use AutoLoop for |
| --- | --- | --- |
| Agent runtime | Tool execution and automation. | Scope, evidence, and gate boundaries. |
| Issue tracker | Backlog, planning, milestones. | Current work-order loop and worker report evidence. |
| Spec system | Durable requirements and contracts. | Execution handoff and acceptance evidence. |
| CI | Build and test gates. | Recording which local or CI evidence was required and returned. |
| Chat | Discussion and clarifications. | Stable task boundaries and reviewable reports. |

The boundary is intentional: AutoLoop should make assistant-driven work easier to trust without becoming the thing that runs, owns, or accepts everything automatically.
