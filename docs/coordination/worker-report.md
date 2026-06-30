# Worker Report

## Summary

- Work order ID: `<T-XXX>`
- Owner: `<owner>`
- Result: `<done | partial | blocked | rejected>`
- Branch / workspace: `<branch and path>`
- Report date: `<YYYY-MM-DD>`
- Evidence level: `<local-readiness | hardware-deferred | live-smoke-required | live-smoke-complete | not applicable>`
- Dispatch/base commit: `<commit or not applicable>`
- Verified branch HEAD: `<commit or worktree state verified>`
- Observed integration branch: `<master/main@commit, not checked, or not applicable>`
- Integration baseline policy: `<dispatch-base acceptable | refresh-before-merge | batch-baseline | current-integration required | not applicable>`
- Integration drift status: `<none observed | observed-no-refresh-needed | refresh performed | refresh required-deferred | not applicable> - <short reason>`

This worker report is the Execution Record for the work order's Loop Contract. It should give the coordinator enough evidence to make an Acceptance Decision without relying on chat history. See `../loop-contract-model.md` for the model map.

## Changed Scope

| File / Area | Change | Reason |
| --- | --- | --- |
| `<path>` | `<what changed>` | `<why>` |

## Verification

| Command | Result | Evidence |
| --- | --- | --- |
| `<command>` | `<passed | failed | not run>` | `<key output or reason>` |

Git evidence boundary guidance:

- Label git evidence as one of `implementation/code evidence`, `pre-report-commit evidence`, or `coordinator final acceptance evidence`.
- Use `implementation/code evidence` for the commit or worktree state that was actually verified by implementation, tests, or local smoke checks.
- Use `pre-report-commit evidence` when the worker report itself, or a later report-only correction, may be committed after the evidence was captured.
- Use `coordinator final acceptance evidence` only for final git state captured by the coordinator after the last commit, merge, push, or report-only boundary.
- A worker report does not need to chase its own future report-only commit. If the report changes HEAD, the coordinator captures final acceptance evidence after that boundary.
- Report-only HEAD drift is not a default worker refresh trigger. If only the worker report or a report-only correction changed after implementation verification, keep `implementation/code evidence` separate from coordinator final acceptance evidence instead of rerunning expensive checks.
- Request worker refresh only when material drift can invalidate implementation evidence, such as overlapping files, shared contracts, schemas, config, tests, runtime/deployment behavior, release/hardware/production paths, explicit current-integration proof, or a work-order requirement.
- A clean committed package with stale worker-report git evidence does not need a report rewrite by default. Coordinator final git evidence can be captured in review or closeout when the worktree is clean, checks passed, and only final `HEAD`, integration-branch, divergence, or log evidence is stale.
- Amending a report-only correction into the latest local commit is acceptable only when the branch is local, unpublished, owned by the worker, and has no shared-history risk. Otherwise use a separate report-only commit or leave final git evidence to coordinator acceptance. Do not require amend as the default.

Integration branch baseline guidance:

- `dispatch-base acceptable`: branch-local readiness against the dispatch/base commit is acceptable; coordinator owns final integration verification.
- `refresh-before-merge`: one bounded refresh/revalidation is expected near acceptance, not unlimited rebase/retest after unrelated integration-branch movement.
- `batch-baseline`: coordinator-defined acceptance batch uses one shared baseline for multiple ready branches.
- `current-integration required`: worker proves against current `master` or `main` for high-risk, overlapping-file, shared-contract, config/schema/test/runtime/deployment/release/hardware/production, or explicitly requested work.
- Record drift facts without automatically chasing them. Refresh only when the coordinator or work order identifies drift that can invalidate the evidence.

## Contract Impact

- Public behavior changed: `<yes/no>`
- API / data model changed: `<yes/no>`
- Security / secret handling changed: `<yes/no>`
- Deployment / runtime behavior changed: `<yes/no>`
- Details: `<impact description or none>`

## Not Verified

- `<item not verified and why>`

## Risks

- `<remaining risk or none>`

## Next Suggested Step

- `<continue | review | needs coordinator decision | needs user decision | blocked>`
- Reason: `<one sentence>`
