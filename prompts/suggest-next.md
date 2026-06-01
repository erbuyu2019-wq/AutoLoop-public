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

## Draft Work Orders

- `<only include if a draft would be useful; otherwise say none>`

Constraints:

- Do not edit files.
- Do not update task status.
- Do not choose or execute the next step automatically.
- Do not dispatch work to another thread or subagent.
- Do not merge, release, deploy, operate hardware, or use real credentials.
- If evidence is missing, say what is missing instead of guessing.
```
