# Quattro AArch64 Desktop Validation

Validated on the existing Archboot AArch64 UTM guest on 2026-07-29. The
Quattro shell is running from the locally built packages while the active
Hyprland process remains the known-good session that was already running.

The next-login Lua/UWSM cutover prepared on 2026-07-30 is recorded in
[`persistent-cutover-2026-07-30.md`](persistent-cutover-2026-07-30.md).

## Outcome

The first desktop milestone passed:

- native AArch64 Quickshell starts and remains healthy under UWSM
- shell IPC returns `ok`
- all 34 first-party plugins are registered; 27 are enabled by the default
  shell configuration
- Quickshell exclusively owns the background, bar, notification server, and
  polkit agent after the legacy Waybar, Mako, swaybg, Walker, and polkit agent
  were stopped
- the root and Apps menus open, accept keyboard input, and launch Alacritty
- workspaces switch and restore through Hyprland IPC
- VirGL remains active on the Apple M4 Pro with direct rendering
- PipeWire playback and guest clipboard round-trip pass, and both SPICE agent
  processes remain healthy
- the packaged Quattro Lua Hyprland configuration reports `config ok` in an
  isolated verification home

No Omarchy source architecture check or runtime substitution was needed for
this milestone. The only package-source change is the AArch64 Gradle bootstrap
recipe committed in `omarchy-pkgs` as `c2a36d3`.

## Installed Packages

The locally built runtime packages installed on the guest are:

```text
omarchy-keyring                 20251027-1
omarchy-settings-dev            4.0.0.r1466.g4f61400-1
omarchy-dev                     4.0.0.r1466.g4f61400-1
limine-snapper-sync             1.31.0-1
quickshell-git                  0.3.0.r18.g10b439f-3
ttf-jetbrains-mono-nerd-basic   3.4.0-1
```

The transaction resolved these additional signed Arch Linux ARM packages:

```text
libdwarf
cpptrace
vulkan-headers
pacman-contrib
```

`limine-mkinitcpio-hook 1.37.1-1` was already installed at the exact locally
built version, so it was not reinstalled. The full Nerd Font package was
replaced by the Quattro basic package. `inotify-tools` and `wtype`, both
present in `install/omarchy-base.packages`, were installed afterward from
`extra/aarch64` to exercise plugin watching and keyboard acceptance.

`pacman -Qk` reports no missing files for the installed runtime packages. A
normal-user check cannot stat the three mode-restricted files under
`/etc/sudoers.d`, so it reports three permission-denied false positives for
`omarchy-settings-dev`.

Local artifact SHA-256 checksums:

```text
a5b8cc519d1ab9eef67212f3d9338de5bc2a4b404207176ebb8ef915e994452c  gradle-9.6.1-1.1-aarch64.pkg.tar.xz
a702340de125434c0609d1bee53513af28aaaffdadf30159eb98c2959f811026  limine-mkinitcpio-hook-1.37.1-1-aarch64.pkg.tar.xz
1defb8876807bd10a81fab175a4c4f0758413e7a0ff5ca5fc329abfa2a6ba3ed  limine-snapper-sync-1.31.0-1-aarch64.pkg.tar.xz
b29dcc45427fe52ec4b345ac4a46a0907a26f05356576a5e8b4eed46e5236c2b  omarchy-dev-4.0.0.r1466.g4f61400-1-any.pkg.tar.xz
2c990bc86564045fb7192e0195c6f86640f2f537edb4f25de7a4aecd2cdb3145  omarchy-keyring-20251027-1-any.pkg.tar.xz
91db864c7b9a8c46035f496edc2e5bc9f2b9a2f4a6a9704ac6ac51279c03142a  omarchy-settings-dev-4.0.0.r1466.g4f61400-1-any.pkg.tar.xz
8fc550c025f6f73aec7c41a859fd5828437545da78956f1e64788aff26ef5eb0  quickshell-git-0.3.0.r18.g10b439f-3-aarch64.pkg.tar.xz
bb8fec888fb1e89195bb14da6242860cf8b02c4e9fb31db0c9294acb6ddb0f69  ttf-jetbrains-mono-nerd-basic-3.4.0-1-any.pkg.tar.xz
```

