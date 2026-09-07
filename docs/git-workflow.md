# Git workflows for this workstation

Checked against upstream documentation on 2026-09-07. No repositories have been
converted to GitButler and no worktrees have been created.

## Worktrees without clutter

Keep the normal checkout where it is and put occasional extra checkouts beneath
one hidden directory:

```
~/Developer/personal/cadence
~/Developer/.worktrees/cadence/bugfix
~/Developer/.worktrees/cadence/review
```

Git accepts arbitrary worktree paths. These checkouts share the Git object
database, but have separate working files and indexes. Use `git worktree remove`
when finished; ordinary directory deletion leaves administrative records until
they are pruned. The project launcher excludes hidden directories by default.

Benefits: independent files and branches, clean review checkouts, simultaneous
builds of incompatible versions, and isolated changes for competing experiments.
Costs: separate dependency installations/build outputs, more disk usage, ports
and databases still need explicit separation, and a branch ordinarily cannot be
checked out twice. A worktree is not a security sandbox. Build caches and local
secrets are not automatically copied into each checkout.

Source: https://git-scm.com/docs/git-worktree

## GitButler

GitButler fits a preference for one working directory: parallel branches are
applied together, with changes allocated to separate lanes and commits. It also
supports stacked branches and editing commits. This can be especially convenient
when a feature uncovers an unrelated fix, or several small changes share one
development server.

The tradeoff is shared state. Tests run against the combined applied changes;
passing them does not prove each branch works independently. Agents can still
overwrite the same file, generated output, dependencies, or database state.
Separate worktrees remain useful for incompatible experiments.

GitButler maintains a `gitbutler/workspace` branch and protection hooks. Use its
GUI or `but` CLI for commits and branch mutations while it manages a repository.
Uncoordinated writes from lazygit, VS Code, GitHub Desktop, or agent Git commands
can conflict with that model. `but teardown` returns to normal Git operation.

Recommendation: trial GitButler on one personal repository when its working
state is ready, before making it the default client. Keep lazygit available for
ordinary repositories. The existing OMP rule requiring Git actions through
`gh`/`glab` would need an explicit GitButler exception before agent integration.

Sources:
- https://docs.gitbutler.com/features/branch-management/virtual-branches
- https://docs.gitbutler.com/workspace-branch
- https://docs.gitbutler.com/ai-agents/parallel-agents

## Other applications

The most plausible next additions are GitButler for a trial, and a database GUI
such as DBeaver if inspecting PostgreSQL becomes frequent. Keep additions tied
to a recurring task; this workstation already has extensive terminal, editor,
launcher, and agent coverage. Docker Desktop, xcodes, and the 1Password CLI are
the additions implemented in this change.
