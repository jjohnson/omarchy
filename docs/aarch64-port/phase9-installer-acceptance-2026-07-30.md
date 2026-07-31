# Phase 9 AArch64 Installer Acceptance

Date: 2026-07-30

Status: complete

## Scope

Phase 8 remained running as the 2-CPU, 4 GiB controller. Phase 9 was created
as a separate disposable UTM virtual machine with a new blank disk. No proof,
package-closure, build, or prior installed-system disk was attached to it.

The UTM display settings validated during this phase are:

```text
Emulated Display Card: virtio-gpu-gl-pci (GPU Supported)
Auto Resolution:       enabled
Serial device:         attached before boot
```

`virtio-ramfb-gl` can display the live installer but leaves the installed
graphical LUKS prompt without an active scanout. It is not the accepted
installed-system configuration.

The Omarchy installer exposes only keyboard, timezone, username, password,
full name, email address, and hostname choices. Storage layout, LUKS, Btrfs,
Limine, and Snapper are installer-owned.

## Failures Found by the Fresh Install

### Live SquashFS compression

The first ARM ISO reached the initramfs but failed to mount `/dev/loop0`:

```text
Filesystem uses "zstd" compression. This is not supported.
ERROR: Failed to mount '/dev/loop0'
```

The Arch Linux ARM kernel has SquashFS but not
`CONFIG_SQUASHFS_ZSTD`. AArch64 builds now use XZ for the live SquashFS;
x86_64 builds retain zstd.

### Live tty1 scanout

UTM initially reported `Display output is not active` while the installer was
running on `tty1`. The guest had both `efifb` and `virtio_gpudrmfb`, but tty1
was not mapped to the active Virtio scanout. The live image now runs
`omarchy-live-console-map`, which finds the framebuffer named
`virtio_gpudrmfb` and maps tty1 with `FBIOPUT_CON2FBMAP`.

The corrected live ISO can take about 17 seconds to progress from the
apparently inactive display to the graphical keyboard picker. That delay is
not a boot failure.

### Native Limine kernel entry

The fresh installation reached `Finalizing Limine boot` and stopped.
`linux-aarch64` installs `/boot/Image`; it does not provide the x86-style
pkgbase kernel path expected by the previous `limine-update` flow.

The target now ships `omarchy-update-kernel-arm64`. It:

- rebuilds the `linux-aarch64` initramfs;
- registers `/boot/Image` and `/boot/initramfs-linux.img` with
  `limine-entry-tool`;
- validates the native Limine 12 `protocol: linux` entry, kernel, initramfs,
  encrypted root, and root command line;
- is called by a target pacman hook for ARM kernel, initcpio, firmware,
  systemd, cryptsetup, LVM, and DKMS changes.

The installer system finalizer calls this updater on AArch64 and retains
`limine-update` on x86_64. Its validation accepts current `path:` entries and
the legacy `kernel_path:` spelling.

### Resume pacman state

Resuming at user finalization previously reran target preparation and copied
the live offline pacman configuration over the target's restored online
configuration. Target preparation is now restricted to the system finalizer;
resumed user finalization preserves the installed system configuration.

### Graphical LUKS and dynamic resize

The ARM firmware publishes its serial console through SPCR. Plymouth therefore
selected the serial terminal even when the Virtio GPU had an active
framebuffer. On a target with `virtio_gpudrmfb`, hardware setup now writes:

```text
KERNEL_CMDLINE[default]+=" plymouth.ignore-serial-consoles"
```

The resulting Limine entry presents the large branded Omarchy LUKS screen and
accepts the password in the graphical window. Serial remains available for
diagnostics.

`spice-vdagent` was also missing from the authoritative fresh-install package
manifest. It is now installed by default. Both the system and user agents
return after reboot, and UTM window resizing updates DRM and Hyprland.

## Recovered Installed-System Proof

The exact source fixes were staged into the stopped fresh installation and
the failed finalization phases were resumed. The installed system then booted
without the ISO.

Runtime state:

```text
architecture:          aarch64
kernel:                7.1.5-2-aarch64-ARCH
root:                  encrypted Btrfs /dev/mapper/root[/@]
ESP:                   /dev/vda1, vfat
graphical LUKS:        branded Omarchy prompt
desktop:               Omarchy/Hyprland loaded
failed system units:   0
failed user units:     0
NetworkManager:        active
systemd-resolved:      active
sddm:                  active
PipeWire/Pulse:        active
WirePlumber:           active
SPICE agents:          active
```

