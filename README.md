# AutoLoop

AutoLoop is a lightweight coordination workflow for Codex App based development. It helps a coordinator thread manage work orders, long-lived module threads, worktree status, worker reports, verification evidence, and user decision gates.

AutoLoop is not a background daemon, GUI, project management database, autonomous coding robot, or replacement for a target project's own `AGENTS.md`, tests, OpenSpec, CI, release process, or human approval gates.

For product positioning and loop taxonomy, see `docs/loop-engineering.md`.
For common misuse patterns, see `docs/anti-patterns.md`.
For private/public changelog and release-note boundaries, see `docs/release-boundaries.md`.

## Requirements

- Windows with Windows PowerShell 5.1 is the supported runtime.
- Git must be available on `PATH` for repository and worktree status checks.
- The test suite currently uses Pester 3.4.0; GitHub Actions installs this version explicitly.
- PowerShell 7, macOS, and Linux are not yet claimed as fully supported. Some library functions may be portable, but the full verifier and command examples are Windows-first.

## When To Use It

Use AutoLoop when a local project needs:

- Multiple Codex threads or worktrees with clear ownership.
- Short work orders with allowed and forbidden scope.
- Worker reports that include changed files, checks, risks, and contract impact.
- A repeatable way to decide whether work can continue, needs rework, or needs user approval.
- A controlled integration bring-up handoff when deploy, start, trigger, observe, and classify steps need to stay together under explicit stop rules.

Avoid AutoLoop for tiny one-off edits where a normal prompt and a direct test run are enough.

## Five-Minute Quickstart

Choose the onboarding mode first:

- `greenfield/light`: use when the target project is early and needs its first coordination skeleton.
- `brownfield/multi-worktree`: use when the target project already has history, worktrees, or owner lanes and AutoLoop should attach only to the current stage.

See `docs/onboarding-modes.md` for details.

Pattern examples:

- `docs/examples/single-owner-greenfield/`
- `docs/examples/multi-owner-smoke/`

When adopting AutoLoop in a target project, use `templates/project-agents-template.md` as a starting point for that project's `AGENTS.md` mapping.

Preview onboarding first:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\init-autoloop.ps1 `
  -ProjectRoot <target-project> `
  -ProjectName <name> `
  -Owners app,device,algo `
  -DryRun
```

If the preview is correct, run without `-DryRun`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\init-autoloop.ps1 `
  -ProjectRoot <target-project> `
  -ProjectName <name> `
  -Owners app,device,algo
```

Inspect target project status:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\status.ps1 -Root <target-project>
```

Check a returned worker report:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\check-report.ps1 `
  -ReportPath <target-project>\docs\coordination\reports\<report>.md `
  -Strict
```

## Default Workflow

1. Read `AGENTS.md`, `docs/coordination/README.md`, `board.md`, `decision-log.md`, and `gates.md`.
2. Optionally run `summarize-coordination-state.ps1` across one or more target projects as a read-only startup digest.
3. Run `status.ps1` or focused coordination checks against the target project that needs human review.
4. Make a `Granularity Gate` decision, then fill a short work order from `docs/coordination/work-order.md`.
5. Give the work order to one owner thread or one short-lived subagent.
6. Require the worker to return `worker-report.md` with the exact strict headings and checked summary values from the work order.
7. Review verification evidence, scope, contract impact, and risk.
8. Move the task to `done` only when the quality gates are satisfied.

Default to one bounded bundle when the owner, workspace or worktree, objective, risk envelope, contract boundary, and evidence gate are the same. Split only when one report would blur responsibility or safety. Use `templates/coordination/integration-bringup-work-order.md` only when a standard work order would over-split an integration loop. It is a manual, evidence-gated work-order mode for approved deploy/start/trigger/observe/classify loops; it does not authorize automatic execution, live smoke, hardware access, credentials, deployment, rollback, or target-project writes by itself.

For coordinator startup guidance, see the runbook in `docs/coordination/README.md` and the manual checklist template in `templates/coordination/coordinator-startup-checklist.md`.

## Common Commands

`scripts\autoloop.ps1` is an optional shorthand that delegates to the existing scripts below; the individual script entry points remain supported.

```powershell
# Show shorthand commands
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\autoloop.ps1 help

# Example shorthand status check
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\autoloop.ps1 status -Root <target-project>

# Read-only coordinator startup diagnostic
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\autoloop.ps1 doctor -ProjectRoot <target-project>

