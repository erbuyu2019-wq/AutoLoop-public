# Work Order

## Summary

- ID: `T-PUB-002`
- Owner: `tools`
- Goal: Validate the public work-order/report paired-check fixture.
- Priority: `normal`
- Due / checkpoint: `public verification fixture`
- Dispatch note: `No dispatch; public verifier fixture only.`

## Context

- Project stage goal: Provide a minimal public paired-check fixture.
- Relevant board item: `T-PUB-001`
- Relevant decision / contract: `D-PUB-001`
- Current known state: Public example coordination files are present.

## Allowed Scope

- Files / modules allowed: `scripts/coordination/check-work-result.ps1`, `docs/coordination/`
- Behavior allowed to change: documentation fixture only
- Tests / fixtures allowed: existing AutoLoop coordination lint

## Forbidden Scope

- Do not touch: private repositories, real credentials, hardware, production systems, deployment systems, or live services
- Do not change: script behavior, automation level, repository visibility, release behavior, or deployment behavior
- Stop and report if: the fixture requires private project context

## Required Approach

- Skill / discipline: `karpathy-baseline`
- Implementation expectation: smallest public fixture that validates pair checking
- Contract handling: no contract change
- Secret / private data handling: no real credentials or private data

## Acceptance Commands

Run the cheapest decisive checks that fit the task.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\check-board.ps1 -BoardPath docs\coordination\board.md
```

Expected result:

- Board check returns `Result: PASS`.

## Required Return Report

Return the result using `worker-report.md` with changed files, verification commands and results, contract impact, risks, and next step.
