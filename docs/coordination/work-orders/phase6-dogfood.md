# Work Order

## Summary

- ID: `T-PUB-001`
- Owner: `coordinator`
- Goal: Validate the public example coordination workflow.
- Priority: `normal`
- Due / checkpoint: `public verification fixture`
- Dispatch note: `No dispatch; public verifier fixture only.`

## Context

- Project stage goal: Provide a minimal public fixture for AutoLoop verification.
- Relevant board item: `T-PUB-001`
- Relevant decision / contract: `D-PUB-001`
- Current known state: Public example coordination files are present.

## Allowed Scope

- Files / modules allowed: `docs/coordination/`, `docs/examples/multi-owner-smoke/`
- Behavior allowed to change: documentation fixture only
- Tests / fixtures allowed: existing AutoLoop coordination lint

## Forbidden Scope

- Do not touch: private repositories, real credentials, hardware, production systems, deployment systems, or live services
- Do not change: script behavior, automation level, repository visibility, release behavior, or deployment behavior
- Stop and report if: the fixture requires private project context

## Required Approach

- Skill / discipline: `karpathy-baseline`
- Implementation expectation: smallest public fixture that validates report shape
- Contract handling: no contract change
- Secret / private data handling: no real credentials or private data

## Acceptance Commands

Run the cheapest decisive checks that fit the task.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\status.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\check-report.ps1 -ReportPath docs\coordination\reports\phase6-dogfood-worker-report.md
```

Expected result:

- Status script reports repository state.
- Worker report completeness check returns `Result: PASS`.

## Required Return Report

Return the result using `worker-report.md` with changed files, verification commands and results, contract impact, risks, and next step.
