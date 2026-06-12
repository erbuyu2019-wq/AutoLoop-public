# AutoLoop Coordination Templates

These templates onboard a target project into the lightweight AutoLoop coordination protocol. The coordinator uses them to maintain a short board, create work orders, review worker reports, and decide when user approval is required.

For the product-level loop-engineering vocabulary that these templates support, see `../loop-engineering.md`.

## Files

- `board.md`: current-stage task board.
- `decision-log.md`: durable decisions that affect goals, interfaces, security, deployment, runtime behavior, or data shape.
- `work-order.md`: short task template for a long-lived owner thread or short-lived subagent.
- `dispatch-instruction.md`: copyable manual handoff block for sending a work order to a worker thread.
- `worker-report.md`: required return report after work is attempted.
- `stage-closeout.md`: stage compression record for completed, deferred, blocked, and gated work.
- `coordinator-startup-checklist.md`: manual startup checklist for interpreting summary-wrapper results.
- `thread-registry.md`: optional manual registry for active coordinator or worker threads in multi-thread projects.
- `gates.md`: user approval gates that must interrupt automation.

## Instance Records

- Keep `work-order.md`, `worker-report.md`, and `stage-closeout.md` as templates.
- Put issued work orders in `docs/coordination/work-orders/`.
- Put returned worker reports in `docs/coordination/reports/`.
- Put trial notes or stage reviews in `docs/trials/`.
- Copy `templates/coordination/thread-registry.md` to `docs/coordination/thread-registry.md` only when a project needs manual active-thread context. Single-thread projects can omit it.
- Use `templates/coordination/dispatch-instruction.md` as a manual copy/paste aid after preparing a work order; do not treat it as an automated dispatch record.
- `Dispatch note` in `work-order.md` is only a planning hint. When a coordinator creates or recommends a work order, the coordinator's final response must include either a complete `派发指令` block or a short `No dispatch` reason.
- A work order's `Required Return Report` should name the exact strict report headings and checked summary values. New or active worker reports should pass `check-report.ps1 -Strict` before coordinator acceptance.

## Loop

1. The coordinator reads `board.md`, `decision-log.md`, `gates.md`, and current git/worktree status.
2. The coordinator fills a short `work-order.md` for one owner or one bounded subagent task.
3. The coordinator outputs a manual dispatch instruction when asking the user to start a worker thread.
4. The worker checks the dispatch instruction against the work order, stays inside allowed scope, and returns a `worker-report.md`.
5. The coordinator reviews strict report shape, verification evidence, contract impact, not-verified items, and risks.
6. The coordinator updates `board.md`; only gate-triggering items interrupt the user.
7. The coordinator writes `stage-closeout.md` when a stage needs compression before the next stage.

## Work-Order Modes

Use the smallest mode that fits the current coordination problem:

- `standard`: one bounded implementation, documentation, review, or report task with a narrow allowed scope.
- `report-only`: evidence refresh, investigation summary, readiness audit, or closeout where product/runtime files must not change.
- `integration-bringup`: a manual, evidence-gated handoff for approved integration bring-up loops where deploy/start/trigger/observe/classify steps need to stay together to avoid losing the causal chain.

Before drafting or dispatching a work order, record a `Granularity Gate` decision: `bounded bundle`, `split work orders`, `report-only`, `integration-bringup`, or `no dispatch`, with a short reason. Default to one bounded bundle when the owner, workspace or worktree, objective, risk envelope, contract boundary, and evidence gate are the same. Split only when owner, workspace or worktree, risk level, contract boundary, acceptance gate, user approval requirement, or evidence type differs enough that one report would blur responsibility or safety.

A work order should close a useful feedback chain, not only one mechanical action. Useful chains include `edit-test-observe`, `hypothesis-fix-verify`, `deploy-start-trigger-observe-classify`, and `evidence-refresh-review`. For low-risk local work, allow reasonable edit-test iterations, harmless retries, and local reruns inside the work order. Reserve explicit one-attempt limits for live hardware, target-device mutation, real credentials, deployment, production, release, rollback, destructive actions, irreversible state, or explicit user or work-order requirements.

Treat each issued work order as the loop contract for one bounded AutoLoop loop. Existing fields define the contract: goal and owner, allowed and forbidden scope, required approach, acceptance commands, stop-and-report conditions, and required return report. Use manual loop budgets such as a short timebox or a small fix-test cycle budget when they help keep a same-boundary feedback loop together. The loop must stop when its budget is exceeded, a new blocker class appears, or scope, security, data, credential, hardware, deployment, production, rollback, or verification assumptions change. This is coordinator guidance only; it does not add checker-enforced budgets or automatic retry behavior.

