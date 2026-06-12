# Review Worker Report Prompt

Use this prompt when the coordinator reviews a completed worker report before updating the board or asking for more work.

```text
Review the worker report returned by a developer thread or subagent. Start in review-only mode. Do not edit code, docs, board rows, or reports unless I explicitly ask for repair.

Check:

1. The report has a clear work order ID and owner.
2. The work stayed inside the work order Allowed Scope.
3. The work did not touch Forbidden Scope.
4. The report uses the exact strict worker-report headings: `Summary`, `Changed Scope`, `Verification`, `Contract Impact`, `Not Verified`, `Risks`, and `Next Suggested Step`.
5. The strict summary values are valid: `Result` is one of `done`, `partial`, `blocked`, or `rejected`; `Evidence level` is one of `local-readiness`, `hardware-deferred`, `live-smoke-required`, `live-smoke-complete`, or `not applicable`; `Next Suggested Step` is one of `continue`, `review`, `needs coordinator decision`, `needs user decision`, or `blocked`.
6. If `Result` is `done`, `check-report.ps1 -Strict` must not allow any `Verification` result marked `failed`, `not run`, or `not-run`; review whether any other non-passed result is acceptable evidence for the work order.
7. Verification commands actually ran and are strong enough for the work order acceptance criteria.
8. `Not Verified` honestly lists gaps and does not hide missing evidence.
9. `Contract Impact` covers public behavior, API/data model, security/secret handling, and deployment/runtime impact.
10. The work triggers any user decision gate in `docs/coordination/gates.md`.
11. The coordinator needs to update `board.md`, `decision-log.md`, contract docs, or the stage closeout after acceptance.
12. Before recommending the next coordination action, make a `Granularity Gate` decision: `bounded bundle`, `split work orders`, `report-only`, `integration-bringup`, or `no dispatch`, with a short reason.
13. If evidence is missing but the owner, workspace or worktree, objective, risk envelope, contract boundary, and evidence gate are still the same, prefer evidence repair inside the same boundary instead of creating a new micro-work-order.
14. Split follow-up work only when owner, workspace or worktree, risk level, contract boundary, acceptance gate, user approval requirement, or evidence type differs enough that one report would blur responsibility or safety.
15. Classify the report and any follow-up evidence value as `direct product proof`, `runtime proof`, `integration proof`, `proxy evidence`, or `planning evidence`.
16. If the chain already has enough planning or proxy evidence for the same objective, prefer direct product, runtime, or integration proof, a user decision, or `no dispatch` over another proxy/planning task.
17. Decide whether Fast Lane still applies for same-owner, same-worktree, same-objective, same-risk, same-contract, same-evidence-gate repair, while keeping hard user gates strict.
18. Check whether any git evidence is labeled as `implementation/code evidence`, `pre-report-commit evidence`, or `coordinator final acceptance evidence`.
19. If a worker report changed after implementation verification, do not require the worker to chase its own future report-only commit. The coordinator captures final acceptance git evidence after the last commit, merge, push, or report-only boundary.
20. For coordinator final acceptance, run or request:
    `git status --short --branch`
    `git rev-parse --short HEAD`
    `git rev-list --left-right --count master...HEAD`
    `git log --oneline -5`
21. Check whether the worker stayed inside the work order as the loop contract: goal/owner, allowed and forbidden scope, required approach, acceptance commands, stop-and-report conditions, and required return report.
22. If the work order had a manual loop budget, check whether the report stayed within it or stopped when the budget was exceeded, a new blocker class appeared, or scope, security, data, credential, hardware, deployment, production, rollback, or verification assumptions changed.

Output format:

## Findings

- List issues by severity. If there are no blocking findings, write `No blocking findings.`

## Evidence Check

- Sufficient verification:
- Insufficient verification:
- Unverified risk:
- Git evidence boundary:
- Coordinator final git checks:
- Loop contract:
- Loop budget / stop conditions:

## Coordination Decision

- `accept`: coordinator may update the board.
- `request changes`: worker needs to repair or add evidence.
- `ask user`: user gate is triggered.
- `hold`: wait for another owner, gate, or integration order.
- Granularity Gate: `<bounded bundle | split work orders | report-only | integration-bringup | no dispatch> - <reason>`
- Fast lane: `<yes | no> - <reason>`
- Evidence value: `<direct product proof | runtime proof | integration proof | proxy evidence | planning evidence> - <reason>`
- Planning depth: `<implementation/proof next | user decision | no dispatch | more planning justified> - <reason>`

## Board Update Draft

- Task status:
- Next step:
- Recent update:

Constraints:

- Do not treat "tests passed" as integration completion unless the checks cover the work order.
- When evidence is missing, request evidence instead of inferring success.
- Do not turn missing evidence in the same owner/workspace/objective/risk/contract/evidence boundary into a separate micro-work-order by default.
- If real credentials, deployment, hardware, field work, production data, or shared contract changes are involved, mark `ask user`.
- Do not silently weaken `check-report.ps1 -Strict` expectations.
- Do not add automatic dispatch, automatic retry, automatic task selection, thread control, or execution authority.
- Do not convert same-boundary evidence repair into another proxy-only or planning-only task when direct proof is available.
- Do not require amend as the default. Amend report-only corrections only when the branch is local, unpublished, worker-owned, and has no shared-history risk.
- Do not treat pre-report-commit evidence as proof of the final accepted git state after coordinator commits, merges, pushes, or report-only changes.
- Do not turn manual loop budgets into checker-enforced counting or automatic retry behavior.
```
