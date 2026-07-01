# Changelog

## Unreleased

### Added

- Added public-facing onboarding links for parallel assistant workflows, boundaries against agent runtimes, and launch-copy adaptation.
- Added a public-safe parallel Codex workflow use case.
- Added a neutral AutoLoop versus agent-runtime comparison.
- Added launch-post and GitHub topic suggestion drafts for human-maintained project promotion.

### Boundary

- No daemon, GUI, automatic dispatch, autonomous execution, package publishing, deployment, merge, rollback, release creation, GitHub metadata mutation, credential handling, hardware handling, production behavior, or L3 automation behavior.

## v0.1.4 - 2026-06-30

### Added

- Added public guidance for keeping private coordination history, public changelog entries, release notes, and public-export sync evidence separate.
- Added tool-neutral dispatch channel guidance for manual copy, optional cross-thread send, and external handoff workflows while preserving manual fallback.
- Added a lightweight Loop Contract model map that explains work orders, worker reports, and coordinator reviews as existing protocol artifacts.

### Changed

- Clarified parallel branch baseline and drift-impact guidance so workers can report branch-local readiness while coordinators own final integration proof.
- Clarified report-only HEAD drift guidance so coordinators capture final acceptance git evidence instead of sending workers into self-referential report refresh loops.
- Clarified that clean committed packages with stale worker-report git evidence should use coordinator final git evidence capture by default, while preserving worker refresh for uncommitted packages, dirty worktrees, post-verification source/test changes, and material integration drift.
- Clarified Fast Integration Check as the default integration-review path and Deep Integration Review as a triggered escalation.

### Boundary

- No daemon, GUI, automatic dispatch, autonomous execution, package publishing, deployment, merge, rollback, credential handling, hardware handling, production behavior, private review-tool dependency, or L3 automation behavior.

## v0.1.3 - 2026-06-17

### Added

- Added a generic single-owner greenfield example with matching work-order, worker-report, and work-result checks.
- Added public anti-pattern guidance for local-readiness misuse, incomplete dispatch handoffs, over-split feedback loops, and private-tool coupling.
- Added a target-project `AGENTS.md` starter template for mapping project-defined review, commit, and acceptance gates.
- Added focused Pester tests for shared checker values and worker-report validation helpers.

### Changed

- Replaced outdated real-project example links in the README with public-safe generic examples.
- Documented Windows PowerShell 5.1, Git, and Pester 3.4.0 as the supported runtime baseline.
- Made `Loop budget` explicit in work-order templates and drafting prompts while keeping it as human coordinator guidance.
- Extended repository verification to cover the new single-owner greenfield example.

### Boundary

- No daemon, GUI, automatic dispatch, autonomous execution, package publishing, deployment, merge, rollback, credential handling, hardware handling, production behavior, private review-tool dependency, or L3 automation behavior.

## v0.1.2 - 2026-06-17

### Added

- Added shared strict worker-report validation helpers used by direct report checks and aggregate coordination-state scans.
- Added loop engineering positioning and taxonomy guidance.
- Added loop contract, manual loop budget, and granularity gate guidance to coordinator prompts and work-order templates.
- Added tool-neutral review gate, independent review, commit authority, and final acceptance owner guidance.

### Changed

- Improved public dispatch wording by using the English `dispatch instruction` phrase consistently.

### Boundary

- No daemon, GUI, automatic dispatch, autonomous execution, package publishing, deployment, merge, rollback, credential handling, hardware handling, production behavior, or L3 automation behavior.

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
