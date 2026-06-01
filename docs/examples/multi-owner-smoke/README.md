# Multi-Owner Smoke Example

This example models a hardware-adjacent smoke task with three owner reports and one coordinator integration review.

The example result is `ACCEPT` for local readiness only. It is not live hardware proof. The follow-up `live-smoke-work-order.md` shows how to keep real-device validation separate.

Run the example board check:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\check-board.ps1 `
  -BoardPath docs\examples\multi-owner-smoke\board.md
```

Run the example integration check:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\check-integration-review.ps1 `
  -WorkOrderPath docs\examples\multi-owner-smoke\work-order.md `
  -ReportPaths docs\examples\multi-owner-smoke\reports\app.md,docs\examples\multi-owner-smoke\reports\device.md,docs\examples\multi-owner-smoke\reports\workbench.md `
  -ExpectedOwners app,device,workbench
```
