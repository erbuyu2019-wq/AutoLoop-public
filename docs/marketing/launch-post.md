# Launch Post Draft

## Title

AutoLoop: lightweight coordination for parallel AI-assisted development

## Short Pitch

AutoLoop is a small Markdown and PowerShell toolkit for coordinating Codex or similar assistant-driven development across threads, worktrees, and owner lanes. It keeps work orders, worker reports, evidence gates, and coordinator review explicit without becoming an autonomous agent runtime.

## Longer Post

AI assistants make it easier to run multiple pieces of development work in parallel. The hard part is not only getting code written. It is keeping scope, evidence, ownership, and acceptance clear when several assistant threads or worktrees are active at once.

AutoLoop is a lightweight coordination protocol and evidence-gate toolkit for that problem.

The core loop is intentionally simple:

```text
work order -> worker report -> coordinator review / integration review -> closeout
```

A work order defines the Loop Contract: owner, goal, allowed scope, forbidden scope, stop rules, acceptance commands, and gate authority. A worker report returns the Execution Record: changed files, verification, contract impact, not-verified items, risks, and next suggested step. Coordinator review or integration review is the Acceptance Decision.

AutoLoop is not a daemon, GUI, autonomous agent runtime, project-management database, merge queue, or deployment tool. It does not automatically dispatch agents, control Codex Desktop threads, merge branches, operate hardware, or deploy systems. The goal is narrower: keep assistant-driven work reviewable and evidence-based.

It is useful when:

- Multiple assistant threads or worktrees are active.
- A project needs clear owner lanes and bounded work orders.
- Local readiness must stay separate from live, hardware, production, or release proof.
- Worker evidence and coordinator final acceptance need to be recorded separately.
- Teams want a lightweight repository-native alternative to chat-only coordination.

The repository includes templates, prompts, examples, and PowerShell checks for boards, work orders, worker reports, coordination state, and integration review. The fastest way to try it is to preview the onboarding skeleton with `init-autoloop.ps1 -DryRun`, then inspect the generated coordination files before applying them.

AutoLoop is designed to complement existing project rules, test suites, CI, issue trackers, and durable spec systems. It gives the coordinator a clearer handoff and review loop around assistant work; it does not replace human judgment or project-specific gates.

## Social Snippets

1. AutoLoop is a lightweight coordination protocol for parallel AI-assisted development: work order -> worker report -> coordinator review -> closeout. Markdown-first, evidence-gated, and intentionally not an autonomous agent runtime.

2. Running multiple Codex or assistant threads? AutoLoop keeps scope, verification, risks, and acceptance boundaries explicit so chat history is not the only coordination record.

3. AutoLoop is for maintainers who want repository-native work orders, worker reports, and evidence gates without adopting a daemon, GUI, merge queue, or project-management database.

4. The useful question for assistant work is often not "did something run?" but "what was allowed, what changed, what was verified, what remains unverified, and who can accept it?" AutoLoop is built around that loop.

5. AutoLoop can sit beside CI, issue trackers, durable specs, and agent runtimes. It does the coordination and evidence boundary work, not automatic execution or release.

## Adaptation Notes

- For GitHub Discussions or a blog, use the longer post and add repository-specific links.
- For Dev.to or Hacker News, keep the first three paragraphs and add a concrete workflow example.
- For Reddit, lead with the coordination problem and be explicit that AutoLoop is not an autonomous runtime.
- For X or LinkedIn, use one social snippet plus a link to the README.
- Do not add adoption, traffic, star-count, production, or customer claims unless there is public evidence.
