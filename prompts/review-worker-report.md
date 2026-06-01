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

Output format:

## Findings

- List issues by severity. If there are no blocking findings, write `No blocking findings.`

## Evidence Check

- Sufficient verification:
- Insufficient verification:
- Unverified risk:

## Coordination Decision

- `accept`: coordinator may update the board.
- `request changes`: worker needs to repair or add evidence.
- `ask user`: user gate is triggered.
- `hold`: wait for another owner, gate, or integration order.

## Board Update Draft

- Task status:
- Next step:
- Recent update:

Constraints:

- Do not treat "tests passed" as integration completion unless the checks cover the work order.
- When evidence is missing, request evidence instead of inferring success.
- If real credentials, deployment, hardware, field work, production data, or shared contract changes are involved, mark `ask user`.
- Do not silently weaken `check-report.ps1 -Strict` expectations.
```
