# Integration Bring-up Work Order

Use this template only when a standard work order would over-split a deploy/start/trigger/observe/classify integration loop. Replace every placeholder before issuing the work order. This template does not grant automatic execution, automatic dispatch, L3 authority, hardware access, credential use, deployment, rollback, or target-project writes by itself.

## Summary

- ID: `{T-XXX}`
- Owner: `{single owner lane}`
- Mode: `integration-bringup`
- Goal: `{one sentence describing the bring-up objective}`
- Priority: `{low | normal | high}`
- Due / checkpoint: `{date or next report point}`
- Dispatch note: `{manual target / workspace / concurrency cue; not a complete dispatch instruction}`

## Context

- Project stage goal: `{stage goal}`
- Relevant board item: `{T-XXX}`
- Relevant decision / contract: `{decision, contract, or none}`
- Current known state: `{facts only; include last known passing and failing signals}`
- Objective reclassification: `{smoke test | target bring-up | deployment rehearsal | diagnostic probe | source bugfix | observability repair | device-health isolation}`
- Why standard mode is insufficient: `{why splitting deploy/start/trigger/observe/classify would lose the causal chain}`

## Runtime Topology

| Layer / Owner | Process, service, device, or file | Expected signal | Observer / evidence source |
| --- | --- | --- | --- |
| `{owner}` | `{component}` | `{heartbeat, status, callback, upload, UI state, log line, or artifact}` | `{command, log, report, UI, or manual observation}` |

## Allowed Scope

- Files / modules allowed: `{exact paths or none}`
- Runtime actions allowed: `{exact deploy/start/trigger/observe/classify actions, or none}`
- Data allowed: `{sanitized fixtures, logs, synthetic payloads, approved live source, or none}`
- Tests / fixtures allowed: `{exact commands or test areas}`
- Observation allowed: `{logs, status endpoints, UI, artifacts, broker topics, or none}`

## Forbidden Scope

- Do not touch: `{files/modules/systems/target projects not in scope}`
- Do not change: `{contracts, public behavior, dependencies, deployment, credentials, hardware, production, or none}`
- Do not use: real credentials, private captures, customer data, raw device identifiers, hardware, production systems, deployment, rollback, or live smoke unless explicitly approved in this work order.
- Do not add: automatic retry loops, automatic task selection, automatic dispatch, automatic board writes, registry mutation, daemon behavior, GUI behavior, L3 execution, or Codex Desktop thread control.
- Stop and report if: `{new blocker class, third failed fix-test cycle, missing authorization, missing observability, unsafe state, or target mismatch}`

## Bring-up Loop

Run only the approved loop below. Do not add retries or adjacent runtime actions without coordinator or user approval.
If the work order allows repeated attempts, state the maximum time or attempt budget explicitly. A bounded budget is manual and evidence-gated; it does not authorize automatic retry loops, automatic execution, hardware access, credential use, deployment, rollback, production access, or target-project writes by itself.

1. Deploy / prepare: `{exact command or manual action, or not applicable}`
2. Start / activate: `{exact command or manual action, or not applicable}`
3. Trigger: `{exact command, input, or event, or not applicable}`
4. Observe: `{exact logs, status, callback, UI, artifact, or metric}`
5. Classify: `{source bug | deployment mismatch | runtime failure | device health failure | broker/control issue | observer/UI issue | inconclusive}`

## Evidence Matrix

| Gate | Source | Result | Scope proven | Remaining gap |
| --- | --- | --- | --- | --- |
| Command accepted | `{command/log/report}` | `{passed | failed | not run}` | `{what accepted means}` | `{what it does not prove}` |
| Runtime state | `{health/status/log}` | `{passed | failed | not run}` | `{service/device/process state proven}` | `{remaining runtime unknown}` |
| Data flow | `{callback/topic/file/artifact}` | `{passed | failed | not run}` | `{source to sink proven}` | `{remaining seam}` |
| User-visible outcome | `{UI/report/operator observation}` | `{passed | failed | not run}` | `{human-visible behavior proven}` | `{remaining UX/product gap}` |
| Remaining gaps | `{worker analysis}` | `{passed | failed | not run}` | `{classified open work}` | `{next smaller task}` |

## Stop Rules

- Stop after three failed fix-test cycles in this work order.
- Stop when a new class of blocker appears.
- Stop when required logs, health signals, callbacks, or user-visible observations are absent.
- Stop when the next action needs credentials, hardware, deployment, rollback, production access, target-project writes, or L3 authority not explicitly approved here.
- Stop when local or mock evidence is being mistaken for live, hardware, production, or end-to-end proof.

## Acceptance Commands

Run the cheapest decisive checks that fit the approved bring-up scope.

```powershell
{command 1}
{command 2}
```

Expected result:

- `{expected command accepted signal}`
- `{expected runtime state signal}`
- `{expected data-flow signal}`
- `{expected user-visible signal or explicit not-verified gap}`

## Required Return Report

Return the result using `worker-report.md` with these exact top-level headings:

- `Summary`
- `Changed Scope`
- `Verification`
- `Contract Impact`
- `Not Verified`
- `Risks`
- `Next Suggested Step`

For `check-report.ps1 -Strict`, use only these checked values:

- Summary `Result`: `done`, `partial`, `blocked`, or `rejected`.
- Summary `Evidence level`: `local-readiness`, `hardware-deferred`, `live-smoke-required`, `live-smoke-complete`, or `not applicable`.
- `Next Suggested Step`: `continue`, `review`, `needs coordinator decision`, `needs user decision`, or `blocked`.
- If Summary `Result` is `done`, `check-report.ps1 -Strict` rejects `failed`, `not run`, and `not-run` verification results. Use `partial` or `blocked` when required checks failed or were not run.

Also include:

- Changed files.
- Bring-up loop steps attempted.
- Evidence matrix with command accepted, runtime state, data flow, user-visible outcome, and remaining gaps.
- Classification of the current seam.
- Stop rule hit, if any.
- Contract impact.
- Remaining risk or unverified items.

`Dispatch note` is only a planning cue in this work order. The coordinator's final response must still provide a complete manual dispatch instruction block or a short `No dispatch` reason.
