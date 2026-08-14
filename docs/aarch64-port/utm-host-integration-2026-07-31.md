# UTM Host Integration and Optional Guest Extras

Date: 2026-07-31

Status: design decision recorded; extras extraction not yet implemented

## Product Boundary

The AArch64 ISO must install and run as an independent Omarchy machine. Its
core acceptance does not depend on a macOS clipboard or on the UTM window
controlling the guest's display mode.

Core Omarchy owns:

- UEFI boot, installation, encrypted root, Limine, and Snapper;
- Virtio GPU, network, audio, input, and a stable graphical session;
- the graphical Plymouth LUKS prompt and serial diagnostics;
- the Omarchy Display panel and `~/.config/hypr/monitors.lua`;
- Wayland clipboard history and bindings inside the guest; and
- normal remote workflows such as SSH, `scp`, `rsync`, Git, and Tailscale.

Optional guest extras may own:

- macOS-to-Wayland and Wayland-to-macOS clipboard forwarding over SPICE; and
- following live UTM window-size changes as new guest display modes.

macOS and UTM own the host window, full-screen Spaces, VM hardware settings,
removable installation media, and the SPICE transport exposed to the guest.

This boundary makes the default VM behave like bare metal or a cloud machine.
A user who wants tighter host integration can install it deliberately.

## Installation-Media Handoff

UTM's VM configuration editor is locked while a VM is running. Its drive-image
menu can normally manage removable media, but a running Linux guest may lock a
mounted CD/DVD and cause UTM's live `Eject` action to fail. Unmounting the
filesystem in the guest only stops Linux from using it; it does not clear the
ISO from UTM's virtual drive.

Do not force-clear the Omarchy installer ISO while its live environment is
running. The ISO does not use `copytoram`: the ArchISO boot mount and SquashFS
live root continue to depend on the optical media.

Use both of these safeguards for an installation VM:

1. Put the blank target disk before the ISO in the UEFI boot order. Firmware
   falls through to the ISO while the disk is not bootable, then prefers the
   installed disk after setup.
2. After installation succeeds, cleanly power off the live environment rather
   than forcing its media out. While the VM is stopped, choose `Clear` for the
   CD/DVD image in UTM, then start the VM and boot the installed disk. This is
   the deterministic handoff.

Until the installer's success screen offers a dedicated power-off action,
leave its final reboot prompt and run `poweroff` from a live or serial shell.
Guest-side `eject /dev/sr0` is appropriate for an ordinary mounted data disc,
but not for the ISO that backs the running live system.

Leaving the ISO attached can return the VM to the installer keyboard screen.
If that happens, no target repair is required: cleanly power off, clear the ISO
from UTM, and boot the installed disk again.

## Distributable UTM Template

The ISO cannot configure UTM from inside the guest. A preconfigured `.utm`
bundle may instead be published as an optional companion download for Apple
Silicon users. It is a host convenience, not part of the portable Omarchy ISO
or a requirement for installing on other AArch64 machines.

Use this drive layout in the template:

| Order | Purpose | Image type | Interface |
| --- | --- | --- | --- |
| 1 | Blank 64 GiB target | `Disk Image` | `VirtIO` |
| 2 | Omarchy installer | `CD/DVD (ISO) Image` | `USB` |

UTM treats the first type as a non-removable system disk and the second as
removable optical media. The interface only selects the emulated bus; changing
the installer from USB to SCSI does not make live ejection safe. Do not use the
deprecated `BIOS`, `Linux Kernel`, `Linux RAM Disk`, or `Linux Device Tree
Binary` image types for the normal UEFI installation path.

The template's CD/DVD drive must initially be empty. UTM stores removable
media as a bookmark to an external host file, so a template that points to its
creator's ISO path is not portable. After opening the template, the user
selects the separately downloaded and checksum-verified ISO for that empty
drive. The ISO remains a separate release artifact and can be updated without
rebuilding the template.

If a template is released, publish the stopped `.utm` bundle as a separate
archive and record the UTM version used to create and test it. It should also
include the Phase 9-proven CPU, memory, UEFI, display, network, sound, and
serial defaults, while keeping clipboard forwarding and host-window resize
helpers optional under the guest-extras boundary described below.

Keep UTM on an input-capable sound backend rather than selecting CoreAudio,
which UTM documents as output-only. macOS may request microphone permission on
first use; restart UTM after granting it. Phase 9 then exposed the emulated
duplex input through PipeWire/WirePlumber and passed microphone recording and
playback. This requires no SPICE clipboard bridge or other guest extra.

