# Stage Closeout Prompt

Use this prompt when the coordinator closes a stage or prepares the next stage.

```text
请对当前 AutoLoop 阶段做收口复核。先只读检查，不要修改文件，除非我要求你写回 coordination 文档。

请按顺序检查：

1. 读取 `docs/coordination/board.md`、`decision-log.md`、`gates.md` 和相关 worker reports。
2. 运行或参考 AutoLoop 状态脚本输出；如果目标项目没有本地脚本，可从 AutoLoop 仓库运行 `scripts/coordination/status.ps1 -Root <project-root>`。
3. 确认所有 `done` 任务都有验证证据。
4. 确认所有 `review` 任务已有 review 结论。
5. 确认所有 `blocked` 任务有明确 blocker 和 owner。
6. 确认共享契约、API/data model、安全、部署或硬件相关变更已进入 decision log 或 contract 文档。
7. 区分本阶段已完成、可推迟、必须用户确认的事项。

输出格式：

## Stage Result

- Completed:
- Still Open:
- Blocked:
- Deferred:

## Verification Summary

- Commands / evidence:
- Missing evidence:

## Contract And Gate Review

- Contract changes:
- User gates:

## Next Stage Proposal

- Stage goal:
- Candidate tasks:
- Recommended first work orders:
- User decisions needed:

约束：

- 不要自动合并、发布、清理 worktree 或写 memory。
- 没有验证证据的任务不能标成完成。
- 如果下一阶段改变产品目标或跨 owner 契约，先要求用户确认。
```
