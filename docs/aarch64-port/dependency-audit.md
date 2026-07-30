# Quattro Dev Package AArch64 Dependency Audit

Audit date: 2026-07-29.

Scope:

- direct `depends` and `makedepends` from
  `pkgbuilds/omarchy-dev/PKGBUILD`
- direct `depends` and `makedepends` from
  `pkgbuilds/omarchy-settings-dev/PKGBUILD`
- build chains for the Omarchy-provided packages required to satisfy missing
  names

The Arch Linux ARM sync databases used for the audit were current on the
capture day for `core` and `extra`. `alarm` was dated 2026-07-25 and `aur` was
dated 2026-05-30. Package metadata was queried with both `expac -S` and
`pacman -Si`; candidate package URLs were resolved with `pacman -Sddp`.
The inherited `asahi-alarm` repository was excluded from conclusions because
this is generic QEMU UEFI hardware.

## Result

| Classification | Result |
| --- | --- |
| Available unchanged | All 21 ordinary runtime/build dependency names |
| Available under another package name | No direct dev-package dependency; kernel mapping is documented below |
| Buildable from `omarchy-pkgs`/AUR | 5 package names |
| x86-only and replaceable | None among hard dependencies |
| x86-only and optional | None among hard dependencies |
| Genuine blocker | None for local package builds |

The published Omarchy repository is still a distribution blocker:
`https://pkgs.omarchy.org/edge/aarch64/omarchy.db` and
`https://pkgs.omarchy.org/stable/aarch64/omarchy.db` both returned HTTP 404.
It is not a blocker for this disposable VM because all missing packages can be
built and installed locally.

## Dependency Matrix

| Consumer | Dependency | Kind | AArch64 evidence | Classification |
| --- | --- | --- | --- | --- |
| `omarchy-dev` | `omarchy-keyring` | runtime | `omarchy-pkgs` local PKGBUILD, `arch=(any)` | Buildable from `omarchy-pkgs`/AUR |
| `omarchy-dev` | `omarchy-settings-dev` | runtime | `omarchy-pkgs` local PKGBUILD, `arch=('any')` | Buildable from `omarchy-pkgs`/AUR |
| `omarchy-dev` | `limine` | runtime | `extra`, 12.5.2-1, `aarch64` | Available unchanged |
| `omarchy-dev` | `limine-mkinitcpio-hook` | runtime | `omarchy-pkgs` AUR-derived PKGBUILD declares `aarch64` and an AArch64 GraalVM source | Buildable from `omarchy-pkgs`/AUR |
| `omarchy-dev` | `limine-snapper-sync` | runtime | `omarchy-pkgs` AUR-derived PKGBUILD declares `aarch64` and an AArch64 GraalVM source | Buildable from `omarchy-pkgs`/AUR |
| `omarchy-dev` | `snapper` | runtime | `extra`, 0.13.1-2, `aarch64` | Available unchanged |
| `omarchy-dev` | `hyprland` | runtime | `extra`, 0.56.1-2, `aarch64` | Available unchanged |
| `omarchy-dev` | `quickshell` | runtime | `extra`, 0.3.0-2, `aarch64` | Available unchanged |
| `omarchy-dev` | `uwsm` | runtime | `extra`, 0.26.6-1, `any` | Available unchanged |
| `omarchy-dev` | `sddm` | runtime | `extra`, 0.21.0-7, `aarch64` | Available unchanged |
| `omarchy-dev` | `xdg-desktop-portal-hyprland` | runtime | `extra`, 1.4.0-1, `aarch64` | Available unchanged |
| `omarchy-dev` | `wireplumber` | runtime | `extra`, 0.5.15-1, `aarch64` | Available unchanged |
| `omarchy-dev` | `pipewire` | runtime | `extra`, 1:1.6.8-1, `aarch64` | Available unchanged |
| `omarchy-dev` | `gnome-keyring` | runtime | `extra`, 1:50.0-1, `aarch64` | Available unchanged |
| `omarchy-dev` | `gum` | runtime | `extra`, 0.17.0-1, `aarch64` | Available unchanged |
| `omarchy-dev` | `jq` | runtime | `extra`, 1.8.2-1, `aarch64` | Available unchanged |
| both | `git` | runtime/build | `extra`, 2.55.0-1, `aarch64` | Available unchanged |
| `omarchy-dev` | `perl` | runtime | `core`, 5.42.2-1, `aarch64` | Available unchanged |
| `omarchy-dev` | `fakeroot` | runtime | `core`, 1:1.37.2-3, `aarch64` | Available unchanged |
| `omarchy-dev` | `pacman-contrib` | runtime | `extra`, 1.13.1-1, `aarch64` | Available unchanged |
| `omarchy-dev` | `ttf-jetbrains-mono-nerd-basic` | runtime | `omarchy-pkgs` local PKGBUILD, `arch=("any")` | Buildable from `omarchy-pkgs`/AUR |
| `omarchy-settings-dev` | `bash` | runtime | `core`, 5.3.15-1, `aarch64` | Available unchanged |
| `omarchy-settings-dev` | `curl` | runtime | `core`, 8.21.0-1, `aarch64` | Available unchanged |
| `omarchy-settings-dev` | `gum` | runtime | `extra`, 0.17.0-1, `aarch64` | Available unchanged |
| `omarchy-settings-dev` | `hicolor-icon-theme` | runtime | `extra`, 0.18-1, `any` | Available unchanged |
| `omarchy-settings-dev` | `plymouth` | runtime | `extra`, 26.134.222-2, `aarch64` | Available unchanged |
| `omarchy-settings-dev` | `imagemagick` | build | `extra`, 7.1.2.29-1, `aarch64` | Available unchanged |

