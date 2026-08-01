# Quattro ARM64 Persistent Session Proof

Date: 2026-07-30

## Outcome

The first persistent Quattro desktop milestone passed on the existing
Archboot ARM64 installation.

This was a real proof boot, not the mixed-session transient launch used during
the initial package test:

- Hyprland selected `~/.config/hypr/hyprland.lua`;
- UWSM exported `OMARCHY_PATH=/usr/share/omarchy`;
- Quickshell started directly from Quattro's Hyprland autostart;
- the transient validation service did not exist;
- no legacy Waybar, Mako, swaybg, Walker, Elephant, SwayOSD, or polkit-agent
  process returned;
- Quickshell owned notifications and its IPC returned `ok`;
- the shell restarted successfully through the normal `omarchy restart shell`
  command;
- VirGL, audio, clipboard, workspaces, SPICE agents, menu navigation, terminal
  launch, and notifications passed;
- host-driven UTM resizing passed in both directions after adding the
  SPICE/virtio-gpu monitor synchronizer;
- the protected boot files remained byte-for-byte unchanged.

## Proof-Boot Evidence

The guest booted at `2026-07-30 00:57:55 EDT`:

```text
Linux omarchy-vm 7.1.5-2-aarch64-ARCH aarch64
```

The user-manager environment was:

```text
OMARCHY_PATH=/usr/share/omarchy
PATH=/usr/share/omarchy/bin:...:/usr/bin:...
XDG_CURRENT_DESKTOP=Hyprland
XDG_SESSION_TYPE=wayland
```

Hyprland's current-boot log contained:

```text
[cfg] Regular config at ~/.config/hypr/hyprland.lua
[cfg] Using lua config found at ~/.config/hypr/hyprland.lua
```

The normal startup process relationship was:

```text
Hyprland   PID 899
Quickshell PID 931, parent 899
```

`omarchy-quattro-shell-runtime.service`, used only for the mixed-session
preparation test, was `not-found` after reboot. Quickshell loaded 34 first-party
plugins with 27 enabled, returned `ok` from `shell ping`, and owned
`org.freedesktop.Notifications`.

The shell then restarted through:

```bash
omarchy restart shell
```

The replacement Quickshell process remained a direct child of Hyprland, IPC
returned `ok`, and notification ownership moved cleanly to the new process.
No temporary environment override was needed.

## User-Supplied Notification Image

The host-shared screenshot was inspected at:

```text
~/utm/quattro-desktop-notifications.png
```

The notification surfaces were legible and consistently aligned with no text
clipping or overlap. They showed:

- the normal system-update invitation;
- the normal first-run keybinding invitation;
- an `udiskie` command-not-found failure;
- 46 pending Omarchy migrations.

The first two are normal invitations. The latter two were investigated.

## Missing `udiskie` Runtime

Quattro's default Hyprland autostart invokes:

```text
udiskie --automount --no-notify --no-tray
```

`udiskie` was absent because this experiment installed the core
`omarchy-dev` package and selected runtime dependencies rather than the ISO's
full `install/omarchy-base.packages` manifest. The package is present
unchanged in the signed Arch Linux ARM `extra` repository:

```text
udiskie 2.6.2-1 any
```

It was installed with its three missing dependencies:

```text
python-docopt   0.6.2-15
python-keyutils 0.6-12
python-yaml     6.0.3-2
udiskie         2.6.2-1
```

`pacman -Qk udiskie` reports 131 files and zero missing files. The autostart
command was relaunched through Hyprland/UWSM and remains active as a child of
Hyprland:

```text
/usr/bin/python /usr/bin/udiskie --automount --no-notify --no-tray
```

The command-not-found notification was dismissed only after the successful
runtime launch. The next login has the same Quattro autostart entry and now
has the required command.

No Omarchy source change is needed for this package in the normal ISO path:
`udiskie` is already listed in `install/omarchy-base.packages`. The finding is
important for package-only bring-up instructions because `omarchy-dev` is not
the complete desktop package manifest.

## Pending Migration Queue

The 46-migration notification was not clicked.

The existing user had 331 markers from its previous Omarchy/Armarchy history,
while all 46 migrations shipped by the installed Quattro source were pending.
The reason is explicit in `omarchy-finalize-user`:

- runtime finalization, which this experiment ran, does not stamp migrations;
- `--first-install`, used for a freshly created ISO user, stamps all shipped
  migrations complete;
- the full existing-user `omarchy-upgrade-to-quattro` path runs pending
  migrations.

This experiment deliberately did not run either broad path. Running the entire
queue now would exceed the milestone guardrails. It includes, among other
work:

