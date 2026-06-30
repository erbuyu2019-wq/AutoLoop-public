# AutoLoop Loop Contract Model

AutoLoop is a lightweight loop-engineering protocol for L0-L2 coordination. It keeps the artifacts small and human-reviewed instead of adding a daemon, task database, automatic dispatcher, or mandatory execution runtime.

## Artifact Map

| Model term | Existing AutoLoop artifact | Purpose |
| --- | --- | --- |
| Loop Contract | Work order | Defines the bounded loop before work starts. |
| Execution Record | Worker report | Returns what changed, what was verified, what was not verified, and what remains risky. |
| Acceptance Decision | Coordinator review or integration review | Decides whether the evidence is enough to accept, return, defer, or ask the user. |

These are names for existing artifacts. They do not create new required files, checker targets, JSON fields, enum values, or automation levels.

## Field Responsibilities

Existing work-order fields carry the loop contract:

- Entry condition: `Context`, current known state, relevant board item, and any dispatch/base commit or integration baseline policy.
- Scope boundary: `Allowed Scope`, `Forbidden Scope`, and stop-and-report conditions.
- Execution discipline: `Required Approach`, granularity decision, fast-lane decision, and loop budget.
- Evidence requirement: `Acceptance Commands`, expected result, evidence value, and required return report.
- Gate ownership: `Gate Authority`, integration baseline guidance, and final acceptance owner.
- Exit condition: the worker report plus coordinator acceptance, rework, deferral, or user decision.

The worker report is the execution record for that contract. It should make scope, verification, contract impact, not-verified items, risks, and the next suggested step explicit enough that the coordinator can review without inferring success from chat history.

The coordinator review or integration review is the acceptance decision. It stays read-only unless the user asks for edits, and it records whether the loop can close, needs rework, should be deferred, or must ask the user.

## Fast And Deep Review

Use a Fast Integration Check by default for one-owner, same-boundary work when the report is complete, scope is consistent, basic dependencies are clear, and gates are not triggered.

Use Deep Integration Review only when a trigger exists:

- Cross-owner conflict or overlapping ownership.
- Shared contract, API, schema, config, test, runtime, deployment, release, hardware, or production impact.
- Evidence conflict, missing required evidence, failed checks, or drift that can invalidate evidence.
- Explicit user, coordinator, work-order, or project requirement.

Fast review is not weaker acceptance. It is the normal path for low-risk loop contracts that already have enough evidence. Deep review is reserved for work where the evidence or impact needs broader integration reasoning.

## Boundaries

This model is documentation guidance only. It does not add automatic task selection, automatic dispatch, automatic retry, board writes, registry mutation, thread discovery, Codex Desktop control, checker enforcement, public-export sync, release action, target-project writes, or L3/L4 execution.
