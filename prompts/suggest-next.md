# Suggest Next Prompt

Use this prompt when the coordinator wants a read-only next-step suggestion. This is L2 drafting assistance only.

```text
You are helping suggest the next AutoLoop coordination step. Work in read-only mode.

Inputs to inspect:

1. `docs/coordination/board.md`
2. `docs/coordination/decision-log.md`
3. `docs/coordination/gates.md`
4. relevant work orders, worker reports, integration reviews, and stage closeouts
5. optional output from `scripts/coordination/status.ps1`

Task:

- Summarize the current stage state.
- Identify tasks that are ready for coordinator review, need rework, are blocked, or need user approval.
- Suggest one to three candidate next steps.
- Explain the evidence behind each suggestion.
- Mark any gate that requires user confirmation.
- Before suggesting draft work orders, make a `Granularity Gate` decision for each candidate: `bounded bundle`, `split work orders`, `report-only`, `integration-bringup`, or `no dispatch`, with a short reason.
- Treat any proposed work order as the loop contract for one bounded AutoLoop loop. Existing fields should define goal/owner, allowed and forbidden scope, required approach, acceptance commands, stop-and-report conditions, and required return report.
- Default to one bounded bundle when the owner, workspace or worktree, objective, risk envelope, contract boundary, and evidence gate are the same.
- Split only when owner, workspace or worktree, risk level, contract boundary, acceptance gate, user approval requirement, or evidence type differs enough that one report would blur responsibility or safety.
- Prefer `integration-bringup` when deploy/start/trigger/observe/classify steps must stay together to preserve the causal chain.
- Apply Efficiency Guardrails to each candidate:
  - Evidence value: classify the next evidence as `direct product proof`, `runtime proof`, `integration proof`, `proxy evidence`, or `planning evidence`.
  - Fast lane: state whether same-owner, same-worktree, same-objective, same-risk, same-contract, same-evidence-gate work can stay in one bounded implementation/local verification/report bundle.
  - Planning depth: if recent work for the same objective is already mostly planning or proxy evidence, favor implementation/proof, a user decision, or `no dispatch` over another proxy/planning task.
  - Loop budget: when a same-boundary feedback loop needs iteration, suggest a manual timebox or small fix-test cycle budget and stop conditions instead of automatic retry behavior or micro-work-orders.
  - Treat this as read-only coordinator judgment; do not add checker rules, automatic selection, or exhaustive history counting.

Output:

## Current State

- Ready for review:
- Needs rework:
- Blocked:
- User approval needed:

## Suggested Next Steps

1. `<candidate step>`
   - Reason:
   - Evidence:
   - Gate:
   - Granularity Gate:
   - Fast lane:
   - Evidence value:
   - Planning depth:
   - Loop budget:

## Draft Work Orders

- `<only include if a draft would be useful; otherwise say none>`
- For each draft, include the granularity decision and keep same-boundary work as one bounded bundle unless the split conditions above apply.
- Do not draft another proxy-only or planning-only task when a bounded implementation/proof work order, user decision, or `no dispatch` reason is the more direct next step.

Constraints:

- Do not edit files.
- Do not update task status.
- Do not choose or execute the next step automatically.
- Do not dispatch work to another thread or subagent.
- Do not add automatic task selection, automatic retry, automatic dispatch, Codex Desktop thread control, or execution authority.
- Do not merge, release, deploy, operate hardware, or use real credentials.
- If evidence is missing, say what is missing instead of guessing.
- If missing evidence can be repaired inside the same owner/workspace/objective/risk/contract/evidence boundary, prefer same-boundary evidence repair over a new micro-work-order.
- Do not use fast lane for credentials, hardware, live targets, production, deployment, release, rollback, private captures, schema/contract changes, or cross-owner integration closure.
- Do not turn manual loop budgets into automatic retry, automatic execution, checker-enforced budget counting, or permission to exceed stop conditions.
```
