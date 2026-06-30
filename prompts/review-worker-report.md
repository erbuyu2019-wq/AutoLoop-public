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
11. The work order's gate authority fields, if present, are honored:
    - `Review gate`: none, project-defined, or external.
    - `Independent review`: not required, worker-authorized, coordinator-owned, or required-before-commit.
    - `Commit authority`: no commit, local branch commit allowed, report-only commit allowed, or coordinator-only.
    - `Final acceptance owner`: worker, coordinator, or user.
12. Any project-defined or external review gate that the worker could not run is clearly marked as deferred to coordinator acceptance or as needing a user decision, not silently treated as completed.
13. The coordinator needs to update `board.md`, `decision-log.md`, contract docs, or the stage closeout after acceptance.
14. Before recommending the next coordination action, make a `Granularity Gate` decision: `bounded bundle`, `split work orders`, `report-only`, `integration-bringup`, or `no dispatch`, with a short reason.
15. If evidence is missing but the owner, workspace or worktree, objective, risk envelope, contract boundary, and evidence gate are still the same, prefer evidence repair inside the same boundary instead of creating a new micro-work-order.
16. Split follow-up work only when owner, workspace or worktree, risk level, contract boundary, acceptance gate, user approval requirement, or evidence type differs enough that one report would blur responsibility or safety.
17. Classify the report and any follow-up evidence value as `direct product proof`, `runtime proof`, `integration proof`, `proxy evidence`, or `planning evidence`.
18. If the chain already has enough planning or proxy evidence for the same objective, prefer direct product, runtime, or integration proof, a user decision, or `no dispatch` over another proxy/planning task.
19. Decide whether Fast Lane still applies for same-owner, same-worktree, same-objective, same-risk, same-contract, same-evidence-gate repair, while keeping hard user gates strict.
20. Check whether any git evidence is labeled as `implementation/code evidence`, `pre-report-commit evidence`, or `coordinator final acceptance evidence`.
21. If a worker report or report-only correction changed after implementation verification, treat that as report-only HEAD drift. Do not require the worker to chase its own future report-only commit or rerun expensive checks solely for that drift.
22. Apply the coordinator final git evidence decision matrix:
    - `uncommitted implementation package`: if source, tests, work order, or worker report are still uncommitted and the work order permits worker commits, returning to the worker to commit the current package is normal.
    - `clean committed package with stale report evidence`: if the branch/worktree is clean, required checks passed, the package is committed, and only the worker report's HEAD/integration/divergence/log evidence is stale, capture final git evidence in coordinator review or closeout instead of asking the worker to rewrite the report.
    - `dirty worktree or post-verification source/test changes`: if source, tests, config, runtime behavior, or other implementation files changed after verification, return to the worker for repair or revalidation.
    - `material integration drift`: if drift can invalidate evidence through overlapping files, shared contracts, schemas, config, tests, runtime/deployment behavior, release, hardware, production paths, explicit current-integration proof, or a work-order requirement, request a bounded refresh or coordinator/user decision.
23. For coordinator final acceptance, run or request:
    `git status --short --branch`
    `git rev-parse --short HEAD`
    `git rev-parse --short master` or `git rev-parse --short main`
    `git rev-list --left-right --count master...HEAD` or `git rev-list --left-right --count main...HEAD`
    `git log --oneline -5`
