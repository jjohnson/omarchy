# Quattro ARM64 Persistent Session Cutover

Date: 2026-07-30

This records the preparation of the existing Archboot ARM64 installation for
a persistent Quattro Hyprland/Quickshell login. The running compositor was
kept on its working legacy configuration while the next-login configuration
was prepared and verified.

## Reboot and Repository Checkpoint

The VM booted normally at `2026-07-30 00:24:23 EDT` with:

```text
Linux omarchy-vm 7.1.5-2-aarch64-ARCH aarch64
```

All three development branches were clean, tracked the corresponding personal
fork, and exactly matched their remote branch:

```text
omarchy      6f07696239940e7f28008848b48d030863e1e6a2
omarchy-pkgs c2a36d3a12607b0f83a299c4d4d28e91f6a23914
omarchy-iso  a76f599eaae524d9fb9e135473320e4e66696cb7
```

The old Omarchy checkout at `~/.local/share/omarchy` remained unchanged on its
`utm-arm-upgrade` branch at
`4989cb77bb86f31920ea9e3a2d4de2e65ac9b553`.

## Pre-Cutover Backup

The user configuration and state affected by the cutover were archived before
any changes:

```text
/home/jj/Projects/omarchy-pkgs-quattro-arm64/build-output/pre-persistent-cutover-2026-07-30-002942.tar
```

Archive size and SHA-256:

```text
25M
a12466e3e292a4f3b2b9ddf6f51b1c6b2ca78f33b408a02f99793cbc5198f2c5
```

It contains `.bashrc`, `.bash_profile`, the Hyprland, UWSM, Omarchy,
autostart, and user-systemd configuration, plus the existing Omarchy runtime
state.

Files retired from active configuration were also moved individually to:

```text
~/.local/state/omarchy/cutover-backups/2026-07-30-002942/
```

This second location contains the legacy UWSM environment, Walker autostart,
Elephant and SwayOSD units, battery-monitor units, and the legacy
internal-monitor recovery unit.

## Scoped User Cutover

The existing `~/.config/uwsm/env` had SHA-256
`0c2cd9c32bd8aea26c62bc18c4a287a29999d4b2ec2b3216b666fb204ab3c471`.
That is an exact known Omarchy legacy default; it contained no user-only
environment customization. It was retired so the package-owned
`/usr/share/uwsm/env.d/10-omarchy` will provide the next session environment:

```text
OMARCHY_PATH=/usr/share/omarchy
```

The existing Bash startup retained its VM-specific `imv` alias but now loads
the package-backed Omarchy environment and Bash runtime instead of sourcing
the old checkout.

No Hyprland Lua user configuration existed. The seven shipped Quattro files
were therefore installed as new files, with no Lua customization overwritten:

```text
~/.config/hypr/.luarc.json
~/.config/hypr/autostart.lua
~/.config/hypr/bindings.lua
~/.config/hypr/hyprland.lua
~/.config/hypr/input.lua
~/.config/hypr/looknfeel.lua
~/.config/hypr/monitors.lua
```

Every file exactly matches its counterpart under
`/usr/share/omarchy/config/hypr`. The legacy `*.conf` configuration and
Armarchy compatibility files remain in place for reference and rollback.

Hyprland's current-session log established the selection rule:

```text
[cfg] Lua config not found, using legacy config at /home/jj/.config/hypr/hyprland.conf
```

With `hyprland.lua` now present, the next Hyprland start should select the Lua
configuration. Explicit validation returned:

```text
======== Config parsing result:

config ok
```

The generated Walker autostart and the user-owned Elephant, SwayOSD, and
battery-monitor units were stopped and retired. The package-backed
`omarchy-recover-internal-monitor.service` and
`omarchy-sleep-lock.service` are enabled for the next session. Legacy packages
remain installed until the persistent login succeeds, preserving a package
fallback without allowing their user units to start.

## Live Shell Handoff

Because the already-running Hyprland process inherited the legacy environment,
the shell was validated in a managed transient unit with explicit Quattro
paths:

```bash
uwsm-app -s b -t service \
  -u omarchy-quattro-shell-runtime.service \
  -d "Quattro shell ARM64 persistent-cutover validation" \
  -p "Environment=OMARCHY_PATH=/usr/share/omarchy" \
  -p "Environment=PATH=/usr/bin:/bin" \
  -- quickshell -n -p /usr/share/omarchy/shell
```