Choose `integration-bringup` only after confirming that over-splitting would hide the integration seam. The work order must record objective reclassification, runtime topology, allowed actions, forbidden actions, stop rules, and an evidence matrix that separates command accepted, runtime state, data flow, user-visible outcome, and remaining gaps. This mode remains L0-L2 coordination by default: it does not select tasks, dispatch threads, run commands automatically, grant L3 execution, operate hardware, use credentials, deploy, roll back, or write target projects without explicit user approval in the work order.

Start from `templates/coordination/integration-bringup-work-order.md` when using this mode.

## Coordinator Startup Runbook

Use the summary wrapper at the start of a coordinator session when one person needs a compact, read-only view across one or more local projects. It is an orientation aid only; it does not choose tasks, update boards, assign owners, dispatch workers, or execute L3 work.

Set `$AutoLoopRoot` once per coordinator session to the AutoLoop checkout root. Do not infer it from the current directory, because the coordinator may run these commands from a target project directory.

Run one project:

```powershell
$AutoLoopRoot = "<path-to-autoloop-root>"
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $AutoLoopRoot "scripts\coordination\summarize-coordination-state.ps1") `
  -ProjectRoots <target-project>
```

Run multiple projects:

```powershell
$AutoLoopRoot = "<path-to-autoloop-root>"
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $AutoLoopRoot "scripts\coordination\summarize-coordination-state.ps1") `
  -ProjectRoots <project-a>,<project-b>,<project-c>
```

For mature brownfield projects with historical worker-report shape debt, add explicit `-Brownfield` to the summary command. This keeps old strict report-shape debt visible as warnings while preserving focused `check-report.ps1 -Strict` for active or new reports.

Use `-Json` only when another read-only review tool needs the aggregate fields. Consumers must check `schemaVersion` before relying on field names.

Use `templates/coordination/coordinator-startup-checklist.md` when a session needs a repeatable manual record of summary result, drill-down commands, gates, and the next coordinator action.

If `docs/coordination/thread-registry.md` exists, read it during coordinator startup as a manual active-thread context list. Use it to notice owner lanes, workspaces, expected reports, and stale rows; do not use it to rank tasks, assign owners, dispatch threads, or close board items.

When preparing or recommending a new work order, include a dispatch instruction block from `templates/coordination/dispatch-instruction.md`. It should name the target thread or owner lane, workspace, branch, work order, expected report, concurrency mode, granularity decision, file boundary, registry note, and startup sentence. If the target or concurrency mode is unclear, use `ask-user`. If no worker should be started, include a short `No dispatch` reason instead. A `Dispatch note` field in the work order is not a substitute for this final-response handoff.

Interpret the aggregate result conservatively:

- `INFO`: checked coordination files did not surface protocol blockers, review gates, or dirty git warnings.
- `WARN`: coordinator awareness is needed, often because a repository is dirty or a non-blocking coordination warning exists.
- `HOLD`: a review gate, blocked task, or user decision remains open. This is not a script failure.
- `FAIL`: a protocol/check failure exists. Drill into the project before relying on the summary.

Drill down with the narrowest read-only command that explains the result:

```powershell
$AutoLoopRoot = "<path-to-autoloop-root>"
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $AutoLoopRoot "scripts\coordination\check-coordination-state.ps1") -ProjectRoot <target-project>
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $AutoLoopRoot "scripts\coordination\check-board.ps1") -BoardPath <target-project>\docs\coordination\board.md
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $AutoLoopRoot "scripts\coordination\check-report.ps1") -ReportPath <report.md> -Strict
```

Use `check-integration-review.ps1` when the question is cross-owner acceptance. A summary wrapper result is local-readiness evidence only; it is not live hardware proof, production proof, deployment proof, or permission to close a gate.

Do not use the summary output to automatically rank tasks, write board rows, assign owners, dispatch Codex threads, initialize OpenSpec, merge, release, deploy, or start L3 execution.

## Boundaries

- Current state comes from the target project's `docs/coordination/`, not chat history.
- `thread-registry.md` is execution context only; `board.md` remains the task source of truth.
- Dispatch instructions are manual copy/paste handoffs only; they do not create locks, schedule work, or control Codex Desktop threads.
- A `Dispatch note` alone is not enough for multi-thread handoff; use the full `dispatch-instruction.md` fields in the coordinator response.
- Memory should hold only durable decisions and repeated failure modes, not temporary task state.
- OpenSpec is used only when the target project already has `openspec/` or the user explicitly requests it.
- AutoLoop does not automatically merge, release, control Codex Desktop threads, dispatch threads, discover sessions, or write real credentials.

## Status Values

Tasks use only:

- `todo`
- `doing`
- `blocked`
- `review`
- `done`