The accepted kernel command line includes:

```text
cryptdevice=PARTUUID=3ba5de4e-8045-4e76-ad02-66f57bfa49b3:root
root=/dev/mapper/root
rootflags=subvol=@
resume=/dev/mapper/root
resume_offset=2197515
quiet splash
plymouth.ignore-serial-consoles
```

The user changed the UTM window from `1280x800` to `800x600`, then to
`1512x909`. At each size the DRM preferred mode and Hyprland mode agreed.
The final desktop had a complete full-width top bar and no clipping:

```text
/home/jj/utm/phase9-final-desktop-1512x909.png
SHA-256: 2d6d49f5b34e434ac2597d1f1938c8a898a5bd6a5e55f2c1a80469da9a7232a5
```

The bar had initially been disabled by the existing
`~/.local/state/omarchy/toggles/bar-off` toggle. Restoring it with
`omarchy-toggle-bar` confirmed that this was user state, not display
clipping.

## Snapshot Integration

The installed system has:

```text
snapshot 1: Phase 9 installer acceptance
snapshot 2: Phase 9 graphical boot acceptance
```

Limine generated a native ARM entry for snapshot 2 using:

```text
protocol: linux
path: boot():/.../limine_history/Image_sha256_f208d7f...
module_path: boot():/.../limine_history/initramfs-linux.img_sha256_2cd79c...
rootflags=subvol=/@/.snapshots/2/snapshot
plymouth.ignore-serial-consoles
```

This proves that the ARM kernel updater and `limine-snapper-sync` generate
snapshot entries with the encrypted-root and graphical-Plymouth arguments.

## Source Changes and Tests

Omarchy commits:

```text
dd1c4f42 Support ARM64 Limine kernel updates
7b8e2d90 Install SPICE guest agent by default
```

ISO commit:

```text
191d576 Complete the ARM64 installer boot path
```

Passing checks:

```text
focused ARM kernel updater tests
base package manifest tests
ISO architecture tests
Bash syntax and Python compile checks
full Omarchy shell suite
```

The full CLI suite still reports the pre-existing, unrelated missing summary
metadata for `omarchy-update-system-pkgs-when-conflicted`.

## Integrated Image

The committed fixes were rebuilt together with:

```bash
cd /home/jj/Projects/omarchy-iso-quattro-arm64
./bin/omarchy-iso-make --arch aarch64 --no-boot-offer \
  --local-source /home/jj/Projects/omarchy-quattro-arm64 \
  /home/jj/Projects/omarchy-pkgs-quattro-arm64
```

Artifact:

```text
/home/jj/utm/omarchy-2026.07.30-aarch64-local-phase9-integrated.iso
size:    4,617,543,680 bytes
SHA-256: 91d99878682b98b5232c7f73b4901a3f258eaecbb450e6ea1600456e8be97d88
```

Read-only inspection proved:

```text
ISO label:                    OMARCHY_202607
ISO GPT:                      data partition + 16 MiB EFI System Partition
EFI launcher:                 PE32+ ARM64, 7,778,304 bytes
EFI SHA-256:                  d1103dfc0e0df5c86157f30e52469cf9d52ddfad89b9c39e79fccc75cb556638
EFI copies:                   byte-identical
kernel:                       ARM64 Image, 7.1.5-2-aarch64-ARCH
kernel SHA-256:               f208d7f3d2e759be71f3a6a39a7c5b2193d9e3ed15b81ddccf89e72e7e17ccd9
initramfs size:               198,966,783 bytes
initramfs SHA-256:            19e22c09d07d3c4314252ee2d5c979adbfeff308d90750d74d969474051544ab
SquashFS file size:           4,349,689,856 bytes
SquashFS compression:         XZ
SquashFS SHA-256:             a7e7175403d90d365ccacab4f86a5d00d405d1bf0355dffc41a5265aac54fa7f
embedded SHA-512 self-test:   passed
live package manifest:        464
target install resolution:    929
offline archives/DB entries:  1,123/1,123
package signatures:           1,086
Gradle runtime archives:      0
stock/T2 live kernels:        0
x86 microcode packages:       0
```

The shared copy was read back independently and produced the same SHA-256.
Its checksum sidecar is:

```text
/home/jj/utm/omarchy-2026.07.30-aarch64-local-phase9-integrated.iso.sha256
```

