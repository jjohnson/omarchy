# Quattro ARM64 Phase 4 Legacy Cleanup

Date: 2026-07-30

## Scope and Guardrails

This phase runs in:

```text
Quattro-ARM64-Phase-4-Legacy-Cleanup-Working-2026-07-30
```

It was duplicated from the completed Phase 3 package checkpoint. The gold,
Phase 2, and Phase 3 VMs remain unchanged. This phase may remove packages
retired by Quattro after recording an exact rollback bundle, but it must not
alter partitions, filesystems, the kernel, initramfs, Limine, UEFI entries, or
migration markers.

The Phase 4 boot began at `2026-07-30 04:30:29 EDT`. Before cleanup:

```text
installed packages:  1027
explicit packages:   224
foreign packages:    54
orphans:             0
manifest entries:    143
manifest missing:    0
pending migrations:  46
disk available:      53G
memory available:    9.9Gi
```

Quickshell IPC returned `ok`, Hyprland had no configuration errors,
NetworkManager was connected, audio services were active, and there were zero
failed system or user units. Direct rendering remained
`virgl (Apple M4 Pro)` with OpenGL 4.1.

Protected hashes before package work:

```text
2662962bab816958bad80f3c24e275f2e306b984bdf1f81dc235342382c8048f  /boot/initramfs-linux.img
add658562939b9abb73bf6fe7865fb177cd8fbfa5a73479467cf3469da57ac44  /boot/limine.conf
6edf91b6ee62aff521de9666d6f8c790be086ecec48352f2dd580d66a6831dd3  /etc/mkinitcpio.conf
a0bf23d62d7d74bfa597e38af7cc841837ba4a353ed8f8b10b5dd3a69dab5814  /etc/mkinitcpio.d/linux-aarch64.preset
```

## Retina Display

UTM Retina mode exposed a `3006x1818@60` guest mode while Hyprland retained
scale 1. The user monitor override now selects scale 2 without hard-coding a
physical mode:

```lua
local omarchy_monitor_scale = 2
```

The prior file is preserved at:

```text
~/.config/hypr/monitors.lua.bak.phase4-retina-20260730-043454
```

The host-driven resize acceptance check ended at:

```text
monitor:       Virtual-1
physical mode: 2826x1818@60
scale:         2
logical size:  1413x909
```

The UTM window stayed at the requested size. Hyprland remained error-free and
Quickshell remained responsive. This confirms that the package-owned SPICE
resize helper preserves the explicit scale while continuing to follow the
host's dynamic physical mode.

Visual reference:

```text
~/Pictures/screenshot-2026-07-30_04-35-44.png
```

## Retired-Package Audit

The authoritative list is `remove_retired_default_packages()` in
`bin/omarchy-upgrade-to-quattro`. Candidates were matched by exact installed
package name. Every removal was preceded by reverse-dependency, process,
configuration-reference, package-reason, and pacman transaction checks.

The audit separated the installed retired packages into:

| Classification | Packages |
| --- | --- |
| Replaced Quattro UI | Walker, Elephant providers, Waybar, Mako, swaybg, SwayOSD, old polkit agent |
| Replaced Quattro utilities | Blueberry, Bluetui, Hypridle, Hyprlock, Playerctl, Satty, Wayfreeze, wf-recorder, Wiremix |
| Retained user applications | `claude-code`, `dust`, `localsend-bin`, `opencode` |
| Deferred network rollback | `impala`, `iwd` |

`gnome-bluetooth` was included with Blueberry because nothing else required
it. `greetd` was not a removal candidate: it is the enabled and active login
manager for this working desktop. The boot stack and NetworkManager rollback
assets were also outside the cleanup scope.

The staged bring-up had installed the complete architecture-resolved package
manifest without applying the upgrade command's package-reason normalization.
Six current Quattro base providers were therefore still marked as
dependencies:

```text
bluez
bluez-tools
fakeroot
libsecret
pacman-contrib
wireplumber
```

Their before-state was recorded, then the same packages that
`mark_packages_explicit()` would resolve were marked explicit before either
recursive removal. All six remain installed and explicit. This prevented
retired-package cleanup from accidentally taking current Quattro base
providers with it.

## Batch 1: Replaced Desktop UI

The first exact request contained 19 retired packages:

```text
walker
elephant
elephant-bluetooth
elephant-calc
elephant-clipboard
elephant-desktopapplications
elephant-files
elephant-menus
elephant-providerlist
elephant-runner
elephant-symbols
elephant-todo
elephant-unicode
elephant-websearch
waybar
mako
swaybg
swayosd
polkit-gnome
```

The inspected `pacman -Rns` transaction contained those 19 packages plus 11
dependencies used only by the retired stack:

```text
libmpdclient jsoncpp gtkmm3 pangomm gtk-layer-shell gpsd pps-tools
cairomm atkmm glibmm libsigc++
```

The transaction removed 30 packages and freed 447.07 MiB. The unowned Walker
pacman hook and inactive user configuration directories for Elephant, Mako,
SwayOSD, Walker, and Waybar were moved into the rollback bundle rather than
deleted.

Quickshell's root menu and notification surfaces rendered cleanly afterward:

```text
~/Pictures/screenshot-2026-07-30_04-53-12.png
~/Pictures/screenshot-2026-07-30_04-53-33.png
```

## Batch 2: Replaced Utilities

The second exact request contained:

```text
blueberry
bluetui
gnome-bluetooth
hypridle
hyprlock
playerctl
satty
wayfreeze-git
wf-recorder
wiremix
```

The inspected transaction contained those ten packages plus five dependencies
that no longer had a consumer:

```text
xapp xapp-symbolic-icons libgnomekbd libxklavier python-setproctitle
```

