# Quattro ARM64 Phase 7 Package Closure

Date: 2026-07-30

## Scope

This phase ran in the
`Quattro-ARM64-Phase-7-Package-Closure-Working-2026-07-30` clone. Its only
runtime mutation was the user-owned Docker and ISO package cache. It did not
build or boot an ISO, install packages on the host, run migrations, or alter
the kernel, initramfs, Limine configuration, UEFI entries, partitions, or
filesystems.

The goal was to replace the missing published Omarchy AArch64 repository with
a complete, reproducible local package closure suitable for the first ISO
build.

## Fresh-Image Audit

The complete target package input contains 283 unique names:

```text
resolved unchanged by Arch Linux ARM: 254
local/provider runtime targets:        29
genuine blockers:                       0
```

The local map contains 30 recipes. Gradle is a build-only prerequisite for the
two Limine helper packages; the other 29 rows satisfy fresh-image runtime
targets.

Three targets use provider packages:

| Fresh-image target | AArch64 package |
| --- | --- |
| `dotnet-runtime` | `dotnet-sdk-bin` |
| `mise` | `mise-bin` |
| `obsidian` | `obsidian-appimage` |

The package repository gained a pinned AArch64 `mise-bin` recipe. `tzupdate`
now applies its existing upstream ARM sync fix persistently, and its package
declares AArch64 support. The package-builder image also skips the nonexistent
published Omarchy repository during ARM bootstrap.

## Package-Only Builder

The ISO source now accepts:

```bash
./bin/omarchy-iso-make --arch aarch64 --packages-only \
  --local-source /home/jj/Projects/omarchy-quattro-arm64 \
  /home/jj/Projects/omarchy-pkgs-quattro-arm64
```

The builder:

- audits the complete fresh-image target list before building;
- builds the exact custom/provider map in dependency order;
- creates a temporary local pacman repository for packages needed by later
  recipes;
- persists Gradle separately as a build-only dependency;
- removes transient build dependencies after each recipe;
- fingerprints recipes and mounted Omarchy source;
- reuses completed runtime artifacts only when their fingerprint matches;
- supports both `.pkg.tar.xz` and `.pkg.tar.zst` package archives;
- stops after repository and target-transaction validation when
  `--packages-only` is selected.

No Gradle archive is copied into the runtime mirror.

## Native Build Result

The complete package-only command exited successfully. Notable native builds
included:

- Gradle 9.6.1, build-only;
- LocalSend 1.17.0;
- both Limine helper native images;
- OBS Studio 32.2.1;
- Pinta 3.1.2 through the local .NET provider;
- Quickshell `0.3.0.r18.g10b439f-3`;
- Tensaku, tzupdate, yay, Yaru, and the remaining local utilities;
- `omarchy-settings-dev` and `omarchy-dev`
  `4.0.0.r1488.gb08e947-1`.

The final local output contains 37 runtime archives because the Yaru recipe
emits nine split packages. Inspection proved that every archive is `aarch64`
or `any`.

The completed offline repository contains:

```text
package archives:        1121
database entries:        1121
repository disk usage:   3.0 GiB
build-only cache:        170 MiB
target install closure:  928 packages
missing mapped targets:  0
bad local architectures: 0
Gradle runtime archives: 0
```

The repository downloaded approximately 2,449 MiB of signed Arch Linux ARM
packages and then indexed those archives together with the 37 local packages.

## Retry Defects Found and Fixed

Long native builds exposed five resumability defects:

1. Gradle's split archives were indexed from a location pacman could not
   access. The builder now stages persistent build-dependency archives beside
   its temporary database.
2. Locale-dependent package-recipe ordering changed fingerprints between the
   host and container. Fingerprint generation now uses `LC_ALL=C`.
3. Rust installed for one recipe conflicted with LocalSend's `rustup`
   toolchain. Local builds now use `makepkg --rmdeps`.
4. A rebuilt same-version .NET archive differed from the stale archive in the
   host pacman cache. Staging now evicts only the exact colliding cache
   filename before repository resolution.