```text
1782002156.sh  retire systemd-networkd in favor of NetworkManager
1784476564.sh  conditionally rebuild initramfs for keyboard-layout handling
1784917531.sh  conditionally rebuild the Limine-managed boot image
1785273276.sh  conditionally repair a T2 Mac boot image
```

The T2 migration is irrelevant on this generic UEFI VM and its hardware file
is absent. Some other boot migrations would currently no-op, but the queue
also contains the intentional, disruptive network-stack transition. Faking
all markers would hide unapplied system work, while running the queue would
violate the no-boot-change boundary and conflate the desktop proof with the
next system-integration phase.

The queue therefore remains visible and documented. It blocks declaring the
whole existing-user Quattro upgrade complete, but it does not invalidate the
persistent Hyprland/Quickshell desktop milestone.

## Acceptance Matrix

| Check | Evidence | Result |
| --- | --- | --- |
| Persistent environment | UWSM exports `/usr/share/omarchy` | Pass |
| Active compositor config | Current-boot log selects `hyprland.lua` | Pass |
| Hyprland reload | `hyprctl reload`; `configerrors` empty | Pass |
| Normal shell autostart | Quickshell is Hyprland child; transient service absent | Pass |
| Shell restart | `omarchy restart shell` replaced process and restored IPC | Pass |
| Plugin registry | 34 registered, 27 enabled | Pass |
| Legacy surfaces | No legacy UI or polkit process | Pass |
| Notifications | Quickshell owns D-Bus service and rendered proof toast | Pass |
| Menu | Root route and typed Apps filter inspected | Pass |
| Terminal | `wtype -k Return` launched a second native Alacritty client | Pass |
| Workspaces | Lua dispatcher visited 3 and 2, then restored 1 | Pass |
| Graphics | Direct VirGL on Apple M4 Pro, Mesa 26.1.5, OpenGL 4.1 | Pass |
| Software fallback | No software-rendering override in manager, Hyprland, or Quickshell | Pass |
| Audio | PipeWire sink/source and both 48 kHz stereo channels exercised | Pass |
| Clipboard | Token round-trip passed and prior text restored | Pass |
| Removable media runtime | `udiskie` installed, verified, and active | Pass |
| SPICE | System and user agents active; repeated host resize modes held | Pass |
| Resize helper persistence | Package-owned helper returned through normal post-reboot autostart | Pass |
| Unit health | Zero failed system and user units | Pass |

With Lua configuration active, the legacy command:

```bash
hyprctl dispatch workspace 3
```

is parsed as invalid Lua. The correct dispatcher used for the proof was:

```bash
hyprctl dispatch 'hl.dsp.focus({ workspace = "3" })'
```

The round trip visited workspaces 3 and 2 and restored workspace 1.

## Visual Evidence

The following proof-boot screenshots were captured and inspected at 1280x800:

```text
~/Pictures/screenshot-2026-07-30_01-09-06.png  persistent shell and bar
~/Pictures/screenshot-2026-07-30_01-09-17.png  root menu
~/Pictures/screenshot-2026-07-30_01-09-30.png  typed Apps filter
~/Pictures/screenshot-2026-07-30_01-09-44.png  terminal launched from menu
~/Pictures/screenshot-2026-07-30_01-10-03.png  proof-boot notification
```

No clipping, overlap, stale surface, or focus problem was observed. The only
visual defect in the user-supplied notification image was the accurate
`udiskie` runtime failure, which is now resolved.

## SPICE Dynamic Resize

The first host-driven resize exposed a Quattro runtime regression. UTM changed
the virtio DRM connector's preferred mode, but Hyprland did not adopt it before
`spice-vdagent` restored the previous configuration:

```text
01:27:22.613 kernel=800x600  hypr=1280x800
01:27:28.860 kernel=1280x800 hypr=1280x800
```

The Omarchy monitor watcher was not responsible. It only handles monitor
addition/removal and clamshell reconciliation. During the failed resize:

- `/sys/class/drm/card0-Virtual-1/modes` advertised the requested mode first;
- Hyprland's active mode and cached mode list remained unchanged;
- `spice-vdagent` logged failed XRandR requests and restored the old mode.

A live Lua monitor update proved that the compositor and virtio-gpu accepted
the transient mode:

```bash
hyprctl eval \
  'hl.monitor({ output = "Virtual-1", mode = "1512x909@60", position = "auto", scale = 1 })'
```

`1512x909` then remained active beyond the previous rollback window. The
upstreamable fix added `omarchy-hyprland-spice-resize`, launched through normal
Quattro Hyprland autostart. It is narrowly gated on both:

