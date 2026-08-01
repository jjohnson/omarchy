# Quattro AArch64 Repository State

Upstream state recorded on 2026-07-29 before dependency auditing or source
changes.

| Repository | Worktree | Upstream branch | Recorded upstream SHA | Development branch |
| --- | --- | --- | --- | --- |
| `basecamp/omarchy` | `~/Projects/omarchy-quattro-arm64` | `quattro` | `559ab04209e35eaac714cdd1f32701ae5f56c5de` | `quattro-aarch64-utm` |
| `omacom-io/omarchy-pkgs` | `~/Projects/omarchy-pkgs-quattro-arm64` | `master` | `0a80091fe638ff13e894a4c1c4a88f4a460207ea` | `quattro-aarch64-utm` |
| `omacom-io/omarchy-iso` | `~/Projects/omarchy-iso-quattro-arm64` | `quattro` | `a76f599eaae524d9fb9e135473320e4e66696cb7` | `quattro-aarch64-utm` |

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

The package repository development branch now contains these pushed atomic
commits:

- `c2a36d3` (`Build Gradle for aarch64`) adds the official Arch Gradle 9.6.1
  packaging recipe, pinned to Arch packaging commit
  `65fdb1b6b29b8966bb340a2c919e131cded3b53a`, and constrains the locally
  rebuilt package to AArch64.
- `74775e1` (`Add aarch64 support for native utilities`) declares AArch64 for
  `asdcontrol`, `hyprland-preview-share-picker`, and `tensaku` after all three
  completed clean native builds.
- `752d420` (`Update tobi-try to 1.9.3`) pins the current upstream 1.9.3
  payload after the package transaction exposed an older recipe.
- `23d81b0` (`Conflict share picker with git variant`) allows the stable
  package to replace the legacy `-git` package transactionally.
- `f49bdf2` (`Add AArch64 .NET SDK package`) packages Microsoft's official
  ARM64 SDK and provides the .NET host/runtime/targeting names.
- `d95da3e` (`Build Pinta on aarch64`) selects the ARM64 runtime identifier
  and updates the vulnerable D-Bus dependency.
- `8ed9c0d` (`Package Obsidian for aarch64`) packages the official upstream
  ARM64 AppImage.
- `9468558` (`Normalize Obsidian icon permissions`) corrects extracted icon
  directory modes.
- `8f6bc12` (`Build OBS Studio on aarch64`) adds the native source build
  without the optional browser plugin.
- `d0f3fdc` (`Use native mbedTLS for ARM OBS`) replaces the broken Arch Linux
  ARM `mbedtls3` layout with the working native `mbedtls` package.

Phase 7 added two more pushed package-repository commits:

- `5ba1876` (`Add ARM64 package providers`) adds the pinned `mise-bin` recipe
  and makes the `tzupdate` ARM source fix persistent.
- `7f7cbb0` (`Bootstrap ARM builds without published repo`) prevents the ARM
  package-builder bootstrap from depending on the missing published Omarchy
  repository.

The current package-repository branch tip is
`7f7cbb0f10c50ab60b801e283f778727bf55f229` and is pushed to the personal
origin.

The Omarchy branch contains source checkpoint
`8eb138c19fddb1c42b020047052e6c9674e135a9`, which adds the tested
architecture-aware base-package resolver. It is pushed to the personal
origin.

The Phase 7 package closure used Omarchy source commit
`b08e94784c50616b15ad55a861e01d0af7e00d2f`.

The ISO branch now contains the complete package-only AArch64 closure builder,
its retry-safe cache fixes, and the updated architecture plan. Its pushed tip
is:

```text
ac984c1d06bc39dc7aebaaa8c0b9f1641ccc6141
```