## Quickshell Selection

Arch Linux ARM now publishes `quickshell 0.3.0-2`, so the literal hard
dependency is available unchanged. This milestone will nevertheless build
`quickshell-git` from `omarchy-pkgs`, which declares
`provides=("quickshell")`, `conflicts=("quickshell")`, and
`arch=(x86_64 aarch64)`.

The Omarchy package pins commit
`10b439fc6e3fd65c15fe1c486271b31da05ed023` and carries two fixes required by
the Quattro shell:

- clear crash-relaunch environment variables
- safely deregister IPC handlers during QML teardown/reload

Every runtime and build dependency of that PKGBUILD resolves from Arch Linux
ARM `core` or `extra` as `aarch64` or `any`.

## Kernel Package Mapping

The kernel is not a direct hard dependency of either dev package, but the
installer and hardware helpers use the generic Arch names. On this Arch Linux
ARM system:

| Generic Arch package | Arch Linux ARM package | Evidence |
| --- | --- | --- |
| `linux` | `linux-aarch64` | 7.1.5-2, provides `linux=7.1.5`, conflicts with `linux` |
| `linux-headers` | `linux-aarch64-headers` | 7.1.5-2, provides `linux-headers=7.1.5`, conflicts with `linux-headers` |

The headers package is available but not installed. Neither package needs to
be installed or changed to build the architecture-independent Omarchy dev
packages or Quickshell.

## Current Guest Resolution

Before local builds, `pacman -T` reported these missing dependency names:

```text
omarchy-keyring
omarchy-settings-dev
limine-snapper-sync
quickshell
pacman-contrib
ttf-jetbrains-mono-nerd-basic
```

`limine-mkinitcpio-hook 1.37.1-1` is already installed from the prior ARM
experiment and matches the current `omarchy-pkgs` version. All other ordinary
hard dependencies are already installed except `pacman-contrib`, which is
available unchanged from Arch Linux ARM `extra`.

The build set for the milestone is therefore:

1. `omarchy-keyring`
2. `omarchy-settings-dev`
3. `limine-snapper-sync`
4. `ttf-jetbrains-mono-nerd-basic`
5. `quickshell-git`
6. `omarchy-dev`

`limine-mkinitcpio-hook` will be rebuilt only if package inspection finds that
the installed artifact is insufficient or differs materially from the pinned
PKGBUILD.