# Brownfield diagnostic for projects with historical worker-report shape debt
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\autoloop.ps1 doctor -ProjectRoot <target-project> -Brownfield
```

```powershell
# Preview onboarding
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\init-autoloop.ps1 -ProjectRoot <target-project> -DryRun

# Force template refresh after review
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\init-autoloop.ps1 -ProjectRoot <target-project> -Force

# Summarize repo and .worktrees/*
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\status.ps1 -Root <target-project>

# Emit machine-readable repo and .worktrees/* status
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\status.ps1 -Root <target-project> -Json

# Check coordination files and git state without choosing tasks
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\check-coordination-state.ps1 -ProjectRoot <target-project>

# Emit machine-readable coordination-state findings
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\check-coordination-state.ps1 -ProjectRoot <target-project> -Json

# Brownfield aggregate lens: keep historical report-shape debt visible as warnings
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\check-coordination-state.ps1 -ProjectRoot <target-project> -Brownfield

# Summarize one or more coordination-state checks without choosing tasks
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\summarize-coordination-state.ps1 -ProjectRoots <target-project>

# Summarize mature brownfield projects with historical report-shape debt as warnings
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\summarize-coordination-state.ps1 -ProjectRoots <target-project> -Brownfield

# Emit machine-readable aggregate coordination-state summary
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\summarize-coordination-state.ps1 -ProjectRoots <target-project> -Json

# Check report completeness and strict worker-report values
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\check-report.ps1 -ReportPath <report.md> -Strict

# Check work-order completeness
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\check-work-order.ps1 -WorkOrderPath <work-order.md>

# Check a work-order / worker-report pair
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\check-work-result.ps1 -WorkOrderPath <work-order.md> -ReportPath <worker-report.md>

# Check board protocol
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\check-board.ps1 -BoardPath <board.md>

# Check the multi-owner example board
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\check-board.ps1 -BoardPath docs\examples\multi-owner-smoke\board.md

# Check a multi-owner integration review
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\check-integration-review.ps1 `
  -WorkOrderPath <work-order.md> `
  -ReportPaths <app-report.md>,<device-report.md>,<workbench-report.md> `
  -ExpectedOwners app,device,workbench

# Check the single-owner greenfield example
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\coordination\check-work-result.ps1 `
  -WorkOrderPath docs\examples\single-owner-greenfield\work-order.md `
  -ReportPath docs\examples\single-owner-greenfield\reports\worker-report.md

# Run AutoLoop repository verification
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify-autoloop.ps1
```

Quick verification is a read-only coordinator preflight only. It is useful for daily protocol checks, but it intentionally omits Pester, historical examples, cached diff checks, and repository-wide text whitespace scans. Full `scripts\verify-autoloop.ps1` remains required before acceptance, commit, release, or completion claims.

```powershell
# Quick coordinator preflight without focused work-order/report checks
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify-autoloop.ps1 -Quick

# Quick coordinator preflight with explicit focused work-order/report checks
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify-autoloop.ps1 -Quick `
  -WorkOrderPath docs\coordination\work-orders\<work-order>.md `
  -ReportPath docs\coordination\reports\<worker-report>.md
```

## Automation Levels

AutoLoop uses explicit automation levels. See `docs/automation-levels.md`.

- L0: read-only status and report completeness.
- L1: lint board, work orders, reports, and scope.
- L2: draft next steps and work orders without code changes.
- L3: execute low-risk scoped tasks only with approval.
- L4: commit/open PR only with gates.
- L5: auto-merge, release, rollback; not a default AutoLoop capability.

L2 drafting prompts live in `prompts/draft-work-order.md` and `prompts/suggest-next.md`. L3 pilot rules live in `docs/l3-pilot-rules.md`.

## Safety Boundaries

AutoLoop does not automatically:

- Merge, release, deploy, or roll back.
- Operate hardware, production systems, real credentials, or private data.
- Initialize OpenSpec in a target project.
- Control other Codex Desktop threads.
- Replace project-specific rules in `AGENTS.md`.

## Encoding

Scripts read and write Markdown with explicit UTF-8. Core operational templates should stay ASCII or English where practical. Chinese prompt documents can stay UTF-8; inspect them with `Get-Content -Encoding UTF8` in Windows PowerShell. See `docs/encoding.md`.

## Repository Checks

Run local checks before pushing changes to AutoLoop itself:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify-autoloop.ps1
git diff --check
```
