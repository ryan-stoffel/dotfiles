---
name: babysit-pr
description: Babysit an open GitHub PR until it is ready to merge, fixing failed CI, conflicts, a stale branch, and review comments along the way. Use when asked to babysit, watch, or monitor a PR, or to keep at it "until merge" or "until ready to merge".
---

# babysit-pr

Goal: the PR is **ready**, proven by `pr_status.py` printing `verdict: READY` on the current head. Ready means open, not draft, no conflicts, not behind base, every check on the head commit passed, no unresolved review threads, and no outstanding change request. If the repo's `AGENTS.md` adds a gate (for example a review comment opening `Verdict: ready to merge`), that gate is part of ready.

`~/.dotfiles/agents/skills/babysit-pr/pr_status.py` is the one readiness check and the one fallback watcher. It uses GraphQL only, so it does not spend the shared REST quota (5,000/hour across every agent on this machine). Run it from inside the repo checkout:

```sh
~/.dotfiles/agents/skills/babysit-pr/pr_status.py <number|url>            # exit 0 ready, 1 not ready, 2 read error
~/.dotfiles/agents/skills/babysit-pr/pr_status.py <number|url> --wait     # blocks until something needs action
```

## Loop

1. **Check.** Run `pr_status.py <pr>`. Handle every reason it prints, using the table below. Read new review threads and comments with `gh pr view <pr> --comments` and the review threads through `gh api graphql`.
2. **Push once.** Batch every fix into one commit, run the repo's checks locally, then push. One push per round keeps CI from restarting mid-run.
3. **Wait.** Arm exactly one watcher for the PR, then end the turn:
   - In T3 Code: `watch_pull_request` with the PR URL. It wakes you on a failed check, required checks passing, a new comment or review, or a conflict. It does not wake on "behind base", so step 1 catches that on every wake.
   - In Claude Code without T3: run `pr_status.py <pr> --wait` as a background Bash command with `timeout: 7200000`. Its exit wakes you. If it times out, start it again.
   - In Codex: run `pr_status.py <pr> --wait` and keep waiting on that same session until it exits.
4. **Wake.** Go back to step 1. A wake is news, not a verdict, so readiness comes only from `pr_status.py`.

Done when `pr_status.py` prints `verdict: READY`. Then:

- Merge only if the user asked for a merge ("until merge", "until merged", "merge"). Use the repo's merge style (squash unless `AGENTS.md` says otherwise) and keep the commit's co-author trailer.
- In T3 Code, call `unwatch_pull_request` before handing back, so the thread returns to the user's inbox.
- Report the PR URL, the head SHA, and the final verdict line.

## Handling each reason

| `pr_status.py` reason | Action |
| --- | --- |
| `failing: <check>` | Read the failed job log (`gh run view <run-id> --log-failed`), reproduce locally, fix the root cause. A flaky check gets one rerun (`gh run rerun <run-id> --failed`), and a second flake becomes a reported issue, not a third rerun. |
| `pending: ...` or `no checks reported on head yet` | Wait (step 3). Right after a push the head has no checks yet. That is pending, never green. |
| `merge conflict with base` / `N commits behind <base>` | `git fetch origin && git rebase origin/<base>`, resolve, rerun local checks, `git push --force-with-lease`. |
| `N unresolved review threads` / `changes requested` | Fix what is right. Reply on the thread with the commit SHA or the reason it stays as is, then resolve it (`resolveReviewThread` mutation via `gh api graphql`). Bot reviewers (Codex, Copilot) count the same as people. |
| `PR is merged` / `PR is closed` | Stop, unwatch, and report who closed it. |
| `draft` | Mark it ready (`gh pr ready <pr>`). The user asked for a real PR. |
| exit 2 (read error) | Run `gh api rate_limit` once. If a quota is spent, wait until its reset (`ScheduleWakeup` in Claude Code) and then re-arm. Otherwise report the error. |

When T3 Code says it "stopped watching" a PR, that is the same case as exit 2: check the rate limit once, then run step 1 and re-arm.

## Watching rules

The watchers above already handle polling cadence, error backoff, empty check lists on a fresh push, and the head SHA. Use them as they are:

- One watcher per PR, owned by the parent thread. A subagent hands its PR back to the parent to watch.
- Status reads go through `pr_status.py`, `gh pr view`, or `gh pr checks` (GraphQL). The REST-backed commands (`gh run view`, `gh run watch`, `gh api repos/...`) are for one-off reads like a failed log, never for waiting.
- When the same check fails three rounds in a row after fixes, or a fix needs a product decision, stop and ask the user with the failing output.