## Guarded Installation

Before installation, system files affected by the package scriptlet and every
legacy unowned file that overlapped the package were backed up under:

```text
/home/jj/Projects/omarchy-pkgs-quattro-arm64/build-output/pre-install-system-2026-07-29
```

User state relevant to finalization was archived at:

```text
/home/jj/Projects/omarchy-pkgs-quattro-arm64/build-output/pre-finalize-user-2026-07-29.tar
```

The first dry installation stopped on 13 unowned files from the 3.x install.
The Plymouth assets, session desktop entry, and sleep helper were byte-for-byte
identical to the package payload. The final transaction used `--overwrite`
only for those 13 exact paths; no broad overwrite pattern was used.

Three package-owned defaults were preserved as `.pacnew` files:

```text
/etc/mkinitcpio.conf.d/omarchy_hooks.conf.pacnew
/etc/sysctl.d/90-omarchy-file-watchers.conf.pacnew
/etc/systemd/resolved.conf.d/10-disable-multicast.conf.pacnew
```

They were deliberately not merged. In particular, the mkinitcpio drop-in was
left untouched to preserve the boot/initramfs guardrail.

## Boot and Kernel Integrity

The kernel, Limine, mkinitcpio, preset, and initramfs remain unchanged:

```text
linux-aarch64             7.1.5-2
limine                    12.5.2-1
limine-mkinitcpio-hook    1.37.1-1
mkinitcpio                41-4
```

Post-install hashes exactly match the pre-install baseline:

```text
2662962bab816958bad80f3c24e275f2e306b984bdf1f81dc235342382c8048f  /boot/initramfs-linux.img
add658562939b9abb73bf6fe7865fb177cd8fbfa5a73479467cf3469da57ac44  /boot/limine.conf
6edf91b6ee62aff521de9666d6f8c790be086ecec48352f2dd580d66a6831dd3  /etc/mkinitcpio.conf
a0bf23d62d7d74bfa597e38af7cc841837ba4a353ed8f8b10b5dd3a69dab5814  /etc/mkinitcpio.d/linux-aarch64.preset
```

`linux-aarch64-headers` remains available but uninstalled. No partition,
filesystem, UEFI entry, kernel, bootloader, or initramfs command was run.

## Finalization

User finalization was run against the packaged Quattro tree:

```bash
env OMARCHY_PATH=/usr/share/omarchy \
  OMARCHY_INSTALL=/usr/share/omarchy/install \
  OMARCHY_SETUP_CONTEXT=runtime \
  PATH=/usr/bin:/bin \
  /usr/bin/omarchy-finalize-user --force
```

It completed successfully and wrote
`~/.local/state/omarchy/done/finalize-user`. The Omarchy skill symlink now
targets `/usr/share/omarchy/default/omarchy-skill`.

`omarchy-reinstall-configs` and `omarchy-upgrade-to-quattro` were not run.
Those commands perform broader configuration or boot-related work than this
milestone allows.

## Session Launch and Legacy PATH Finding

The packaged shell is launched for validation as a managed UWSM user service:

```bash
uwsm-app -s b -t service \
  -u omarchy-quattro-shell-runtime.service \
  -d "Quattro shell ARM64 runtime validation" \
  -p "Environment=OMARCHY_PATH=/usr/share/omarchy" \
  -p "Environment=PATH=/usr/bin:/bin" \
  -- quickshell -n -p /usr/share/omarchy/shell
```

The explicit `PATH` is necessary only because the already-running 3.x UWSM
manager still exports `~/.local/share/omarchy/bin` before `/usr/bin`. Without
the override, Quattro's Indicators widget resolves the legacy
`omarchy-voxtype-status`. When `voxtype` is absent, that old script runs its
`trap 'kill 0' EXIT` and sends `SIGTERM` to the Quickshell process group.

