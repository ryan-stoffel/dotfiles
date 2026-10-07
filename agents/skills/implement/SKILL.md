---
name: implement
description: Take a feature or fix from request to a ready-to-merge PR, with screenshots or GIFs in the body. Use when asked to implement or fix something and then file a PR, add images or a GIF, or babysit it until merge.
---

# implement

Goal: one PR that does what was asked, shows it working, and reaches `verdict: READY` from the `babysit-pr` skill. Each step ends on the check named in bold.

## Steps

1. **Understand.** Read the request and every attached image. Read the code the change touches and trace the real flow end to end. For a bug, find the root cause and every caller that routes through it. **Done when you can name the files you will change and why.**

2. **Branch.** Read the repo's `AGENTS.md`, `CONTRIBUTING.md`, and `.github/pull_request_template.md` if present, and `git branch -r` for the branch naming convention. Start from the latest base: `git fetch origin && git switch -c <branch> origin/<base>`. The base is the repo default unless `AGENTS.md` names another. **Done when the branch name matches the repo's pattern.**

3. **Build.** Make the smallest change that fully meets the request, in the repo's style. Add a focused test for any non-trivial logic. **Done when every part of the request is handled.**

4. **Verify.** Run the checks CI runs (find them in `.github/workflows/` or the repo's scripts), plus the new tests. **Done when they all pass locally.**

5. **Show it.** For any visible change, capture the real running app with the change, using the `upload-media-pr` skill for capture, upload, and embedding. Behavior changes get before/after or a GIF of the flow. In T3 Code the `preview_*` tools capture web UIs. Open each image and confirm it shows the change before uploading. For a change with nothing visible, write one line saying so instead. **Done when every image shows the claimed change.**

6. **Commit.** Follow the repo's commit convention and end the message with the co-author trailer your harness specifies. Rebase onto the latest base right before pushing: `git fetch origin && git rebase origin/<base>`, then rerun step 4 if the rebase brought in changes. **Done when the branch is pushed with no commits behind base.**

7. **Open the PR.** Real PR, not a draft. Title in the repo's convention (Conventional Commits where the repo uses them). Body follows the repo template, else:
   - the problem, in one or two plain sentences
   - the fix
   - `## Validation` with the embedded images or GIF
   - how it was tested
   - last line: the model and harness that made the change, for example `Changes made by Claude Opus 5.5 in Claude Code.`

   In T3 Code, call `link_pull_request` with the PR URL. Read the body back with `gh pr view <n> --json body` and confirm each image line starts with `![`. **Done when the PR exists, is linked, and every image renders.**

8. **Babysit.** Run the `babysit-pr` skill on the PR. **Done when it reports `verdict: READY`, or the PR is merged if the user asked for a merge.**

## Report

End with the PR URL, the final `pr_status.py` verdict line, and one line on what changed. Leave out the step-by-step history.