5. Git rejected the root-owned mounted Omarchy source while calculating a
   source-backed fingerprint. The read-only fingerprint command now declares
   that exact mount as a safe directory.

Each fix has focused architecture-test coverage.

## Package Inspection

The offline database resolves all 29 mapped targets, including each provider
name. Package metadata confirms:

- `quickshell-git` is AArch64, provides `quickshell`, and ships the Hyprland,
  Wayland, PipeWire, notification, networking, Bluetooth, and polkit QML
  modules;
- `omarchy-dev` provides `omarchy` and contains all 21 intended hard runtime
  dependencies;
- `omarchy-settings-dev` provides `omarchy-settings` and contains its five
  intended runtime dependencies;
- the two Omarchy packages were built from source commit `b08e947`;
- `dotnet-sdk-bin`, `mise-bin`, and `obsidian-appimage` advertise the exact
  generic target names needed by the install transaction.

`omarchy-nvim` emitted a non-fatal Mason warning while trying to install
`stylua`. Its package completed and contains the full cached plugin tree plus
the native ARM64 `shfmt` Mason tool. The recipe intentionally treats
headless Lazy synchronization as best-effort, and `stylua` is not a package
dependency. This is not an ISO closure blocker, but first-boot Neovim
acceptance should confirm that optional Mason tools can be installed normally.

## Source Checkpoints

All Phase 7 source work is on the dedicated branch and pushed:

```text
omarchy:
  source tip before this report: b08e94784c50616b15ad55a861e01d0af7e00d2f

omarchy-pkgs:
  5ba1876 Add ARM64 package providers
  7f7cbb0 Bootstrap ARM builds without published repo
  tip: 7f7cbb0f10c50ab60b801e283f778727bf55f229

omarchy-iso:
  f9e1a13 Build local AArch64 package closure
  d3dbc90 Persist ARM package build dependencies
  6e26971 Make package fingerprints locale independent
  9b400ec Isolate ARM package build dependencies
  87da845 Reuse completed ARM package builds
  73a0971 Fingerprint mounted Omarchy sources safely
  ac984c1 Document ARM package closure
  tip: ac984c1d06bc39dc7aebaaa8c0b9f1641ccc6141
```

Passing checks:

```text
ISO architecture test
Bash syntax checks
PKGBUILD syntax and .SRCINFO generation for mise-bin and tzupdate
git diff --check in all changed repositories
1,121-entry offline database/archive parity
29/29 mapped target resolution
37/37 local archive architecture and package-metadata inspection
```

## Protected Host Proof

The installed VM remained at:

```text
kernel:             7.1.5-2-aarch64-ARCH
installed packages: 979
explicit packages:  199
foreign packages:   37
orphans:            0
Quickshell IPC:      ok
Hyprland errors:     none
failed units:        zero system and user
network:             connected
renderer:            direct virgl (Apple M4 Pro), OpenGL 4.1
```

The protected hashes are unchanged:

```text
2662962bab816958bad80f3c24e275f2e306b984bdf1f81dc235342382c8048f  /boot/initramfs-linux.img
add658562939b9abb73bf6fe7865fb177cd8fbfa5a73479467cf3469da57ac44  /boot/limine.conf
6edf91b6ee62aff521de9666d6f8c790be086ecec48352f2dd580d66a6831dd3  /etc/mkinitcpio.conf
a0bf23d62d7d74bfa597e38af7cc841837ba4a353ed8f8b10b5dd3a69dab5814  /etc/mkinitcpio.d/linux-aarch64.preset
```

The root filesystem still has 48 GiB available and the VM has approximately
10 GiB of available memory. No ISO exists under `release/`.

## Next Boundary

Phase 7 is complete. Preserve it while powered off as:

```text
Quattro-ARM64-Phase-7-Package-Closure-Complete-2026-07-30
```

Create the next disposable working clone as:

```text
Quattro-ARM64-Phase-8-First-ISO-Build-Working-2026-07-30
```

Phase 8 should use the validated cache to build the first actual AArch64 ISO,
inspect its boot payload and package database, and only then boot it as a
separate installer test VM. The Phase 7 proof host should not be used as the
installation target.