GDB confirmed the external `SIGTERM`; Quickshell did not crash. Launching with
the packaged path resolves `/usr/bin/omarchy-voxtype-status`, whose Quattro
implementation does not contain that process-group trap. The shell then
remains active and healthy. A fresh Quattro login will receive the packaged
environment instead of this mixed 3.x/4.x state.

## Validation Matrix

| Check | Evidence | Result |
| --- | --- | --- |
| Quickshell process | Managed service active; native `/usr/bin/quickshell`; IPC `shell ping` returns `ok` | Pass |
| Plugin registry | 34 first-party plugins, 27 enabled; `inotifywait` watches `~/.config/omarchy/plugins` | Pass |
| Shell layers | Only `omarchy-background` and `omarchy-bar` remain after legacy surfaces stop | Pass |
| Notifications | `org.freedesktop.Notifications` owner is Quickshell; test toast rendered correctly | Pass |
| Menu | Root and Apps routes rendered without clipping; typed `Alacritty` reduced the Apps list to one row | Pass |
| Terminal | `wtype -k Return` launched a second native Alacritty client on workspace 2 | Pass |
| Workspaces | Hyprland IPC changed workspace 2 to 3 and restored 2 | Pass |
| Quattro Hyprland config | `Hyprland --verify-config` against an isolated copy of shipped Lua config returned `config ok` | Pass |
| Active Hyprland config | `hyprctl configerrors` is empty | Pass |
| Graphics | `virgl (Apple M4 Pro)`, Mesa 26.1.5, OpenGL 4.1, direct rendering `Yes` | Pass |
| Software fallback | No `LIBGL_ALWAYS_SOFTWARE`, `GALLIUM_DRIVER`, `MESA_LOADER_DRIVER_OVERRIDE`, `WLR_RENDERER`, or `AQ_*RENDERER` override | Pass |
| Audio | PipeWire sink/source present; 48 kHz stereo test stream wrote both channels for the requested test interval | Pass |
| Clipboard | `wl-copy`/`wl-paste` token round-trip succeeded and the prior text selection was restored | Pass |
| SPICE integration | User and system `spice-vdagent` processes remain active; `Virtual-1` is healthy at 1280x800 | Runtime intact; a host-driven UTM resize was not re-exercised from inside the guest |
| Session health | No failed user units | Pass |
| Visual review | Background, bar, menus, notification, empty desktop, and terminal screenshots inspected at 1280x800 | Pass |

Visual evidence:

```text
~/Pictures/screenshot-2026-07-29_23-26-22.png  shell and bar
~/Pictures/screenshot-2026-07-29_23-26-33.png  root menu
~/Pictures/screenshot-2026-07-29_23-26-52.png  Apps menu
~/Pictures/screenshot-2026-07-29_23-28-08.png  empty Quattro desktop
~/Pictures/screenshot-2026-07-29_23-29-07.png  terminal
~/Pictures/screenshot-2026-07-29_23-30-22.png  Quickshell notification
~/Pictures/screenshot-2026-07-29_23-31-09.png  typed Apps filter
```

## Remaining Boundaries

- The active compositor still reads the known-good 3.x
  `~/.config/hypr/hyprland.conf`. The shipped Quattro Lua tree is verified, but
  the user-config cutover and a fresh login were not performed because that is
  a broader live-config reset. This does not prevent the Quattro shell desktop
  from running for the first milestone.
- The existing host uses `iwd`; Quattro's default package set uses
  NetworkManager. Quickshell therefore logs that no supported network backend
  is available. Switching the working network stack was not needed for this
  milestone and was intentionally deferred.
- A host-driven UTM window resize cannot be initiated from the guest. Both
  SPICE agent processes and the dynamic virtual output remain healthy, but a
  manual resize is the one acceptance action not repeated in this run.
- The guest has no Bluetooth service/hardware, so the BlueZ object-manager
  warning is expected.
- Claude model-usage warnings only report that no Claude credentials/history
  exist for this user.
- The published Omarchy `edge/aarch64` and `stable/aarch64` databases remain
  HTTP 404. Local packages close the VM milestone, but the missing published
  repository is still a distribution blocker.
