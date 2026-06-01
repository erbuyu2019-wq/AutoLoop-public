# Draft Work Order Prompt

Use this prompt when the coordinator wants a draft work order. This is L2 drafting assistance only.

```text
You are helping draft an AutoLoop work order. Work in read-only mode.

Inputs to read:

1. `docs/coordination/board.md`
2. `docs/coordination/decision-log.md`
3. `docs/coordination/gates.md`
4. the relevant current reports or stage closeout, if referenced by the user

Task:

- Draft one work order for the task or owner I name.
- Use the fields from `docs/coordination/work-order.md`.
- Keep scope narrow and owner-specific.
- Include allowed scope, forbidden scope, stop conditions, acceptance commands, dispatch note, and required return report.
- Treat `Dispatch note` as a planning cue only. It is not a complete manual handoff and does not replace the coordinator's final `派发指令` block or `No dispatch` reason.
- In `Required Return Report`, list these exact worker-report headings: `Summary`, `Changed Scope`, `Verification`, `Contract Impact`, `Not Verified`, `Risks`, and `Next Suggested Step`.
- In `Required Return Report`, list the strict checked values: Summary `Result` must be `done`, `partial`, `blocked`, or `rejected`; Summary `Evidence level` must be `local-readiness`, `hardware-deferred`, `live-smoke-required`, `live-smoke-complete`, or `not applicable`; `Next Suggested Step` must be `continue`, `review`, `needs coordinator decision`, `needs user decision`, or `blocked`.
- State that a `done` report must not contain `failed`, `not run`, or `not-run` results in the `Verification` table.
- If the request triggers a user gate, do not draft an execution work order. Output a user-decision summary instead.

Output:

## Draft Work Order

- ID:
- Owner:
- Goal:
- Dispatch note:
- Allowed Scope:
- Forbidden Scope:
- Required Approach:
- Acceptance Commands:
- Stop And Report If:
- Required Return Report:

## User Decision Needed

- `<none or decision summary>`

Constraints:

- Do not edit files.
- Do not update the board.
- Do not assign or dispatch the work.
- Do not execute commands.
- Do not expand the task beyond the board or user request.
- Do not treat lint success as technical correctness.
- Do not invent weaker worker-report headings or summary values than the strict checker accepts.
```
