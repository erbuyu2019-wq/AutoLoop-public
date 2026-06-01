# Coordinator Startup Checklist

Use this checklist at the start of a coordinator session after reading the target project's `AGENTS.md` and coordination rules. It is a manual review aid only. It does not rank tasks, assign owners, update boards, dispatch workers, or execute code.

## Session Scope

- Coordinator:
- Date:
- Target project roots:
- Active user request:
- Out-of-scope systems:
- User approval gates known before startup:

## Startup Commands

Run the read-only summary first:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Projects\AutoLoop\scripts\coordination\summarize-coordination-state.ps1 -ProjectRoots <target-project>
```

For multiple projects:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Projects\AutoLoop\scripts\coordination\summarize-coordination-state.ps1 -ProjectRoots <project-a>,<project-b>,<project-c>
```

Drill down only as needed:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Projects\AutoLoop\scripts\coordination\check-coordination-state.ps1 -ProjectRoot <target-project>
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Projects\AutoLoop\scripts\coordination\check-board.ps1 -BoardPath <target-project>\docs\coordination\board.md
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Projects\AutoLoop\scripts\coordination\check-report.ps1 -ReportPath <report.md> -Strict
```

## Result Handling

| Summary Result | Manual Coordinator Action | Do Not Infer |
| --- | --- | --- |
| `INFO` | Continue with normal coordinator review. Confirm the request still matches the current board and project rules. | Do not treat this as product correctness, live proof, or permission to merge. |
| `WARN` | Inspect dirty repositories or warning findings. Decide whether they are expected active work before issuing more work. | Do not treat dirty files as failure by themselves. |
| `HOLD` | Drill into blocked/review tasks, user gates, and integration-review evidence before closing or dispatching anything. | Do not treat lane-local reports as cross-owner acceptance. |
| `FAIL` | Stop task advancement and fix protocol/report/work-order/board issues first. | Do not rely on summary output for readiness decisions until the protocol failure is resolved. |

## Evidence Notes

Record only concise status evidence:

- Summary result:
- Projects checked:
- Dirty repositories:
- Blocked or review tasks:
- Failed protocol checks:
- Reports checked:
- Integration review needed:
- User decision needed:

## Boundary Check

Before issuing or accepting work, confirm:

- No automatic task ranking was used.
- No board rows were written from summary output alone.
- No owner assignment or Codex thread dispatch was automated.
- No OpenSpec initialization was performed unless explicitly requested.
- No hardware, production, deployment, private data, or real credentials were touched.
- Local-readiness evidence was not described as live, production, deployment, hardware, or end-to-end proof.

## Coordinator Decision

- Next manual action:
- Evidence supporting it:
- Remaining uncertainty:
- User gate required:
