# Loop Engineering

AutoLoop is a lightweight loop-engineering protocol for Codex-assisted development. It helps a human coordinator shape agent work into bounded cycles with explicit contracts, evidence, stop rules, and human gates.

Loop engineering in AutoLoop does not mean an autonomous loop runner. It means making each coordination loop small enough to review, broad enough to close a useful feedback chain, and explicit enough that workers know when to continue, stop, repair, or ask for a decision.

## Existing Primitives

| Loop Engineering Need | AutoLoop Primitive |
| --- | --- |
| Goal and state | `board.md`, stage goal, stage closeout |
| Scope contract | Work order allowed scope, forbidden scope, stop rules |
| Owner and workspace | Owner lane, workspace/worktree field, optional thread registry |
| Evidence | Worker report verification, evidence level, not-verified items |
| Stop and escalation | `gates.md`, blocked rows, risks, user-decision next steps |
| Review | Strict report checks, paired work-result check, coordinator review prompts |
| Compression | `stage-closeout.md`, historical references |
| Efficiency control | Granularity Gate, Fast Lane, Evidence Value, Planning Depth |
| Git evidence boundary | Implementation/code evidence, pre-report-commit evidence, coordinator final acceptance evidence |

These primitives stay in the existing board, work-order, report, gate, prompt, and template surfaces. Phase 35 does not add a second schema or a new audit directory.

## Loop Types

Use these names as vocabulary for existing AutoLoop work, not as new automation modes:

- `status`: read repository, worktree, board, report, and coordination-state signals without changing project state.
- `lint`: check board, work-order, report, integration-review, or repository protocol shape.
- `draft`: prepare a work order, dispatch instruction, or next-step proposal for human review.
- `execute`: perform one bounded implementation, docs, tools, or evidence task inside an approved work order.
- `review`: inspect returned evidence, scope, risks, and contract impact before accepting or requesting repair.
- `repair`: fix a concrete issue found by review or verification without widening the original boundary.
- `integration`: keep approved deploy/start/trigger/observe/classify steps together when splitting them would hide the causal chain.
- `closeout`: compress accepted, deferred, blocked, and gated work into durable stage state.

## Non-Goals

AutoLoop does not add or authorize:

- autonomous loop runners, daemons, GUIs, automatic retries, or automatic execution;
- automatic task selection, automatic dispatch, automatic board writes, or Codex Desktop thread control;
- automatic merge, commit, push, release, rollback, deployment, or production operation;
- hardware operation, credential use, private-data handling, live smoke, or target-project writes unless a separate user-approved work order explicitly allows that action;
- checker-enforced loop budgets, a `Loop Receipt` artifact, or a `docs/coordination/loops/` audit directory by default.

The default product boundary remains L0-L2: read, lint, draft, review, and gate. Any L3 execution remains explicit, scoped, and separately approved.
