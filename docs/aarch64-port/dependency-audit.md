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
| Buildable from `omarchy-pkgs`/AUR | 6 package names, including the transitive Gradle build tool |
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
| Limine helper packages | `gradle` | build | Missing from Arch Linux ARM; official Arch packaging is `any` and was locally constrained to `aarch64` in `omarchy-pkgs` | Buildable from `omarchy-pkgs`/AUR |

## Gradle Build-Tool Gap

The direct runtime matrix has no blocker, but the first clean-container build
found one transitive omission: Arch Linux ARM does not publish `gradle`.
Both `limine-mkinitcpio-hook` and `limine-snapper-sync` declare it as a build
dependency.

The AUR `gradle` recipe is not usable: its pinned state is version 2.6. The
current official Arch packaging repository was therefore cloned and pinned at
commit `65fdb1b6b29b8966bb340a2c919e131cded3b53a`. Its architecture-independent
9.6.1 recipe was added to `omarchy-pkgs` as an AArch64-only local package, so
x86_64 builds continue using the official Arch repository package.

The clean AArch64 container resolved all of Gradle's build requirements from
Arch Linux ARM, including JDK 11, JDK 17, JDK 21, Groovy, AsciiDoc, and XML
tools. Gradle completed 3,342 source-build tasks natively and then built both
Limine helper packages as AArch64 GraalVM native images. This closes the
transitive package-build gap; it is not a desktop runtime dependency.

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

The final local build set for the milestone is:

1. `gradle` 9.6.1-1.1, used only inside the build container
2. `omarchy-keyring`
3. `omarchy-settings-dev`
4. `limine-mkinitcpio-hook`
5. `limine-snapper-sync`
6. `ttf-jetbrains-mono-nerd-basic`
7. `quickshell-git`
8. `omarchy-dev`

The two Omarchy dev packages were built from local source SHA
`4f61400b949bf0d0ee9375cce38ababe95b4f7a8`, rather than the moving upstream
branch tip. The resulting version is `4.0.0.r1466.g4f61400-1`.

Package inspection confirmed that Quickshell and both Limine native images are
ELF64 little-endian AArch64 PIE executables. A dry `pacman -U` transaction
resolved the remaining runtime packages from Arch Linux ARM:

```text
libdwarf 1:2.3.2-1
cpptrace 1.0.4-2
vulkan-headers 1:1.4.350.1-1
pacman-contrib 1.13.1-1
```

## Existing-Host Base-Set Differences

`omarchy-dev` intentionally declares only desktop-breaking hard dependencies;
the ISO installs the larger default set from `install/omarchy-base.packages`.
Two non-hard utilities needed by acceptance were absent from the 3.x host:

| Package | Quattro use | AArch64 result |
| --- | --- | --- |
| `inotify-tools` | third-party plugin hot-reload watcher | `extra/aarch64`, installed unchanged |
| `wtype` | keyboard-driven desktop acceptance | `extra/aarch64`, installed unchanged |

At the initial desktop milestone, the host still used `iwd` and
`systemd-networkd`, while the Quattro default set uses NetworkManager. Both
NetworkManager and the BlueZ packages were available unchanged for AArch64,
but they were not installed or enabled because switching a working network
stack was not required to launch the desktop. That historical difference
produced expected network-backend warnings in the first Quickshell log; it was
an existing-host integration difference, not an architecture or package-build
blocker.

## Quattro Base Manifest Follow-Up

The Phase 2 provider-aware audit checked all 143 non-comment entries in
`install/omarchy-base.packages` with one `pacman -T` transaction. Installed
packages and `provides` entries satisfied 122 names. The remaining 21 are:

