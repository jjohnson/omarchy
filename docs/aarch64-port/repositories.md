# Quattro AArch64 Repository State

Upstream state recorded on 2026-07-29 before dependency auditing or source
changes.

| Repository | Worktree | Upstream branch | Recorded upstream SHA | Development branch |
| --- | --- | --- | --- | --- |
| `basecamp/omarchy` | `/home/jj/Projects/omarchy-quattro-arm64` | `quattro` | `559ab04209e35eaac714cdd1f32701ae5f56c5de` | `quattro-aarch64-utm` |
| `omacom-io/omarchy-pkgs` | `/home/jj/Projects/omarchy-pkgs-quattro-arm64` | `master` | `0a80091fe638ff13e894a4c1c4a88f4a460207ea` | `quattro-aarch64-utm` |
| `omacom-io/omarchy-iso` | `/home/jj/Projects/omarchy-iso-quattro-arm64` | `quattro` | `a76f599eaae524d9fb9e135473320e4e66696cb7` | `quattro-aarch64-utm` |

The Omarchy worktree uses the developer fork as `origin` and
`https://github.com/basecamp/omarchy.git` as `upstream`. Its local development
branch contains the baseline documentation commit on top of the recorded
`upstream/quattro` SHA.

The package and ISO repositories were cloned directly from their canonical
repositories. Their development branches initially point exactly at the
recorded upstream commits.

The Omarchy repository contains a root `AGENTS.md`, which was read completely
before editing. Neither the package repository nor the ISO repository contains
an `AGENTS.md` at its recorded commit.