## Clean Integrated-Image Replay

A second new UTM VM used the integrated ISO with:

```text
CPU:                    4
memory:                 8 GiB
new target disk:        64 GiB
display card:           virtio-gpu-gl-pci (GPU Supported)
Auto Resolution:        enabled
serial device:          attached before first boot
```

The graphical window briefly showed `Display output is not active`, resized
itself, went black during the framebuffer handoff, and then loaded the
Omarchy keyboard screen. The serial window showed normal systemd startup and
ended at the Archiso login prompt. This is the accepted live-media behavior.

The installer completed in 2 minutes 33 seconds without stopping or requiring
manual recovery. The first reboot returned to the keyboard picker because the
ISO remained attached. After stopping the VM and clearing the ISO, the blank
disk's installed system booted through Limine and presented the branded
graphical Omarchy LUKS prompt.

The password was accepted in the graphical window. Omarchy loaded with its
complete top bar, and resizing the UTM window smaller and larger adapted the
desktop and bar without clipping. This clean replay proves that the committed
live-console, XZ SquashFS, installer-resume, ARM kernel/Limine, Plymouth, and
SPICE changes work together from an untouched image and blank disk.

The final recovery-path test also passed. `omarchy snapshot create` created a
new numbered Snapper snapshot, `limine-snapper-list` showed its boot entry, and
the VM rebooted through Limine's `Snapshots` menu. The graphical Omarchy LUKS
screen accepted the encrypted-root password, the snapshot reached the desktop,
and a second reboot returned to the normal Omarchy entry without restoring the
snapshot. No repair or manual recovery was required.

This completes Phase 9 installer acceptance.

## Known Wayland Clipboard Boundary

UTM delivered clipboard grabs, requests, and data through the SPICE channel,
and both SPICE guest-agent processes were active. The installed session agent
identifies itself as an X11 agent, however, and the received selection did not
appear in Hyprland's Wayland clipboard.

Quattro's Lua clipboard bindings and Quickshell clipboard history both worked
inside the guest. They do not provide a SPICE-to-Wayland transport. Comparison
with Phase 8 traced its working host clipboard to an unowned pair of local
X11/Wayland forwarding services. The corresponding source workaround was
reverted and is not present in the integrated candidate. A proper fix belongs
in a native SPICE Wayland clipboard backend or equivalent compositor-level
Xwayland clipboard integration; it is not an AArch64 installer blocker.

## Phase 8 Controller Proof

After the integrated build and inspection, the Phase 8 controller remained
at 979 installed packages, 199 explicit packages, 37 foreign packages, zero
orphans, and zero failed system or user units. Omarchy shell IPC returned
`ok`, Hyprland reported no configuration error text, and direct VirGL remained
active on the Apple M4 Pro with OpenGL 4.1.

The protected hashes remained exact:

```text
2662962bab816958bad80f3c24e275f2e306b984bdf1f81dc235342382c8048f  /boot/initramfs-linux.img
add658562939b9abb73bf6fe7865fb177cd8fbfa5a73479467cf3469da57ac44  /boot/limine.conf
6edf91b6ee62aff521de9666d6f8c790be086ecec48352f2dd580d66a6831dd3  /etc/mkinitcpio.conf
a0bf23d62d7d74bfa597e38af7cc841837ba4a353ed8f8b10b5dd3a69dab5814  /etc/mkinitcpio.d/linux-aarch64.preset
```

The global pacman cache retained the exact Phase 8 regular-file byte total of
2,765,056,410 bytes. Build downloads remained isolated under
`~/.cache/omarchy/iso_edge_aarch64`.

## Temporary Access Cleanup

All temporary controller access was removed after the audits. On the recovered
VM, the exact port-22 IPv4 and IPv6 UFW rules and temporary
`/root/.ssh/authorized_keys` file were removed, and `sshd.service` finished
disabled and inactive.

On the clean replay, the controller key was removed from the `quattro` user's
`authorized_keys`, the empty temporary `.ssh` directory was removed, and the
Phase 9 firewall exception was deleted. The Phase 8 one-file key server,
temporary key file, listener, and narrow port-8765 firewall exception were
also removed.

## Known Distribution Boundary

The published Omarchy AArch64 repository still returns 404. Local-source
images are complete because they embed the signed offline closure. Publishing
`pkgs.omarchy.org/{stable,edge}/aarch64` remains a production release
prerequisite; it is not a local installer blocker.
