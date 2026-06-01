# Integration Review

## Integration Result

- Result: `accept`
- Evidence level: `local-readiness`
- Accepted owners: `app`, `device`, `workbench`
- Rework needed: none
- Deferred: live hardware smoke
- User approval needed: before real credentials, hardware, deployment, or production access

## Evidence

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\check-integration-review.ps1 -WorkOrderPath docs\examples\multi-owner-smoke\work-order.md -ReportPaths docs\examples\multi-owner-smoke\reports\app.md,docs\examples\multi-owner-smoke\reports\device.md,docs\examples\multi-owner-smoke\reports\workbench.md -ExpectedOwners app,device,workbench
```

Expected output:

- `Result: ACCEPT`

## Interpretation

This accepts local readiness only. It does not prove live hardware behavior. The next stage should use `live-smoke-work-order.md`.
