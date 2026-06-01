# AutoLoop Working Agreements

AutoLoop is a lightweight coordination protocol and evidence-gate toolkit for Codex-assisted development. Keep changes in this repository aligned with that product boundary.

## Default Boundary

- Keep AutoLoop focused on L0-L2 by default: status, lint, work orders, worker reports, integration review, evidence levels, and user gates.
- Do not turn AutoLoop into a daemon, GUI, project-management database, autonomous coding agent, or automatic multi-agent runtime.
- Do not automatically control Codex Desktop threads.
- Do not automatically initialize OpenSpec in this repository or in target projects.
- Do not automatically merge, release, deploy, roll back, or publish PRs.
- Do not touch real credentials, private data, hardware, production systems, deployment behavior, or live infrastructure unless a user explicitly approves that specific action.

## Implementation Discipline

- Prefer small, test-backed changes that improve reuse, verification, or evidence clarity.
- Keep scripts PowerShell 5.1 compatible unless the project explicitly changes its runtime target.
- Read and write Markdown files with explicit UTF-8 handling in scripts.
- Keep board, work-order, report, and integration checks as protocol lint. They must not infer priorities, schedule work, or make automatic next-step decisions.
- Preserve the distinction between local readiness and live hardware proof.

## Verification

Before claiming repository changes are complete, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify-autoloop.ps1
git diff --check
```
