# Release Boundaries

AutoLoop keeps private coordination history, public-facing changelog text, release notes, and public-export sync evidence separate. This helps coordinators publish clear public updates without leaking private planning context or treating publication evidence as product/runtime proof.

## Record Types

| Record type | Belongs in | Purpose |
| --- | --- | --- |
| Private coordination history | Private `docs/coordination/`, `docs/trials/`, work orders, worker reports, board rows, and stage closeouts | Preserve internal planning, evidence, risks, acceptance decisions, and deferred work. |
| Public changelog entries | Public-safe changelog or equivalent public docs in the export/release surface | Summarize user-visible or reusable project changes without private paths, trial-project details, or coordination transcripts. |
| Release notes | The release artifact or public release-notes file for a specific version | Explain what a public version contains, what is not included, and any compatibility notes. |
| Public-export sync evidence | Private worker reports, trial notes, or stage closeouts for the sync work | Prove that the sanitized export was checked, scanned, pushed, or released. This evidence stays private unless separately sanitized. |

## Coordinator Guidance

- Keep private coordination evidence in the private repository by default.
- Write public changelog and release notes as concise, public-safe summaries, not copied worker reports or board history.
- Treat public-export sync evidence as local-readiness or publication evidence for that export action only. It does not prove target-project behavior, production readiness, hardware success, or live smoke.
- Do not copy private project names, local absolute paths, raw target-project observations, credentials, private captures, or generated runtime artifacts into public-facing changelog or release notes.
- Do not sync `.autoloop/public-export/AutoLoop`, create a release, update release metadata, or push public repository changes from a docs-only coordination work order unless that action is explicitly approved in a separate work order.

## Deferred Work

This document does not add release automation, public-export automation, changelog tooling, checker enforcement, JSON schema changes, or package publication. Those remain separate user-gated decisions.
