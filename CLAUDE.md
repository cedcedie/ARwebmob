# Working conventions for this repo

Read this before starting any work here — it exists because branch/folder
drift already happened once (2026-08-30 cleanup) and cost real time to
untangle. Follow it so the same thing doesn't happen again.

## Branch strategy

- **`main` is not where development happens.** It only ever held early
  docs/specs before Phase 1 started. Do not commit implementation work,
  plan files, or spec edits to `main` — it will silently diverge from the
  real branch and someone has to reconcile it later.
- **The active development branch is `worktree-phase1-scaffold-core-auth`**,
  checked out at `.claude/worktrees/phase1-scaffold-core-auth/`. Every
  phase (1 → 2 → 3 → 4 → ...) lives on this one branch, in order, as a
  single linear history — there is no per-phase long-lived branch after
  the phase's own short-lived worktree (see below) merges in.
- **Each phase gets its own short-lived worktree** for the duration of its
  own implementation (e.g. `.claude/worktrees/phase2-student-core-flow`,
  created via `git worktree add`), which merges into
  `worktree-phase1-scaffold-core-auth` when the phase's final review is
  clean, then gets deleted (`git worktree remove`). Don't leave a phase's
  worktree around after it's merged — that's exactly the kind of stale
  clutter that caused the 2026-08-30 cleanup.
- If you ever need to work from `main`'s checkout (repo root, not a
  worktree) for something genuinely main-scoped, merge `main`'s tip into
  `worktree-phase1-scaffold-core-auth` before doing anything else, so the
  two don't drift apart silently.

## Where documentation lives (all on `worktree-phase1-scaffold-core-auth`, not `main`)

- `docs/superpowers/specs/` — the design spec(s). One doc, kept up to date
  with resolved architecture decisions as phases progress. Read this and
  `PROJECT_FLOW.md` (repo root) before writing any new phase's plan.
- `docs/superpowers/plans/YYYY-MM-DD-<phase-name>.md` — one implementation
  plan per phase, written via the `writing-plans` skill (brainstorm first
  for anything architectural). This is the actual task-by-task spec an
  implementer works from.
- `docs/superpowers/sdd/<plan-name>/` — **tracked** build-log for a phase:
  task briefs, task reports, the ledger (`progress.md`). This is optional
  provenance, not required reading — the plan + spec + git history are the
  real source of truth. Phase 4 and Phase 3 have these committed; earlier
  phases don't (their scratch workspace was cleaned up per the skill's
  normal flow — see below). Either is fine; just don't let this content
  end up sitting **uncommitted** in a random working directory, which is
  what happened before the 2026-08-30 cleanup.
- `docs/superpowers/NICE_TO_HAVES.md` — running, cross-phase log of minor
  deferred findings noticed during implementation/review. Append to it,
  don't create a new one.

## The subagent-driven-development scratch workspace

- `.superpowers/sdd/` (note: **no** `docs/` prefix) is **gitignored** —
  it's the live scratch space for an in-progress plan's briefs, reports,
  and review diffs while `subagent-driven-development` is actively running
  a plan. Per that skill's own instructions: **delete a plan's workspace
  folder once its final whole-branch review comes back clean** —
  `rm -rf .superpowers/sdd/<plan-name>/`. Don't let it accumulate stale
  folders from already-completed phases.
- If you want a phase's build-log preserved permanently (like Phase 3/4
  have), commit it to the **tracked** `docs/superpowers/sdd/<plan-name>/`
  path instead — copy it there before deleting the gitignored scratch copy,
  don't leave two versions of the same content in two places.
- Ad-hoc audit/review work that isn't a full plan run (e.g. reviewing work
  someone else did outside this flow) can use `.superpowers/sdd/` too —
  just nest it under a dated folder
  (`.superpowers/sdd/YYYY-MM-DD-<short-name>/`) instead of writing loose
  files at the top level, so it stays scannable.

## A note on line endings

This repo has `core.autocrlf` behavior that makes files show as "modified"
in `git status`/`git diff` purely from CRLF↔LF conversion, with no real
content change. Before treating two copies of a file as genuinely
different, diff them with `--strip-trailing-cr` (or `git diff
--ignore-space-at-eol`) to rule this out — several "different" files during
the 2026-08-30 cleanup turned out to be byte-identical content once line
endings were normalized.