The transaction removed 15 packages and freed 23.31 MiB. The inactive Wiremix
configuration and desktop launcher were moved into the batch rollback
directory. Quattro's screenshot command still worked after the retired
capture packages were gone:

```text
~/Pictures/screenshot-2026-07-30_04-57-53.png
```

The legacy `hypridle.conf` and `hyprlock.conf` files remain in place as
rollback material; no retired service or process consumes them.

## Rollback Material

Every installed package payload, pacman database entry, version, file
manifest, cached official package archive, and relevant user configuration
was captured before removal:

```text
~/.local/state/omarchy/phase4-retired-ui-backup-20260730-044500/
```

The complete directory is approximately 486 MiB. Important archive hashes:

```text
e5e2c9ddb32e23bc2ec6b6e551574279ebee3788e65530361a5ee70aedd1af10  batch1 installed-payload.tar
5b2d06628d36ff2b0915f7af40f8ea6d751128bfa5273191604573c9d1d2e967  batch1 package-database.tar
e9632d66fe1fb19c44d8c97b49bb79353411ecb0085819c941c892661c01c550  batch1 user-configs.tar
1e965dba4713f59bb6383a010e0a73761b20e931cccfe24db10b1283a673da80  walker-restart.hook
8b4bf1988bc887eebf412cee868d219ac082d053163cb23c0ef094009862485f  batch2 installed-payload.tar
adfc8665e497e441f4e47a220d0c164a0f0e541b522f15d97daac491a4a7d4d3  batch2 package-database.tar
22938868f6f4b15244daba3b9aecb0d4e7d52e52a7976850fae17a81643870a0  batch2 user-configs.tar
```

The powered-off Phase 3 VM remains the stronger whole-system rollback point.

## Pre-Reboot Result

After both removal batches and the manual Retina resize acceptance check:

```text
installed packages:  982
explicit packages:   201
foreign packages:    37
orphans:             0
manifest entries:    143
manifest missing:    0
pending migrations:  46
Quickshell IPC:       ok
Hyprland errors:      none
failed units:         zero system and user
NetworkManager:       connected
audio services:       active
renderer:             direct virgl (Apple M4 Pro), OpenGL 4.1
```

All 45 packages in the two exact transactions are absent. The exact
intersection between installed packages and Quattro's canonical retired list
is now:

```text
claude-code
dust
impala
iwd
localsend-bin
opencode
```

The first four application decisions are user-data preservation choices.
`impala` and `iwd` remain temporarily as the known network fallback until a
separate checkpoint removes that rollback path. Bluetooth's service remains
enabled but inactive because this VM exposes no Bluetooth hardware; the
current Quattro BlueZ packages remain installed.

The four protected hashes remain byte-for-byte identical to their Phase 3
values. No migration, finalization, kernel, initramfs, Limine, UEFI,
partition, or filesystem action ran.

## Post-Reboot Proof

The controlled proof boot began at `2026-07-30 05:09:02 EDT`. The normal
login and session chain returned:

```text
greetd -> start-hyprland -> Hyprland
                             |- quickshell
                             `- omarchy-hyprland-spice-resize
```

Hyprland selected `~/.config/hypr/hyprland.lua`, UWSM exported
`OMARCHY_PATH=/usr/share/omarchy`, and exactly one package-owned SPICE resize
helper ran as a direct Hyprland child. The current-boot journals contained no
Quickshell warnings, Hyprland errors, or `greetd` errors.

The reboot audit reproduced the pre-reboot package state:

```text
installed packages:  982
explicit packages:   201
foreign packages:    37
orphans:             0
manifest entries:    143
manifest missing:    0
pending migrations:  46
```

Both removal batches remain absent. The six normalized base providers remain
installed and explicit. `omarchy-dev`, `omarchy-settings-dev`,
`quickshell-git`, and Hyprland passed package-file checks; the protected
sudoers paths in `omarchy-settings-dev` were verified through `pkexec`.

Runtime proof after reboot:

- Quickshell IPC returned `ok`, with no Hyprland configuration errors.
- The Quickshell root menu, notification surface, and migration notification
  rendered without clipping or overlap.
- `omarchy launch terminal` opened a second Alacritty window normally; it was
  closed after inspection.
- Lua workspace dispatch moved from workspace 1 to 3 and back to 1.
- NetworkManager restored the same `.4` address and `.1` gateway; DNS and an
  HTTPS request to Arch Linux ARM passed.
- PipeWire, PipeWire Pulse, and WirePlumber were active with the SPICE audio
  device exposed. The existing output volume remained at the user's setting
  of zero, so an audible playback test was not forced.
- Both SPICE agents and all three Quickshell clipboard watchers returned.
- Direct VirGL remained active on the Apple M4 Pro with OpenGL 4.1 and no
  software-rendering environment override.
- There were zero failed system or user units.

Visual references:

```text
menu:         ~/Pictures/screenshot-2026-07-30_05-11-17.png
notification: ~/Pictures/screenshot-2026-07-30_05-11-25.png
terminal:     ~/Pictures/screenshot-2026-07-30_05-11-52.png
```

The display initially returned at `3024x1818@60`, scale 2. The user then
resized the UTM window and waited beyond the prior rollback interval. The
window stayed put at:

```text
physical mode: 2828x1818@60
DRM preferred: 2828x1818
scale:         2
logical size:  1414x909
```

The user also copied `phase4-clipboard-ok` from macOS and pasted it into the
guest, proving host-to-guest SPICE clipboard transfer after reboot.

All four protected hashes remain byte-for-byte exact. No migration,
finalization, kernel, initramfs, Limine, UEFI, partition, or filesystem action
ran. Phase 4 legacy cleanup is complete.
