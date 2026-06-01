# Work Order

## Summary

- ID: `T-EX-002`
- Owner: `coordinator`
- Goal: Run live hardware smoke after local readiness is accepted.
- Priority: `normal`
- Due / checkpoint: `requires user approval`

## Context

- Project stage goal: Convert local readiness into live device evidence.
- Relevant board item: `T-EX-002`
- Relevant decision / contract: requires user approval gate
- Current known state: `T-EX-001` accepted local readiness only.

## Allowed Scope

- Files / modules allowed: project-specific smoke logs and approved runtime paths
- Behavior allowed to change: none
- Tests / fixtures allowed: approved live smoke command only

## Forbidden Scope

- Do not touch: real credentials, hardware, deployment, or production systems without explicit user approval
- Do not change: API/data/security/deployment contracts
- Stop and report if: credentials, device access, or deployment behavior differs from the approved plan

## Required Approach

- Skill / discipline: `karpathy-deep`
- Implementation expectation: run only the approved live smoke and report evidence
- Contract handling: no contract change
- Secret / private data handling: redact all credentials and report only safe fields

## Acceptance Commands

```powershell
throw "Replace this guard with the project-approved live smoke command after user approval"
```

Expected result:

- After user approval and command replacement, the live hardware path produces approved evidence.
- Credentials remain redacted.

## Required Return Report

Return a worker report with evidence level `live-smoke-required` resolved to live smoke evidence.
