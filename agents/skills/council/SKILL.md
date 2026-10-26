---
name: council
description: Trigger this if the user says 'council'.
---

# Council

Bring in two delegates to help with the user's request, usually for review
or feedback, at high reasoning effort: the latest Claude Opus on `claude` and
the latest GPT Sol on `codex`.

In Parallax, use `orchestrator_capabilities` to resolve the models, then
`delegate_task` to start one delegate per model in parallel. When `codex` lists
no models, omit `model`. It then runs the default from
`~/.dotfiles/agents/codex/config.toml`, which is a Sol model. Elsewhere, use
the harness's subagent tools. If either member is unavailable, report it
instead of substituting.

Give each delegate the request and relevant context. For review or feedback,
keep their work read-only. Collect their responses and summarize the useful
findings, disagreements, and recommended next steps.

For a code review, ask each delegate for a score out of 10.
Count each full review pass as one round.
A fresh review after fixes starts a new round.

If the work ends in a pull request, put the results in the PR description.
Put this section before the model and harness line at the end:

```markdown
## Council review

Rounds: 2

| Delegate | Round 1 | Round 2 |
| --- | --- | --- |
| Claude Opus | 7/10 | 9/10 |
| GPT Sol | 8/10 | 10/10 |
```

If a delegate gives no score, write `no score`. Do not invent one.
If the PR is open, edit the description. Do not post a comment for this.
If there is no PR, put the same results in the final reply only.

If you agree with their recommendations, make the changes and request a fresh
review after. Continue this process until all delegates are satisfied with the
outcome.

Do not let repeated reviews result in scope creep. It is your job to fight to
keep scope limited.
