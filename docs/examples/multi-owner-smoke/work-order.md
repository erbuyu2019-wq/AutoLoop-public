# Work Order

## Summary

- ID: `T-EX-001`
- Owner: `coordinator`
- Goal: Verify local readiness across app, device, and workbench lanes before live hardware smoke.
- Priority: `normal`
- Due / checkpoint: `next integration review`

## Context

- Project stage goal: Confirm local readiness without real hardware or credentials.
- Relevant board item: `T-EX-001`
- Relevant decision / contract: `none`
- Current known state: workbench, app, and device lanes have separate owner boundaries.

## Allowed Scope

- Files / modules allowed: `docs/coordination/`, test fixtures, local smoke harnesses
- Behavior allowed to change: local readiness evidence only
- Tests / fixtures allowed: lane-specific local checks and fake/in-memory probes

## Forbidden Scope

- Do not touch: real credentials, production systems, hardware configuration, deployment
- Do not change: API/data/security/deployment contracts
- Stop and report if: live hardware, real credential, or contract change is required

## Required Approach

- Skill / discipline: `review-only`
- Implementation expectation: collect lane reports and defer live hardware proof
- Contract handling: no contract change
- Secret / private data handling: report only `password_set` or equivalent redacted evidence

## Acceptance Commands

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\check-report.ps1 -ReportPath docs\examples\multi-owner-smoke\reports\app.md -Strict
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\check-report.ps1 -ReportPath docs\examples\multi-owner-smoke\reports\device.md -Strict
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\check-report.ps1 -ReportPath docs\examples\multi-owner-smoke\reports\workbench.md -Strict
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\check-integration-review.ps1 -WorkOrderPath docs\examples\multi-owner-smoke\work-order.md -ReportPaths docs\examples\multi-owner-smoke\reports\app.md,docs\examples\multi-owner-smoke\reports\device.md,docs\examples\multi-owner-smoke\reports\workbench.md -ExpectedOwners app,device,workbench
```

Expected result:

- All lane reports pass strict report checks.
- Integration review returns `Result: ACCEPT`.
- The coordinator records that this is `local-readiness`, not live hardware proof.

## Required Return Report

Return one report per owner and one coordinator integration review.
