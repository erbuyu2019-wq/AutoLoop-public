# Generate Work Orders Prompt

Use this prompt when the coordinator needs to turn board items into short work orders for long-lived threads or temporary subagents.

```text
请基于当前 `docs/coordination/board.md`、`decision-log.md`、`gates.md` 和 git/worktree 状态，生成下一批可执行工单。

要求：

1. 只为状态为 `todo`、`blocked` 已解除、或 `review` 后需要返工的任务生成工单。
2. 每张工单都必须使用 `docs/coordination/work-order.md` 的字段。
3. 每张工单必须明确：
   - owner
   - 目标
   - 允许修改范围
   - 禁止触碰范围
   - 是否允许契约变化
   - 验收命令
   - 停止并回报的条件
4. 工单应短而具体，不要输出长篇设计说明。
5. 如果任务触发 `gates.md`，不要生成执行工单，改为生成“需要用户确认”的决策摘要。

输出格式：

## 工单 <T-XXX>

- Owner:
- Goal:
- Allowed Scope:
- Forbidden Scope:
- Required Approach:
- Acceptance Commands:
- Stop and Report If:
- Return Report:

## 需要用户确认

- `<none or gate summary>`

约束：

- 不要扩大 board 中的任务范围。
- 不要把一个跨 owner 的大任务塞进单张工单；拆成按 owner 可交付的小工单。
- 对 subagent 工单，优先选择短期探索、review、测试补齐或窄范围修复。
```
