# Changelog

## Unreleased

### Added

- Added loop engineering positioning and taxonomy guidance.
- Added loop contract, manual loop budget, and granularity gate guidance to coordinator prompts and work-order templates.

## v0.1.1 - 2026-06-05

### Added

- Added shared checker value helpers for board statuses and worker-report strict values.
- Added right-sized work-order guidance to help coordinators avoid over-fragmenting tightly coupled feedback loops.
- Added parser boundary coverage for Markdown sections and verification tables.
- Added explicit brownfield pass-through support to the coordination-state summary wrapper.
- Added a controlled `integration-bringup` work-order template for manual deploy/start/trigger/observe/classify loops with evidence gates and stop rules.

### Fixed

- Hardened strict worker-report verification parsing when command cells contain pipeline characters.

### Boundary

- No daemon, GUI, automatic dispatch, autonomous execution, package publishing, deployment, merge, rollback, credential handling, hardware handling, or production behavior.

## v0.1.0 - 2026-06-01

Initial public source release.

### Included

- PowerShell verification scripts for AutoLoop coordination protocols.
- Markdown templates for boards, work orders, worker reports, integration reviews, thread registries, and stage closeout.
- Generic prompts for coordinator and worker workflows.
- Sanitized docs and examples for lightweight coordination and evidence gates.
- Pester tests and a Windows GitHub Actions verifier.

### Boundary

- No daemon, GUI, automatic Codex Desktop thread control, automatic dispatch, autonomous execution, package publishing, deployment, merge, release automation, credential handling, hardware handling, or production behavior.
- No private repository history, raw internal work orders, raw worker reports, raw trial notes, named real-project case studies, target-project data, credentials, generated runtime artifacts, or deployment artifacts.