- `/dev/virtio-ports/com.redhat.spice.0`;
- a DRM card bound to the `virtio_gpu` driver.

The helper listens for DRM kernel events, reads the connector's preferred
dimensions, and applies them through Hyprland's Lua API while preserving the
monitor's position and scale. It exits immediately on non-matching hardware.

Focused tests cover the changed mode, redundant mode, missing SPICE port,
non-virtio GPU, and disconnected-output cases. Repeated smaller/larger resizes
passed with the checkout helper. The exact committed payload was then built,
inspected, and installed as:

```text
omarchy-dev          4.0.0.r1471.g227b6e0-1
omarchy-settings-dev 4.0.0.r1471.g227b6e0-1
```

The installed `/usr/bin/omarchy-hyprland-spice-resize` passed another manual
host resize. After the rollback window, the connector and compositor agreed:

```text
kernel preferred: 800x600
Hyprland active:   800x600@60.317, scale 1
```

There was no new `Restoring previous config` event. Hyprland config errors
remained empty, Quickshell IPC returned `ok`, and VirGL remained
`virgl (Apple M4 Pro)` with OpenGL 4.1 and no software-rendering override.

The implementation and tests were pushed on `quattro-aarch64-utm` in commit
`227b6e0ec245ecdf0d8175aa05be5e03d0e36b61`.

### Post-Reboot Persistence

After a powered-off safety checkpoint, the original VM booted again at
`2026-07-30 01:48:02 EDT`. Normal Quattro autostart produced exactly one
package-owned helper:

```text
Hyprland PID 1104
resize helper PID 1183, parent 1104
/bin/bash /usr/share/omarchy/bin/omarchy-hyprland-spice-resize
```

The `/usr/share/omarchy/bin` command is the package symlink to `/usr/bin`.
No checkout path or temporary service was involved. Before the manual test,
the connector and Hyprland already agreed at `1376x909`.

The final post-reboot trace captured two host size changes:

```text
01:49:56.604 kernel=800x600  hypr=1376x909
01:49:56.713 kernel=800x600  hypr=800x600
01:50:19.340 kernel=1512x909 hypr=1512x909
```

The helper adopted the first requested mode in approximately 109 ms. The
second was already synchronized by the next 100 ms sample. Both sizes stayed
put.

`spice-vdagent` still logged its known XRandR failure and
`Restoring previous config` message during the first transition. That warning
describes its XWayland compatibility path, not the resulting DRM/Hyprland
state: the connector did not revert, the UTM window did not snap back, and the
final connector and compositor state remained `1512x909@60`.

After the final resize:

- Hyprland still loaded `~/.config/hypr/hyprland.lua` with no errors;
- Quickshell remained a direct Hyprland child and IPC returned `ok`;
- both SPICE services remained active;
- VirGL remained direct on Apple M4 Pro with OpenGL 4.1;
- no software-rendering override was present;
- system and user failed-unit counts remained zero;
- all three development repositories remained clean.

## Boot Integrity

The protected hashes remained exact after the proof boot, package
installations, shell restart, dynamic-resize package upgrade, post-upgrade
reboot, and acceptance checks:

```text
2662962bab816958bad80f3c24e275f2e306b984bdf1f81dc235342382c8048f  /boot/initramfs-linux.img
add658562939b9abb73bf6fe7865fb177cd8fbfa5a73479467cf3469da57ac44  /boot/limine.conf
6edf91b6ee62aff521de9666d6f8c790be086ecec48352f2dd580d66a6831dd3  /etc/mkinitcpio.conf
a0bf23d62d7d74bfa597e38af7cc841837ba4a353ed8f8b10b5dd3a69dab5814  /etc/mkinitcpio.d/linux-aarch64.preset
```

No partition, filesystem, kernel, bootloader, initramfs, or UEFI operation was
performed.

## Remaining Work

The desktop milestone is complete. The next system-integration phase is:

1. decide how to handle the existing-user migration queue without violating
   the boot-stack guardrail;
2. move the disposable VM from iwd/systemd-networkd to NetworkManager so the
   Quickshell network backend becomes available;
3. remove the now-unused legacy UI packages after preserving the checkpoint;
4. decide whether BlueZ should be installed despite the VM having no Bluetooth
   hardware;
5. turn the local Gradle recipe and ARM package work into upstreamable changes;
6. implement and test the ARM kernel mapping in the ISO/setup path;
7. publish and validate the missing Omarchy AArch64 package repositories;
8. build an ISO only after those repository and orchestration gaps close.