After the shell IPC became ready, the exact legacy Mako, Waybar, swaybg, and
polkit-agent processes were stopped. Quickshell was restarted once so it could
register notifications and polkit without startup conflicts.

Final live state:

```text
Quickshell service: active/running
Quickshell IPC: ok
Plugins: 34 registered, 27 enabled
Notification owner: /usr/bin/quickshell
Legacy UI processes: none
Failed system units: 0
Failed user units: 0
```

The remaining shell warnings are expected host/optional-service differences:

- `iwd` is active and NetworkManager is not installed, so the Quickshell
  network backend is unavailable.
- No BlueZ service or Bluetooth hardware exists.
- No Claude credentials or history exist for the model-usage provider.

The clean restart produced no notification-server or polkit-agent warning.

## Acceptance Results

| Check | Evidence | Result |
| --- | --- | --- |
| Quattro Lua config | Explicit `Hyprland --verify-config` | `config ok` |
| Active legacy config | `hyprctl configerrors` | No errors |
| Quickshell | Managed process, IPC ping, plugin inventory | Pass |
| Menu | Root route and typed Apps filter inspected | Pass |
| Terminal | `wtype -k Return` launched a new native Alacritty client | Pass |
| Notifications | Quickshell owns D-Bus service and rendered test toast | Pass |
| Workspaces | Visited workspaces 3 and 2, then restored the starting workspace | Pass |
| Graphics | Direct VirGL rendering on Apple M4 Pro, Mesa 26.1.5, OpenGL 4.1 | Pass |
| Software fallback | No rendering override in user manager, Hyprland, or Quickshell | Pass |
| Audio | PipeWire sink/source and both 48 kHz stereo channels exercised | Pass |
| Clipboard | Token round-trip passed and previous text was restored | Pass |
| SPICE | System and user agents active | Pass |
| Session health | No failed system or user units | Pass |

Visual evidence inspected at 1280x800:

```text
~/Pictures/screenshot-2026-07-30_00-31-21.png  shell and bar
~/Pictures/screenshot-2026-07-30_00-31-44.png  root menu
~/Pictures/screenshot-2026-07-30_00-32-47.png  typed Apps filter
~/Pictures/screenshot-2026-07-30_00-32-59.png  launched terminal
~/Pictures/screenshot-2026-07-30_00-33-31.png  Quickshell notification
```

No clipping, overlap, stale legacy surfaces, or focus failure was observed.
A host-driven UTM resize still requires a manual host interaction; both SPICE
agents remain active.

## Boot Integrity

The protected files remained byte-for-byte unchanged after the reboot and
cutover preparation:

```text
2662962bab816958bad80f3c24e275f2e306b984bdf1f81dc235342382c8048f  /boot/initramfs-linux.img
add658562939b9abb73bf6fe7865fb177cd8fbfa5a73479467cf3469da57ac44  /boot/limine.conf
6edf91b6ee62aff521de9666d6f8c790be086ecec48352f2dd580d66a6831dd3  /etc/mkinitcpio.conf
a0bf23d62d7d74bfa597e38af7cc841837ba4a353ed8f8b10b5dd3a69dab5814  /etc/mkinitcpio.d/linux-aarch64.preset
```

No partition, filesystem, kernel, bootloader, initramfs, or UEFI operation was
performed.

## Next Login and Rollback

The remaining acceptance step is a reboot or full logout/login. Success means:

- Hyprland's log reports `~/.config/hypr/hyprland.lua`;
- UWSM exports `/usr/share/omarchy`;
- Quickshell starts directly from Quattro autostart without the transient unit;
- Waybar, Mako, swaybg, Walker, Elephant, and the old polkit agent do not start;
- graphics, audio, clipboard, workspaces, SPICE, and visual behavior still pass.

The simplest compositor rollback from a TTY is to move
`~/.config/hypr/hyprland.lua` out of the active name. Hyprland will then fall
back to the preserved `~/.config/hypr/hyprland.conf`. The complete pre-cutover
state is available in the tar archive, and every retired login hook is also
available under the timestamped rollback directory.
