# AutoLoop

AutoLoop is a lightweight coordination protocol and evidence-gate toolkit for Codex-assisted development.

It provides reusable PowerShell checks, Markdown templates, prompts, tests, generic docs, and sanitized verification fixtures for teams that want manual or semi-automatic coordination across Codex threads and worktrees without turning the workflow into an autonomous development platform.

This public repository intentionally excludes private repository history, raw internal work orders, raw worker reports, raw trial notes, named real-project case studies, local review inputs, target-project data, credentials, generated runtime artifacts, and deployment artifacts.

## Boundary

AutoLoop focuses on:

- status and coordination-state checks;
- board, work-order, report, and integration-review protocol lint;
- evidence-level clarity;
- manual dispatch and user-gated coordination.

AutoLoop does not provide a daemon, GUI, automatic Codex Desktop thread control, automatic merge/release/rollback, automatic live smoke, or default autonomous code execution.

## Verify

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify-autoloop.ps1
```

## License

MIT.