| Package | Current AArch64 evidence | Classification |
| --- | --- | --- |
| `asdcontrol` | Clean native build produced an AArch64 ELF; this UTM VM has no USB Apple display | Buildable from `omarchy-pkgs`; optional here |
| `bluez-utils` | `extra`, 5.87-2, `aarch64` | Available unchanged |
| `cliamp` | Clean native build produced an AArch64 ELF | Buildable from `omarchy-pkgs` |
| `dotnet-runtime` | Local `dotnet-sdk-bin 10.0.10.sdk302-1` packages Microsoft's official ARM64 SDK and provides the host/runtime/targeting names; installed and verified | Buildable from `omarchy-pkgs` under a provider package |
| `dua-cli` | `extra`, 2.39.0-1, `aarch64` | Available unchanged |
| `foot` | `extra`, 1.27.0-1, `aarch64` | Available unchanged |
| `gpu-screen-recorder` | `extra`, 5.15.3-1, `aarch64` | Available unchanged |
| `hyprland-preview-share-picker` | Clean native Rust build produced an AArch64 ELF | Buildable from `omarchy-pkgs` |
| `networkmanager` | `extra`, 1.58.0-1, `aarch64`; installed and live-tested | Available unchanged |
| `lua51` | `extra`, 5.1.5-13, `aarch64` | Available unchanged |
| `moonlight-qt` | `extra`, 6.1.0-6, `aarch64` | Available unchanged |
| `mpv-mpris` | `extra`, 1.2-1, `aarch64` | Available unchanged |
| `obs-studio` | Local `32.2.1-2` native build passed Wayland, direct VirGL, PipeWire capture/audio, WebSocket, encoder, and visual checks | Buildable from `omarchy-pkgs`; browser plugin optional and omitted |
| `obsidian` | Local `obsidian-appimage 1.12.7-2` packages the official ARM64 AppImage, provides `obsidian`, and passed GPU/visual checks | Buildable from `omarchy-pkgs` using the upstream ARM64 distribution |
| `omacut` | Clean native Qt build produced an AArch64 ELF | Buildable from `omarchy-pkgs` |
| `omawrite` | Clean native Qt build produced an AArch64 ELF | Buildable from `omarchy-pkgs` |
| `pinta` | Local `3.1.2-2` selects `linux-arm64`, uses the local .NET provider, and passed package and visual checks | Buildable from `omarchy-pkgs` |
| `qemu-user-static-binfmt` | `omarchy-pkg-base-list` maps only AArch64 to signed `qemu-user-binfmt 11.0.2-4`; installed handlers are registered | Available under another package name through an architecture substitution |
| `tensaku` | Clean native Rust/GTK build produced an AArch64 ELF | Buildable from `omarchy-pkgs` |
| `tobi-try` | Clean native build packaged the architecture-independent Ruby application | Buildable from `omarchy-pkgs` |
| `yt-dlp` | `extra`, 2025.12.08-2, `any` | Available unchanged |

There is no blocker for the Hyprland/Quickshell desktop, NetworkManager
transition, or architecture-resolved default package set. All 143 base
manifest entries now satisfy `pacman -T` on this AArch64 VM. The ISO has not
been built; installer integration and any requirement for static user-mode
emulation remain later ISO-phase questions.

The NetworkManager transition and visual panel proof are recorded in
[`phase2-networkmanager-2026-07-30.md`](phase2-networkmanager-2026-07-30.md).

## Phase 3 Native Build Proof

The Phase 3 clone built seven Omarchy base-manifest packages in a clean ARM64
Docker builder:

```text
asdcontrol                       1:0.6.0-1
cliamp                           1.62.0-1
hyprland-preview-share-picker    0.2.1-1
omacut                           0.2.0-1
omawrite                         0.4.0-1
tensaku                          0.26.6-1
tobi-try                         1.9.3-1
```

`file` and `readelf` identified the compiled payloads as ELF64 little-endian
AArch64 executables. `tobi-try` is a Ruby application. Package contents,
install scriptlets, dependencies, and dry pacman transactions were inspected
before any system-wide installation.

The only source changes required for this batch were architecture declarations
for the three native-source recipes that had been constrained to x86_64.
Those changes are pushed in package-repository commit `74775e1`.

## Phase 7 Fresh-Image Closure

The ISO package-only audit expanded the scope from direct dev-package and
base-manifest dependencies to every package requested by a fresh Quattro
image:

| Classification | Count |
| --- | ---: |
| Unique fresh-image package targets | 283 |
| Available unchanged from Arch Linux ARM | 254 |
| Local/provider runtime targets | 29 |
| Build-only local recipes | 1 |
| Genuine blockers | 0 |

The local build map supplies these runtime targets:

```text
aether asdcontrol cliamp dotnet-runtime
hyprland-preview-share-picker limine-mkinitcpio-hook limine-snapper-sync
localsend mise obs-studio obsidian omacut omarchy-dev omarchy-keyring
omarchy-nvim omarchy-settings-dev omawrite pinta
python-terminaltexteffects quickshell-git tensaku tobi-try ttf-ia-writer
ttf-jetbrains-mono-nerd-basic tzupdate ufw-docker xdg-terminal-exec
yaru-icon-theme yay
```

Gradle is the sole build-only recipe. It is cached for the Limine helper
builds and excluded from the runtime repository.

The final package-only run built all mapped recipes and produced a
1,121-package offline repository. A complete target transaction resolved to
928 installed packages. Parsing the repository database proved that all 29
runtime targets are satisfied by an exact name or `provides` entry. Inspection
of all 37 local runtime archives found only `aarch64` and `any` packages.

This closes the local-source package dependency blocker. The published
Omarchy AArch64 repository still returns HTTP 404 and remains a production
publishing requirement, but the first development ISO can now use the
validated local closure.