24. If the coordinator has repository/worktree access, run final git checks directly instead of requesting a worker refresh solely to make the worker report include final HEAD. If the coordinator cannot access the worktree, ask for one concise final git-state handoff rather than a full report rewrite, unless material drift or failed checks require worker repair.
25. Check whether the worker stayed inside the work order as the loop contract: goal/owner, allowed and forbidden scope, required approach, gate authority, acceptance commands, stop-and-report conditions, and required return report.
26. If the work order had a manual loop budget, check whether the report stayed within it or stopped when the budget was exceeded, a new blocker class appeared, or scope, security, data, credential, hardware, deployment, production, rollback, or verification assumptions changed.
27. If the work order had an integration baseline policy, check that the report records dispatch/base commit, verified branch HEAD, observed integration branch when relevant, and drift status.
28. Perform material drift review before requesting a worker refresh. Request refresh only when drift can invalidate implementation evidence through overlapping files, shared contracts, schemas, config, tests, runtime/deployment behavior, release, hardware, production paths, explicit current-integration proof, or a work-order requirement.
29. Keep branch-local worker evidence separate from coordinator final integration proof. If accepting a merge, batch receive, push, or report-only boundary, record final integration proof after that boundary.
30. Use Fast Integration Check as the default for a complete same-owner, same-boundary report. Recommend Deep Integration Review only when there is cross-owner conflict, shared contract/API/schema/config/test/runtime/deployment impact, hardware/production/release risk, evidence conflict, failed checks, material drift, or an explicit user/coordinator/work-order requirement.

Output format:

## Findings

- List issues by severity. If there are no blocking findings, write `No blocking findings.`

## Evidence Check

- Sufficient verification:
- Insufficient verification:
- Unverified risk:
- Gate authority:
- Git evidence boundary:
- Report-only HEAD drift:
- Coordinator final git evidence default:
- Integration baseline / drift impact:
- Coordinator final git checks:
- Loop contract:
- Loop budget / stop conditions:
- Integration review depth:

## Coordination Decision

- `accept`: coordinator may update the board.
- `request changes`: worker needs to repair or add evidence.
- `ask user`: user gate is triggered.
- `hold`: wait for another owner, gate, or integration order.
- Granularity Gate: `<bounded bundle | split work orders | report-only | integration-bringup | no dispatch> - <reason>`
- Fast lane: `<yes | no> - <reason>`
- Integration review depth: `<Fast Integration Check | Deep Integration Review> - <trigger or no trigger>`
- Evidence value: `<direct product proof | runtime proof | integration proof | proxy evidence | planning evidence> - <reason>`
- Planning depth: `<implementation/proof next | user decision | no dispatch | more planning justified> - <reason>`
- Deferred gate handling: `<none | coordinator acceptance needed | user decision needed | independent review needed before commit> - <reason>`

## Board Update Draft

- Task status:
- Next step:
- Recent update:

Constraints:

- Do not treat "tests passed" as integration completion unless the checks cover the work order.
- When evidence is missing, request evidence instead of inferring success.
- Do not turn missing evidence in the same owner/workspace/objective/risk/contract/evidence boundary into a separate micro-work-order by default.
- If real credentials, deployment, hardware, field work, production data, or shared contract changes are involved, mark `ask user`.
- If a required project-defined or external gate is outside worker authority, do not reject completed local work solely for that reason; hold for coordinator-owned review, independent review, or user decision as appropriate.
- Do not accept a branch commit when the work order says `no commit` or `coordinator-only`.
- Do not silently weaken `check-report.ps1 -Strict` expectations.
- Do not add automatic dispatch, automatic retry, automatic task selection, thread control, or execution authority.
- Do not convert same-boundary evidence repair into another proxy-only or planning-only task when direct proof is available.
- Do not require amend as the default. Amend report-only corrections only when the branch is local, unpublished, worker-owned, and has no shared-history risk.
- Do not treat pre-report-commit evidence as proof of the final accepted git state after coordinator commits, merges, pushes, or report-only changes.
- Do not send work back for self-referential report refresh solely because the report-only commit moved HEAD; capture final git state in coordinator acceptance or closeout.
- Do not return a clean committed package to the worker only because the worker report's git evidence is stale; coordinator final git evidence capture is the default acceptance path.
- Do not turn manual loop budgets into checker-enforced counting or automatic retry behavior.
- Do not require workers to chase every unrelated `master` or `main` movement. Require current-integration proof only when the work order demands it or drift impact can invalidate the worker evidence.
- Do not recommend Deep Integration Review by default for ordinary complete same-owner, same-boundary worker reports.
```
