# Dispatch Instruction

Use this block when a coordinator has prepared or recommended a work order and needs the user to copy a clear handoff into the target worker thread. This is a manual handoff only; it does not rank tasks, assign owners automatically, lock worktrees, control Codex Desktop threads, or update `thread-registry.md`.

Coordinator output invariant: whenever a coordinator creates or recommends a work order, its final response must include either a complete `派发指令` block or a short `No dispatch` reason explaining why no worker should be started. A `Dispatch note` inside a work order is only a planning hint; it is not a complete multi-thread handoff by itself.

## Template

```text
派发指令
- 发给：[thread label / owner lane]
- 工作区：[path]
- 分支：[branch]
- 工单：[path]
- 预期报告：[path]
- 并发：[exclusive-write | shared-read-only | report-only | ask-user]
- 文件边界：[key allowed / forbidden scope]
- Registry：[suggested row update, or none]
- 启动语：请作为 AutoLoop worker 执行该工单，先复述边界再动文件。
```

## Concurrency Modes

- `exclusive-write`: default for code, tests, OpenSpec, board, or project-state edits; do not share a worktree with another writer.
- `shared-read-only`: read-only review, audit, status check, or evidence inspection.
- `report-only`: worker-report or coordination-record correction only; no product code edits.
- `ask-user`: coordinator cannot safely choose the target thread, workspace, or sharing mode.

## No Dispatch

Use a short no-dispatch line only when no worker should be started from the current coordinator response.

```text
No dispatch: [reason no worker should be started now]
```

## Examples

```text
派发指令
- 发给：AutoLoop / docs developer / manual-dispatch-instruction
- 工作区：E:\ProductDevelop\AutoLoop
- 分支：master
- 工单：docs/coordination/work-orders/T-XXX-manual-docs-change.md
- 预期报告：docs/coordination/reports/T-XXX-worker-report.md
- 并发：exclusive-write
- 文件边界：只允许修改该工单 Allowed Scope 中列出的 docs/templates/prompts/report 文件；不得修改脚本、checker、测试或目标项目。
- Registry：none
- 启动语：请作为 AutoLoop worker 执行该工单，先复述边界再动文件。
```

```text
派发指令
- 发给：Project / coordinator reviewer / report-check
- 工作区：E:\ProductDevelop\ExampleProject
- 分支：main
- 工单：docs/coordination/work-orders/T-YYY-report-review.md
- 预期报告：docs/coordination/reports/T-YYY-worker-report.md
- 并发：shared-read-only
- 文件边界：只读检查 board/work-order/report/git 状态；不得修改产品代码、凭据、部署配置或 board 状态。
- Registry：如果存在相关行，报告建议状态；不要直接编辑 registry。
- 启动语：请作为 AutoLoop worker 执行该工单，先复述边界再动文件。
```
