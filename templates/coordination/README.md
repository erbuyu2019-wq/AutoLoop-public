# AutoLoop Coordination Templates

These templates onboard a target project into the lightweight AutoLoop coordination protocol. The coordinator uses them to maintain a short board, create work orders, review worker reports, and decide when user approval is required.

## Files

- `board.md`: current-stage task board.
- `decision-log.md`: durable decisions that affect goals, interfaces, security, deployment, runtime behavior, or data shape.
- `work-order.md`: short task template for a long-lived owner thread or short-lived subagent.
- `dispatch-instruction.md`: copyable manual handoff block for sending a work order to a worker thread.
- `worker-report.md`: required return report after work is attempted.
- `stage-closeout.md`: stage compression record for completed, deferred, blocked, and gated work.
- `thread-registry.md`: optional manual registry for active coordinator or worker threads in multi-thread projects.
- `gates.md`: user approval gates that must interrupt automation.

## Instance Records

- Keep `work-order.md`, `worker-report.md`, and `stage-closeout.md` as templates.
- Put issued work orders in `docs/coordination/work-orders/`.
- Put returned worker reports in `docs/coordination/reports/`.
- Put trial notes or stage reviews in `docs/trials/`.
- Copy `thread-registry.md` to `docs/coordination/thread-registry.md` only when a project needs manual active-thread context. Single-thread projects can omit it.
- Use `dispatch-instruction.md` as a manual copy/paste aid after preparing a work order; do not treat it as an automated dispatch record.
- `Dispatch note` in `work-order.md` is only a planning hint. When a coordinator creates or recommends a work order, the coordinator's final response must include either a complete `派发指令` block or a short `No dispatch` reason.

## Loop

1. The coordinator reads `board.md`, `decision-log.md`, `gates.md`, and current git/worktree status.
2. The coordinator fills a short `work-order.md` for one owner or one bounded subagent task.
3. The coordinator outputs a manual dispatch instruction when asking the user to start a worker thread.
4. The worker checks the dispatch instruction against the work order, stays inside allowed scope, and returns a `worker-report.md`.
5. The coordinator reviews verification evidence, contract impact, not-verified items, and risks.
6. The coordinator updates `board.md`; only gate-triggering items interrupt the user.
7. The coordinator writes `stage-closeout.md` when a stage needs compression before the next stage.

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
