# Single Owner Greenfield Example

This example shows one complete AutoLoop loop for a small greenfield project with one owner. It is intentionally generic and does not depend on a real product, credential, service, hardware device, or deployment target.

Files:

- `work-order.md`: a filled work order for one documentation owner.
- `reports/worker-report.md`: the matching worker report.

Run from the AutoLoop repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\check-work-order.ps1 -WorkOrderPath docs\examples\single-owner-greenfield\work-order.md
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\check-report.ps1 -ReportPath docs\examples\single-owner-greenfield\reports\worker-report.md -Strict
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\check-work-result.ps1 -WorkOrderPath docs\examples\single-owner-greenfield\work-order.md -ReportPath docs\examples\single-owner-greenfield\reports\worker-report.md
```

Expected result:

- The work order passes.
- The worker report passes strict validation.
- The work-result pair passes because the report mirrors every acceptance command from the work order.