UTM documents image-type, removable-media, interface, and boot-order behavior
in its [QEMU drive settings](https://docs.getutm.app/settings-qemu/drive/drive/).
Its [macOS sound settings](https://docs.getutm.app/preferences/macos/#sound)
document the CoreAudio input limitation.

## macOS Window Sizing

The macOS green-button menu controls the macOS window, not Hyprland:

- `Move & Resize` and `Fill & Arrange` place or tile the UTM window;
- `Full Screen > Entire Screen` is the closest match to dedicating a macOS
  Space to the VM; and
- the left/right full-screen choices tile UTM with another macOS application.

For the bare-metal-style workflow, use `Full Screen > Entire Screen` and
switch Spaces with normal macOS gestures or shortcuts. Omarchy does not need
to know how macOS placed the UTM window.

There are three separate sizing layers:

```text
macOS window or Space
  -> optional UTM Auto Resolution request
    -> guest Virtio GPU preferred mode
      -> Hyprland mode and Omarchy logical scale
```

Changing the first layer does not edit guest configuration. With Auto
Resolution disabled, or without a guest resize integration, UTM fits or scales
the fixed guest output inside its host window. This is a valid and supported
default.

With Auto Resolution enabled, UTM can advertise a new preferred Virtio GPU
mode when the host window changes. An optional guest resize service can make
Hyprland adopt that transient preferred mode. The macOS command itself still
does not write any Omarchy file.

## Omarchy Display Configuration

The Display panel in the top-right Omarchy bar controls desktop text size and
the focused Hyprland monitor's logical scale. It does not choose the macOS
window size and does not independently create a new Virtio GPU pixel mode.

For the generic monitor, Omarchy persists the selected scale in:

```text
~/.config/hypr/monitors.lua
```

The shipped model keeps the mode at `preferred` and separates toolkit scale
from monitor scale:

```lua
local omarchy_gdk_scale = 2
local omarchy_monitor_scale = "auto"

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })
```

The optional extras must not replace or own this file. Two supported operating
styles follow from that rule:

- Fixed display: leave dynamic resize disabled and use the Omarchy Display
  panel to choose a comfortable persistent scale.
- Dynamic display: enable UTM Auto Resolution and the optional resize service,
  keep the generic mode at `preferred`, and let the service preserve the
  current position and scale while adopting new preferred modes.

Hard-coding a physical resolution is a valid personal fixed-display choice,
but it intentionally prevents the dynamic workflow from following UTM.

## Proposed Optional Extras Project

Use a separate repository and AUR package rather than adding host assumptions
to the base ISO. Its repository, package, command, and systemd unit names must
use an independent, collision-checked namespace rather than `omarchy-*`. Keep
the project usable by other QEMU and virt-manager guests where practical.

Proposed roles, using placeholders until that namespace is selected:

```text
<project>/
  PKGBUILD
  README.md
  LICENSE
  bin/
    <wayland-to-x11-clipboard-command>
    <x11-to-wayland-clipboard-command>
    <compositor-resize-command>
  systemd/user/
    <wayland-to-x11-clipboard-service>
    <x11-to-wayland-clipboard-service>
    <clipboard-target>
    <compositor-resize-service>
  test/
```

The AUR package can use `arch=('any')` when it contains only shell scripts and
user units. Expected runtime dependencies are `spice-vdagent`, `wl-clipboard`,
`xclip`, and `clipnotify`. `wl-clipboard` is already a core Omarchy dependency
for the native Wayland clipboard plugin; the extras package does not take
ownership of that plugin.

Installation should not silently enable both integrations. Let the user opt
into the final clipboard target and resize service separately after their
collision-checked names are selected.

The units should join the graphical session, require the session's imported
Wayland/X11 environment, and exit harmlessly when the SPICE virtio port is not
present. The resize service should additionally require a Virtio GPU.

## Clipboard Bridge Design

`spice-vdagent` integrates with X11 selections. XWayland supplies an X11
environment inside a Wayland session, but its presence does not give the agent
general access to Hyprland's native Wayland clipboard. Explicit forwarding is
still required:

```text
macOS clipboard
  <-> UTM SPICE channel
    <-> spice-vdagent X11 selection
      <-> optional xclip/wl-clipboard bridge
        <-> Hyprland Wayland selection
```

One user service can watch Wayland with `wl-paste --watch` and publish changes
to X11 with `xclip`. The reverse service can use `clipnotify` plus `xclip -o`
and publish received X11 changes with `wl-copy`.

The implementation must:

- suppress echo loops and duplicate payloads in both directions;
- preserve empty-selection behavior;
- begin with explicit UTF-8 text MIME handling;
- avoid forwarding `CLIPBOARD_STATE=sensitive` and password-manager hints;
- make image MIME support a deliberate later feature; and
- never replace Quickshell's existing Wayland clipboard-history watcher.

The Quickshell clipboard plugin remains the native in-guest history. Bridged
non-sensitive content will naturally enter that history after it becomes a
Wayland selection.

## Resize Extraction

Phase 9 proved the currently bundled `omarchy-hyprland-spice-resize` helper:
UTM changed the DRM preferred mode and the helper made Hyprland follow it while
preserving position and scale. That result remains valid.

The ownership decision came after acceptance. The intended follow-up is to
move that helper, its autostart, its package dependency, and its focused tests
from core Omarchy into the optional extras repository. Until that extraction
lands, the Phase 9 source tree still contains the bundled implementation.

Core and extras should then be accepted independently:

- Core: boot and use a fixed graphical mode with extras absent.
- Resize extra: change UTM window sizes repeatedly and verify DRM and
  Hyprland converge without changing the configured logical scale.
- Clipboard extra: prove both text directions, duplicate suppression,
  sensitive-content exclusion, reboot persistence, and harmless behavior
  without a SPICE port.
