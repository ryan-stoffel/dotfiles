Hello, my name is Ryan Thomas Stoffel, please refer to me as Ryan.

You are my agent.

We will be working together a lot, so I thought it would be worth introducting myself.

I am a senior Computer Science Student at California Baptist University (CBU). I am an aspiring software engineer, and I love working on backend systems, systems engineering projects, applied AI projects, and building real software that improves mine and other peoples life. I focus on building complex things as simple as possible. I love to find ways to reduce complexity when solving problems.

I want to share some of my preferences here so we can be more aligned as we work together.

# **Coding Preferences - General:**

- Keep things **simple**. Channel "yagni" energy unless told otherwise.
- Typesafety is useful, take **advantage** of it.
- Be **careful** with destructive actions that are not explicity requested by the user.
- Tests are **good**! Endless smoke tests, "regression tests" for feature deletions, etc, much **less** good. Tests should be focused, not **slop**.
- Comments are a good way to clarify functionallity and how code is used. **Don't** comment every line, but feel free to describe (**concisely**) how functions are used above function definitions, classes, etc.
- Keep comments **up to date!** When making changes, it's important to keep things in sync.

# Questions are read-only

- A question is a request for an **answer**, not for changes. If the message opens with "how hard would it be", "what are your thoughts", "why does", "should we", "is it possible", "can X do Y", or otherwise **asks** rather than **instructs**: answer it, and **do not** edit files.
- If the answer is obvious and the change is trivial, **still** answer first and **offer** the change. **Ask** before making it.

# Match ceremony to the task

- **Do not** spawn subagents or a multi-agent panel for work a single agent finishes in **one pass**. Delegation is for **breadth** or **adversarial review**, not for ordinary tasks.
- When several agents do work in parallel, state **file ownership** up front so they do not **collide**.

# Blast radius

- **Never** touch **production**, **live databases**, or **daily-driver** build/preview channels unless **explicitly** told to. When a task is adjacent to any of them, **name** what you are about to touch **before** touching it.

# Pull Requests

- Make sure titles follow **conventions** from the repo. They should be **simple** and easy to understand. Conventional commit styles in projects that use them, i.e. "fix(web): new threads no longer spike CPU"
- PR descriptions must be **human readable**. A person should understand the whole PR in **under a minute**, without reading the diff.
- Every PR description states two things and little else: the **PROBLEM** (or the **cause** for the PR), then the **FIX** (the **solution**). Problem first, fix second.
- Keep it **short** and **plain**. No walls of text, no bullet dumps of every file changed, no restating the diff, no filler sections. If a sentence does not explain the **problem** or the **fix**, **delete** it.
- Add a blurb to the **end** of the PR description about what **model** and **harness** is making the changes.
- Open a **real** PR, **not a draft**. Drafts do not get review-bot coverage.
- **Rebase** onto latest `main` **before** opening. Stale branches conflict and waste a review round.
- When asked to **monitor** or babysit a PR: poll checks and comments **newer** than the last push; **verify** each bot finding against the source before acting on it; fix **real** ones and dismiss **false positives** with a written reason; fix CI failures, distinguishing **real breaks** from known **infra flakes**. If nothing is new, **stay quiet** — do not post filler comments.
