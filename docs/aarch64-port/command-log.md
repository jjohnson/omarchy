# Quattro AArch64 UTM Command Log

This log records the commands and meaningful results from the first Quattro
AArch64 desktop milestone. Commands are run as the normal user unless a
privileged command is explicitly shown.

## 2026-08-15: Quattro release and Phase 10 controller handoff

Archived the superseded upstream reconnaissance before moving active work to
the fresh Phase 10 controller. The 2026-08-14 read-only comparison had found:

```text
repository     audit tip    upstream ref       upstream tip  commits/files since base
omarchy        998ddb78     upstream/quattro   8b70f015      276 / 561
omarchy-pkgs   6f8b660f     upstream/master    c24302e6      107 / 120
omarchy-iso    191d576f     upstream/quattro   7d3b01ea       28 / 31
```

The Omarchy audit branch overlapped that upstream in six paths:

```text
bin/omarchy-upgrade-to-quattro
default/hypr/autostart.lua
install/hardware/all.sh
install/omarchy-base.packages
install/user/mise-work.sh
test/shell.d/upgrade-to-quattro-test.sh
```

The autostart and base-package overlaps were optional SPICE extras to omit.
The upgrade command and test combined the legacy-iwd transition with
fresh-install ARM work and required fresh review rather than replay. The
remaining retained seams were current hardware orchestration and Node archive
selection. A three-way merge reported conflicts in the upgrade command, its
test, and `mise-work.sh`.

The package audit branch overlapped upstream only in
`pkgbuilds/tobi-try/PKGBUILD`; upstream independently made it architecture
neutral, so the audit branch's unrelated version change should be omitted.
The historical `upstream/add-aarch64-support` branch was already merged and
873 commits behind `upstream/master`.

The ISO audit had eight raw overlaps and four three-way conflict paths:

```text
README.md
builder/build-iso.sh
configs/airootfs/usr/share/omarchy-iso/orchestrator/phases_impl.py
configs/profiledef.sh
```

Upstream had added autoinstall, deferred provisioning, factory snapshots,
`omarchy-apply-system`, and a larger Limine pipeline. The accepted proof
commits therefore must not be cherry-picked; their architecture and boot seams
need reconstruction in current orchestration.

Omarchy v4.0.0 was released after that assessment. A 2026-08-15 Phase 8
preflight recorded:

```text
Omarchy v4.0.0 tag:             f0020448
Omarchy upstream/quattro:       b724f761
omarchy-pkgs upstream/master:   55752759
omarchy-iso upstream/quattro:   174dd82b
```

The release tag was an ancestor of `upstream/quattro`, which was also the
upstream default and contained two post-release fixes. The ISO release changed
`builder/build-iso.sh`; the package release added no audit-branch overlap. No
clean branch or worktree was created. These values are historical snapshots;
the authoritative Step 2 must fetch and recompute all three repositories.

Created `Omarchy-Phase-10-2026-08-15` as a fresh blank-disk installation from
the accepted integrated ISO, not as a Phase 8 or Phase 9 clone. Its verified
identity at handoff was:

```text
user:          dhh
architecture:  aarch64
Omarchy build: 4.0.0.r1493.g7b8e2d9
CPU / memory:  4 / 8 GiB
disk:          64 GiB, with 2 GiB ESP and 62 GiB LUKS/Btrfs root
```

The desktop, NetworkManager, SSHD, PipeWire, WirePlumber, Hyprland, and
Quickshell were active with zero failed system or user units. The active
workspace moved to `~/Projects` with clean `omarchy`, `omarchy-pkgs`, and
`omarchy-iso` clones on `quattro-aarch64-utm`. The handoff documents moved to
the VM's local `~/utm` directory over ordinary SSH; no persistent UTM share is
required.

The first optional-service test exposed a fresh-install repository defect.
Pacman configured `core`, `extra`, `alarm`, `aur`, and `omarchy`, but
`/var/lib/pacman/sync/` contained only `offline.db`.
`omarchy-install-service-tailscale` consequently could not resolve Tailscale.
Phase 8 exhibited the related stale-metadata case: its local database selected
`tailscale 1.98.10-1` after that archive left the mirror, while the live ARM
repository listed `1.102.2-1`. The product fix must preserve Arch's full-update
model; a direct package URL or partial `pacman -Sy` is not an acceptable
remedy.

## 2026-07-31: UTM media and optional host integration

Recorded the post-acceptance ownership boundary for UTM-specific behavior.
The core ISO must remain usable with a fixed guest display and no macOS
clipboard. SSH, `scp`, `rsync`, Git, and Tailscale are the normal machine
boundary; SPICE clipboard forwarding and live host-window-driven display modes
are opt-in conveniences.

UTM's running VM window exposes a removable drive-image menu even though the
configuration editor is locked. The reliable installer handoff is to put the
target disk before the ISO in boot order and eject the ISO from that live menu
before selecting the installer's final `Reboot`. The captured menu shows
`Eject` disabled only because its CD/DVD entry is already `none`.

The macOS green-button menu is also host-side. `Full Screen > Entire Screen`
places UTM in the dedicated-Space workflow; `Move & Resize`, tiling, and
full-screen placement do not directly edit the guest. With UTM Auto Resolution
enabled, a host-window change can become a new Virtio GPU preferred mode. The
Omarchy Display panel separately controls logical scale and persists the
generic monitor scale in `~/.config/hypr/monitors.lua`.

Proposed a separately named repository/AUR package with independently enabled
user services for dynamic resize and bidirectional X11/Wayland clipboard
forwarding. Its names must use an independent, collision-checked namespace
rather than `omarchy-*`. The extras must not overwrite
`monitors.lua` or replace Quickshell's Wayland clipboard history. The current
Phase 9 source still contains the proven resize helper; moving it and its
autostart out of core is a follow-up, not a retroactive change to the Phase 9
result.

Full design:
[`utm-host-integration-2026-07-31.md`](utm-host-integration-2026-07-31.md).

## 2026-07-30: Phase 9 installer acceptance

Created a separate UTM VM with a new blank disk and kept Phase 8 running as
the 2-CPU, 4 GiB controller. The install test exposed four ARM-specific
boundaries:

```text
zstd SquashFS unsupported by the Arch Linux ARM kernel
live tty1 not mapped to the Virtio GPU framebuffer
linux-aarch64 installs /boot/Image instead of a pkgbase vmlinuz
firmware serial console selected by Plymouth ahead of the GPU
```

AArch64 live images now use XZ SquashFS and map tty1 to
`virtio_gpudrmfb`. Target setup now installs a native ARM Limine updater and
pacman hook, validates real Limine 12 Linux entries, keeps resumed user
finalization from restoring offline pacman state, and adds
`plymouth.ignore-serial-consoles` for a Virtio framebuffer. Added
`spice-vdagent` to the authoritative base manifest.

Validated UTM settings:

```text
display card:    virtio-gpu-gl-pci (GPU Supported)
Auto Resolution: enabled
serial device:   attached before boot
```

After staging the exact source fixes into the stopped installation and
resuming finalization, the encrypted Btrfs target booted
`7.1.5-2-aarch64-ARCH` through native Limine. The graphical window displayed
the branded Omarchy LUKS prompt, accepted the password, and loaded the
desktop. System and user failed-unit counts were zero.

SPICE resize acceptance passed from `1280x800` to `800x600` and then
`1512x909`; DRM preferred modes and Hyprland agreed. The final full-width bar
and unclipped desktop are recorded at:

```text
~/utm/phase9-final-desktop-1512x909.png
SHA-256: 2d6d49f5b34e434ac2597d1f1938c8a898a5bd6a5e55f2c1a80469da9a7232a5
```

Created Snapper snapshot 2, `Phase 9 graphical boot acceptance`. Its Limine
entry uses `protocol: linux`, the ARM `Image` history asset, encrypted root,
`rootflags=subvol=/@/.snapshots/2/snapshot`, and
`plymouth.ignore-serial-consoles`.

Committed the target changes as `dd1c4f42` and `7b8e2d90`, and the live
installer changes as `191d576`. Focused tests, ISO architecture tests, and
the full Omarchy shell suite pass.

Built the integrated image:

```bash
cd ~/Projects/omarchy-iso-quattro-arm64
./bin/omarchy-iso-make --arch aarch64 --no-boot-offer \
  --local-source ~/Projects/omarchy-quattro-arm64 \
  ~/Projects/omarchy-pkgs-quattro-arm64
```

Read-only inspection proved ARM64 UEFI and kernel payloads, XZ SquashFS,
complete initramfs hooks and modules, byte-identical EFI copies, a passing
embedded SHA-512 self-test, 929 resolved target packages, and 1,123 matching
offline archives/database entries. The inspected source and shared copy have
the same SHA-256:

```text
~/utm/omarchy-2026.07.30-aarch64-local-phase9-integrated.iso
size:    4,617,543,680 bytes
SHA-256: 91d99878682b98b5232c7f73b4901a3f258eaecbb450e6ea1600456e8be97d88
```

A second new VM replayed the integrated artifact with 4 CPUs, 8 GiB RAM, and
a new 64 GiB disk. The live display completed its expected brief inactive,
resize, and black framebuffer handoff before loading the keyboard picker.
The installer completed in 2 minutes 33 seconds with no stop or manual
recovery.

After clearing the still-attached ISO, the installed disk booted through
Limine to the branded graphical Omarchy LUKS prompt. The password was
accepted graphically, the desktop loaded with its complete top bar, and UTM
window resizing smaller and larger adapted the desktop without clipping.

The final recovery-path test passed. The clean installation created and
listed a numbered Snapper snapshot, selected it from Limine's `Snapshots`
menu, unlocked the encrypted root through the branded graphical prompt, and
loaded the snapshot desktop. Rebooting through the normal Omarchy entry
returned to the normal root without restoring the snapshot.

Host clipboard traffic reached the active SPICE guest agent, but the agent's
X11 clipboard did not become Hyprland's Wayland selection. Quattro's Lua
clipboard bindings and Quickshell history work inside the guest; they are not
a SPICE-to-Wayland transport. Comparison with Phase 8 traced its working host
clipboard to unowned local forwarding services. The corresponding source
experiment was reverted, so the integrated candidate contains no custom
clipboard bridge. This is recorded as a Wayland/SPICE integration boundary
rather than an ARM installer failure.

Phase 9 installer acceptance is complete.

Full details are in
[`phase9-installer-acceptance-2026-07-30.md`](phase9-installer-acceptance-2026-07-30.md).

## 2026-07-30: Phase 8 first AArch64 ISO

The Phase 8 clone reproduced the Phase 7 package cache, clean pushed source
branches, 979-package proof-host state, healthy desktop, and exact protected
boot hashes.

Removed an unsafe full-build dependency on the host's global pacman cache.
The ISO entrypoint now mounts an architecture/channel-specific user cache
under `~/.cache/omarchy/` and never clears `/var/cache/pacman/pkg`. Focused
tests pass; the isolation change is pushed at `68e4bc4`.

The first full build command was:

```bash
cd ~/Projects/omarchy-iso-quattro-arm64
./bin/omarchy-iso-make --arch aarch64 --no-boot-offer \
  --local-source ~/Projects/omarchy-quattro-arm64 \
  ~/Projects/omarchy-pkgs-quattro-arm64
```

It reached mkarchiso and exposed two concrete ARM live-media issues:

```text
memdisk required unavailable phram and memdiskfind
arm64-efi GRUB lacked seven legacy keyboard/USB preload modules
```

Added an AArch64-only live-initramfs filter, made the live-root transaction
build only the Archiso `linux-aarch64` preset, and applied a build-time patch
to a temporary copy of pinned mkarchiso that omits unavailable ARM64 GRUB
modules. The Archiso submodule remains unchanged. The fix and focused tests
are pushed at `cfe5c34`.

GRUB is only the ISO's generic UEFI launcher. Target bootstrap contains
`limine` and no `grub`; the shipped installer rejects non-Limine target
bootloader setup, installs `limine_aa64.efi`, and finalizes with
`limine-update`.

Repeated the same build command. The package closure resolved to 928 target
packages, the ARM Archiso initramfs completed without an incomplete-image
error, `BOOTAA64.EFI` was created, and xorriso wrote the ISO successfully.

Inspected the artifact without booting it:

```bash
sha256sum release/omarchy-2026.07.30-aarch64-local.iso
file release/omarchy-2026.07.30-aarch64-local.iso
bsdtar -tf release/omarchy-2026.07.30-aarch64-local.iso
fdisk -l release/omarchy-2026.07.30-aarch64-local.iso
objdump -f <extracted-BOOTAA64.EFI>
lsinitcpio -a <extracted-initramfs>
docker run --rm --platform linux/arm64 \
  -v <inspection-directory>:/inspect:ro \
  menci/archlinuxarm:latest \
  <read-only SquashFS and ESP inspection>
```

Validated result:

```text
ISO size:                    4,688,142,336 bytes
ISO SHA-256:                 e579204b4c39fd36837c9a470bee4d7662bd04cda6ba39d546f46ad1fc4ca53c
EFI launcher:                PE32+ ARM64, 7,778,304 bytes
kernel:                      ARM64 Image, 7.1.5-2-aarch64-ARCH
initramfs:                   successful Archiso image, 198,966,783 bytes
live packages:               464
target install closure:      928
offline archives/DB entries: 1121/1121
Gradle runtime archives:     0
stock/T2 live kernels:       0
x86 microcode packages:      0
```

The embedded SquashFS SHA-512 self-test passed. Its initramfs contains the
Virtio GPU/network, ISO9660, SquashFS, OverlayFS, input, and storage support
needed by the UTM profile. The two ISO copies of `BOOTAA64.EFI` match and the
GPT contains a 16 MiB EFI System Partition.

Copied the ISO to the macOS/UTM share and independently verified the same
SHA-256:

```text
~/utm/omarchy-2026.07.30-aarch64-local.iso
~/utm/omarchy-2026.07.30-aarch64-local.iso.sha256
~/utm/quattro-phase8-iso-build-2.log
```

The host remained at 979 installed packages, and all four protected boot
hashes, Quickshell IPC, Hyprland, direct VirGL, failed-unit counts, and the
global pacman cache remained unchanged. The ISO was not booted in the build
VM.

Full details are in
[`phase8-first-iso-build-2026-07-30.md`](phase8-first-iso-build-2026-07-30.md).

## 2026-07-30: Phase 7 package-only closure

The Phase 7 clone reproduced the Phase 5 installed-system state and the
Phase 6 source checkpoints. All repositories began clean on their pushed
`quattro-aarch64-utm` branches.

Audited the complete fresh-image package input against synchronized Arch Linux
ARM metadata:

```bash
./bin/omarchy-iso-make --arch aarch64 --packages-only \
  --local-source ~/Projects/omarchy-quattro-arm64 \
  ~/Projects/omarchy-pkgs-quattro-arm64
```

The audit found 283 unique targets: Arch Linux ARM resolves 254 unchanged and
29 require a local recipe or provider. Added an exact 30-row build map: 29
runtime targets plus build-only Gradle. The three runtime provider mappings
are `dotnet-runtime -> dotnet-sdk-bin`, `mise -> mise-bin`, and
`obsidian -> obsidian-appimage`.

Repeated the same package-only command after each bounded retry fix. Long
native builds exposed and resolved:

```text
Gradle split archives inaccessible to the temporary repository
locale-dependent recipe fingerprints
rust versus rustup build-tool conflicts
same-version stale archives in pacman's host cache
Git safe-directory rejection on the mounted Omarchy source
```

The final run built every mapped recipe, downloaded the signed Arch Linux ARM
closure, indexed the offline repository, and exited zero:

```text
local runtime archives: 37
offline archives:       1121
offline DB entries:     1121
target install:         928 packages
Gradle in mirror:       absent
```

Validated the final repository and local artifacts:

```bash
bsdtar -tf \
  ~/.cache/omarchy/iso_edge_aarch64/airootfs/var/cache/omarchy/mirror/offline/offline.db.tar.gz
pacman -Qp <each locally built runtime archive>
bsdtar -xOf <archive> .PKGINFO
OMARCHY_PKGS_PATH=~/Projects/omarchy-pkgs-quattro-arm64 \
  ./test/architecture-test.sh
bash -n bin/omarchy-iso-make builder/architecture.sh \
  builder/build-iso.sh builder/build-omarchy-packages.sh
git diff --check
```

Database parsing proved 29/29 mapped target names resolve. All 37 local
archives are `aarch64` or `any`. Inspected the dependency metadata and
contents of `omarchy-dev`, `omarchy-settings-dev`, `omarchy-nvim`, and
`quickshell-git`.

`omarchy-nvim` logged a non-fatal failed optional Mason `stylua` download.
The package completed with the cached plugin tree and ARM64 `shfmt`; its
recipe intentionally permits best-effort headless synchronization. Record
this for first-boot Neovim acceptance rather than treating it as a closure
failure.

Rechecked the proof host after the build:

```bash
pacman -Q
pacman -Qqe
pacman -Qm
pacman -Qdtq
sha256sum /boot/initramfs-linux.img /boot/limine.conf \
  /etc/mkinitcpio.conf /etc/mkinitcpio.d/linux-aarch64.preset
systemctl --failed --no-legend
systemctl --user --failed --no-legend
omarchy-shell shell ping
hyprctl configerrors
glxinfo -B
nmcli -t -f STATE general
wpctl status
```

The host remains at 979 installed packages, 199 explicit packages, 37 foreign
packages, and zero orphans. Quickshell, Hyprland, NetworkManager, PipeWire,
and direct VirGL are healthy; all protected hashes remain exact. No ISO,
host package transaction, migration, or boot-stack change occurred.

Full details are in
[`phase7-package-closure-2026-07-30.md`](phase7-package-closure-2026-07-30.md).

## 2026-07-30: Phase 6 ISO source integration

The new Phase 6 clone reproduced the Phase 5 package, session, graphics,
network, audio, and protected-boot hashes. The source repositories were clean
at their pushed Phase 5 commits.

Read the ISO architecture plan and all relevant profile, builder, bootloader,
installer, package-list, and archiso source files:

```bash
sed -n '1,320p' plans/aarch64-support.md
rg -n '_make_packages|_make_customize_airootfs|_make_boot_on_iso9660|vmlinuz' \
  archiso/archiso/mkarchiso
sed -n '1,220p' archiso/README.rst
sed -n '1,220p' archiso/configs/releng/packages.x86_64
sed -n '1,260p' builder/build-iso.sh
sed -n '1,220p' configs/profiledef.sh
rg -n 'linux-t2|BOOTX64|limine_x64|x86_64|linux-x64' \
  bin builder configs
```

Inspected the actual Arch Linux ARM kernel and mkinitcpio contracts:

```bash
pacman -Ql linux-aarch64
sed -n '1,320p' /usr/share/libalpm/scripts/mkinitcpio
sed -n '1,160p' /etc/mkinitcpio.d/linux-aarch64.preset
file /boot/Image
mkinitcpio -k /boot/Image -M
```

Result: `linux-aarch64` installs `/boot/Image`; archiso only copies
`/boot/vmlinuz-*`. The source fix is an ARM-only profile hook that stages the
kernel and builds an archiso-specific initramfs.

Validated package, bootloader, repository, and mirror inputs:

```bash
pacman -Si linux-aarch64 linux-aarch64-headers grub limine \
  archinstall mkinitcpio-archiso
file /usr/share/limine/BOOTAA64.EFI
curl -L -sS -o /dev/null -w '%{http_code}' \
  https://ca.us.mirror.archlinuxarm.org/aarch64/core/core.db
curl -L -sS -o /dev/null -w '%{http_code}' \
  https://pkgs.omarchy.org/edge/aarch64
```

The Arch Linux ARM mirror returned 200. The Omarchy AArch64 repository
returned 404.

Generated the ARM releng package list without building an ISO and resolved
every entry against the actual repositories:

```bash
source builder/architecture.sh
omarchy_iso_prepare_package_list aarch64 \
  archiso/configs/releng/packages.x86_64 \
  <temporary-directory>/packages.aarch64 \
  builder/releng-aarch64-exclude.packages
pacman -Si <each generated package>
```

Result: 116 of 116 packages resolve. The target bootstrap list maps to
`linux-aarch64` and drops both x86 microcode packages.

After source changes, ran:

```bash
bash -n <all changed Bash files>
python -m py_compile <changed installer Python files>
./test/architecture-test.sh
./test/shell.d/pacman-config-test.sh
./test/shell.d/mise-work-architecture-test.sh
OMARCHY_PKGS_PATH=~/Projects/omarchy-pkgs-quattro-arm64 \
OMARCHY_ISO_PATH=~/Projects/omarchy-iso-quattro-arm64 \
  ./test/shell
git diff --check
```

All listed checks passed. `./test/cli` still reports the pre-existing missing
metadata summary on unchanged
`omarchy-update-system-pkgs-when-conflicted`. `shellcheck` is not installed.

No ISO build, package transaction, migration, or installed boot-stack change
was performed. Full details are in
[`phase6-iso-source-integration-2026-07-30.md`](phase6-iso-source-integration-2026-07-30.md).

## 2026-07-29: Prior-session baseline

Read the complete validated 3.x UTM procedure before inspecting or changing the
guest:

```bash
sed -n '1,240p' ~/utm/arm64-utm-3x-happy-path.md
sed -n '241,520p' ~/utm/arm64-utm-3x-happy-path.md
```

Result: confirmed the known-good Archboot, Btrfs, Limine, VirGL, Hyprland,
SPICE, clipboard, resize, and audio baseline. Confirmed that the old Armarchy
source is reference material only.

## 2026-07-29: System and package capture

Read-only inventory commands:

```bash
date --iso-8601=seconds
uname -a
uname -m
uname -r
uname -v
hostnamectl
systemd-detect-virt
lscpu
inxi -Fxxxz --no-host
findmnt -no SOURCE,FSTYPE,OPTIONS /
findmnt -R /boot
df -hT / /home /boot
free -h
lsblk -o NAME,PATH,SIZE,TYPE,FSTYPE,FSVER,MOUNTPOINTS,UUID,PARTUUID
```

Package inventory and kernel mapping commands:

```bash
pacman -Q
pacman -Qqe
pacman -Qm
pacman -Qdtq
pacman -Q linux-aarch64-headers
pacman -Si linux linux-headers linux-aarch64 linux-aarch64-headers
pacman -Qi linux-aarch64 limine limine-mkinitcpio-hook mkinitcpio hyprland
pacman -Qk linux-aarch64 limine limine-mkinitcpio-hook mkinitcpio
pacman -Qo /boot/* /etc/mkinitcpio.d/*
```

Boot and initramfs inspection:

```bash
efibootmgr -v
ls -la /etc/mkinitcpio.d /boot
ls -l /usr/lib/modules
sed -n '1,200p' /etc/mkinitcpio.d/linux-aarch64.preset
sed -n '1,200p' /etc/mkinitcpio.conf
sha256sum /etc/pacman.conf /etc/pacman.d/mirrorlist \
  /etc/pacman.d/mirrorlist.asahi-alarm /etc/mkinitcpio.conf \
  /etc/mkinitcpio.d/linux-aarch64.preset /boot/limine.conf
```

Repository inspection:

```bash
pacman-conf --repo-list
pacman-conf --repo core
pacman-conf --repo extra
pacman-conf --repo alarm
pacman-conf --repo aur
pacman-conf --repo asahi-alarm
sed -n '/^[[:space:]]*\[[^]]*\]/p; \
  /^[[:space:]]*Include[[:space:]]*=/p; \
  /^[[:space:]]*Server[[:space:]]*=/p' /etc/pacman.conf
sed -n '1,120p' /etc/pacman.d/mirrorlist
sed -n '1,160p' /etc/pacman.d/mirrorlist.asahi-alarm
```

Graphics and session inspection:

```bash
lspci -nnk
glxinfo -B
hyprctl version
hyprctl monitors
hyprctl configerrors
env | rg \
  '^(DISPLAY|WAYLAND_DISPLAY|XDG_CURRENT_DESKTOP|XDG_SESSION_DESKTOP|XDG_SESSION_TYPE|WLR_RENDERER|LIBGL_ALWAYS_SOFTWARE|AQ_)=' |
  sort
systemctl --failed --no-legend
systemctl --user --failed --no-legend
```

Results are summarized in
[`baseline-2026-07-29.md`](baseline-2026-07-29.md). No package database,
package, service, boot, kernel, filesystem, or configuration state was changed.

The baseline was committed atomically:

```bash
git add docs/aarch64-port/baseline-2026-07-29.md \
  docs/aarch64-port/installed-packages-2026-07-29.txt \
  docs/aarch64-port/command-log.md
git commit -m "Document ARM64 UTM baseline"
```

## 2026-07-29: Repository pinning

The existing Omarchy worktree was already on the dedicated
`quattro-aarch64-utm` branch. It was updated from the current Quattro source
tip without modifying the upstream branch:

```bash
git fetch upstream quattro
git fetch origin
git rebase upstream/quattro
```

The other repositories were cloned into separate worktrees:

```bash
git clone https://github.com/omacom-io/omarchy-pkgs.git \
  ~/Projects/omarchy-pkgs-quattro-arm64
git clone --branch quattro --single-branch \
  https://github.com/omacom-io/omarchy-iso.git \
  ~/Projects/omarchy-iso-quattro-arm64
```

Repository-local instruction discovery:

```bash
rg --files -g AGENTS.md
```

The Omarchy root `AGENTS.md` was read completely. No `AGENTS.md` exists in
either newly cloned repository at the pinned revisions.

Created the same isolated branch in each new worktree:

```bash
git switch -c quattro-aarch64-utm
```

Exact commits and worktree paths are recorded in
[`repositories.md`](repositories.md).

## 2026-07-29: Hard dependency audit

Read the existing ISO architecture plan and inspected all relevant PKGBUILDs:

```bash
sed -n '1,360p' plans/aarch64-support.md
sed -n '1,280p' pkgbuilds/omarchy-dev/PKGBUILD
sed -n '1,320p' pkgbuilds/omarchy-settings-dev/PKGBUILD
sed -n '1,320p' pkgbuilds/omarchy-keyring/PKGBUILD
sed -n '1,320p' pkgbuilds/limine-mkinitcpio-hook/PKGBUILD
sed -n '1,320p' pkgbuilds/limine-snapper-sync/PKGBUILD
sed -n '1,320p' pkgbuilds/ttf-jetbrains-mono-nerd-basic/PKGBUILD
sed -n '1,320p' pkgbuilds/quickshell-git/PKGBUILD
```

Validated PKGBUILD syntax and normalized metadata without building:

```bash
bash -n PKGBUILD
makepkg --printsrcinfo
```

Queried synchronized Arch Linux ARM metadata and candidate package URLs:

```bash
expac -S '%r|%n|%v|%a|%D|%P' <dependency names>
pacman -Si <dependency names>
pacman -Sddp --print-format '%r|%n|%v|%a|%l' <dependency name>
pacman -T <all direct runtime dependencies>
```

Rechecked the published Omarchy ARM repositories:

```bash
curl -L -sS -o /dev/null -w '%{http_code}' \
  https://pkgs.omarchy.org/edge/aarch64/omarchy.db
curl -L -sS -o /dev/null -w '%{http_code}' \
  https://pkgs.omarchy.org/stable/aarch64/omarchy.db
```

Both returned HTTP 404. The complete categorized result is in
[`dependency-audit.md`](dependency-audit.md).

## 2026-07-29: Native AArch64 package builds

The first clean-container build exposed a transitive build dependency that was
not visible in the direct dev-package matrix:

```bash
./bin/repo build --arch aarch64 --package \
  omarchy-keyring omarchy-settings-dev limine-snapper-sync \
  ttf-jetbrains-mono-nerd-basic quickshell-git omarchy-dev
```

`limine-mkinitcpio-hook` and `limine-snapper-sync` require `gradle`, which is
not published in the Arch Linux ARM repositories. The AUR recipe was inspected
and rejected because it is still Gradle 2.6. The current official Arch package
recipe was cloned and pinned:

```bash
git clone \
  https://gitlab.archlinux.org/archlinux/packaging/packages/gradle.git \
  ~/Projects/gradle-arch-package-arm64
git -C ~/Projects/gradle-arch-package-arm64 rev-parse HEAD
```

Result:

```text
65fdb1b6b29b8966bb340a2c919e131cded3b53a
```

The recipe was added to the package repository as an AArch64-only local
package and committed atomically:

```bash
git commit -m "Build Gradle for aarch64"
```

Package repository commit: `c2a36d3`.

The bootstrap and both Limine packages then built in dependency order:

```bash
./bin/repo build --arch aarch64 --package \
  gradle limine-mkinitcpio-hook limine-snapper-sync
```

Results:

- Gradle 9.6.1 completed 3,342 source-build tasks natively in 10m57s.
- `limine-mkinitcpio-hook 1.37.1-1` built a 64-bit AArch64 GraalVM image.
- `limine-snapper-sync 1.31.0-1` built a 64-bit AArch64 GraalVM image.
- All three packages completed successfully.

The Omarchy dev packages were built from the exact local development checkout,
not the moving upstream `quattro` branch:

```bash
cd ~/Projects/omarchy-pkgs-quattro-arm64/pkgbuilds/omarchy-settings-dev
OMARCHY_SRC=~/Projects/omarchy-quattro-arm64 \
  makepkg --cleanbuild --force --nodeps --noconfirm

cd ~/Projects/omarchy-pkgs-quattro-arm64/pkgbuilds/omarchy-dev
OMARCHY_SRC=~/Projects/omarchy-quattro-arm64 \
  makepkg --cleanbuild --force --nodeps --noconfirm
```

Both packages identify source SHA
`4f61400b949bf0d0ee9375cce38ababe95b4f7a8` in their version:

```text
omarchy-settings-dev 4.0.0.r1466.g4f61400-1
omarchy-dev          4.0.0.r1466.g4f61400-1
```

The settings build reports three pre-existing backup-array warnings for paths
that are no longer present in the package. They do not affect the produced
payload:

```text
etc/systemd/zram-generator.conf
etc/udev/rules.d/99-omarchy-power-profile.rules
etc/udev/rules.d/99-omarchy-wifi-powersave.rules
```

The final keyring, font, and pinned Quickshell batch was built with:

```bash
./bin/repo build --arch aarch64 --package \
  omarchy-keyring ttf-jetbrains-mono-nerd-basic quickshell-git
```

All three succeeded. Quickshell compiled all 1,321 targets natively and
produced `quickshell-git 0.3.0.r18.g10b439f-3` for AArch64.

## 2026-07-29: Package inspection and transaction resolution

The local repository database contains these runtime candidates:

```text
limine-mkinitcpio-hook 1.37.1-1 aarch64
limine-snapper-sync 1.31.0-1 aarch64
omarchy-dev 4.0.0.r1466.g4f61400-1 any
omarchy-keyring 20251027-1 any
omarchy-settings-dev 4.0.0.r1466.g4f61400-1 any
quickshell-git 0.3.0.r18.g10b439f-3 aarch64
ttf-jetbrains-mono-nerd-basic 3.4.0-1 any
```

Gradle 9.6.1-1.1 is also retained in the local repository as a build-only
AArch64 package.

Inspection commands:

```bash
bsdtar -xOf <package> .PKGINFO
bsdtar -tf <package>
file <extracted ELF>
readelf -h <extracted ELF>
ldd <extracted ELF>
pacman -U --noconfirm --print-format '%r\t%n\t%v\t%l' <runtime packages>
```

Quickshell, `limine-entry-tool`, and `limine-snapper-sync` are all ELF64
little-endian AArch64 PIE executables. The dry transaction selected the six
local runtime packages and four official Arch Linux ARM dependencies:
`libdwarf`, `cpptrace`, `vulkan-headers`, and `pacman-contrib`.

## 2026-07-29: Guarded package installation

Backed up the boot/config files and user state that could be affected:

```bash
pkexec <scoped backup and pacman transaction helper>
tar -cf \
  ~/Projects/omarchy-pkgs-quattro-arm64/build-output/pre-finalize-user-2026-07-29.tar \
  <existing user state paths>
```

The first installation attempt stopped before changing packages because 13
legacy unowned files overlapped `omarchy-settings-dev`. After comparing those
files with the package payload, the final transaction used exact
`--overwrite` arguments for those paths only:

```bash
pkexec \
  ~/Projects/omarchy-pkgs-quattro-arm64/build-output/install-aarch64-runtime.sh
```

The local packages and their four official runtime dependencies installed
successfully. `limine-mkinitcpio-hook` was already installed at the required
version and was not reinstalled.

Verified the guarded state immediately after the transaction:

```bash
pacman -Q <runtime package names>
pacman -Qk <runtime package names>
sha256sum /boot/initramfs-linux.img /boot/limine.conf \
  /etc/mkinitcpio.conf /etc/mkinitcpio.d/linux-aarch64.preset
hyprctl configerrors
glxinfo -B
```

All four boot/initramfs hashes match the pre-install baseline exactly.

## 2026-07-29: Quattro user finalization

Finalized the existing user against the packaged Quattro tree:

```bash
env OMARCHY_PATH=/usr/share/omarchy \
  OMARCHY_INSTALL=/usr/share/omarchy/install \
  OMARCHY_SETUP_CONTEXT=runtime \
  PATH=/usr/bin:/bin \
  /usr/bin/omarchy-finalize-user --force
```

The command completed successfully. `omarchy-reinstall-configs` and the broad
`omarchy-upgrade-to-quattro` transition were not run because they exceed the
boot/config scope of this milestone.

## 2026-07-29: Quickshell launch diagnosis

The first foreground and generic transient-service launches loaded the full
QML tree, then received `SIGTERM`. The shell was relaunched under the same UWSM
application management used by the real desktop:

```bash
uwsm-app -s b -t service \
  -u omarchy-quattro-shell-test.service \
  -p "Environment=OMARCHY_PATH=/usr/share/omarchy" \
  -- quickshell -n -p /usr/share/omarchy/shell
```

The process remained active when given the legacy empty plugin path, but exited
after loading Quattro's Indicators widget. Temporary manifest and indicator
probes narrowed the behavior without changing either source checkout or user
configuration.

GDB captured the actual termination:

```bash
uwsm-app -s b -t service \
  -u omarchy-quattro-shell-gdb.service \
  -p "Environment=OMARCHY_PATH=/usr/share/omarchy" \
  -- gdb -batch -ex run -ex "thread apply all bt" \
  --args /usr/bin/quickshell -p /usr/share/omarchy/shell
```

Result: the main Quickshell thread received external `SIGTERM`; there was no
crash or QML fatal error. The current UWSM manager still had this 3.x
environment:

```text
OMARCHY_PATH=~/.local/share/omarchy
PATH=...:$HOME/.local/share/omarchy/bin:...:/usr/bin:...
```

The Indicators widget consequently ran the legacy
`omarchy-voxtype-status`, whose `trap 'kill 0' EXIT` killed the entire process
group when `voxtype` was absent. The packaged Quattro command has no such trap.

The stable launch command therefore pins both runtime variables:

```bash
uwsm-app -s b -t service \
  -u omarchy-quattro-shell-runtime.service \
  -d "Quattro shell ARM64 runtime validation" \
  -p "Environment=OMARCHY_PATH=/usr/share/omarchy" \
  -p "Environment=PATH=/usr/bin:/bin" \
  -- quickshell -n -p /usr/share/omarchy/shell
```

IPC returned `ok`; 34 first-party plugins were registered and 27 enabled.

## 2026-07-29: Desktop acceptance

Stopped the exact legacy Waybar, Mako, swaybg, and Walker user units, then the
exact legacy polkit-agent PID. Restarted Quickshell so it could own
notifications and polkit from startup. No broad process-kill command was used.

Installed two small signed AArch64 packages from the Quattro base set:

```bash
pkexec pacman -S --noconfirm --needed inotify-tools wtype
```

Restarted Quickshell and confirmed `inotifywait` was watching
`~/.config/omarchy/plugins`.

Verified the shipped Lua configuration without overwriting the live 3.x user
configuration:

```bash
verify_home=$(mktemp -d /tmp/omarchy-quattro-hypr-verify.XXXXXX)
mkdir -p "$verify_home/.config"
cp -a /usr/share/omarchy/config/hypr "$verify_home/.config/"
env HOME="$verify_home" \
  XDG_CONFIG_HOME="$verify_home/.config" \
  OMARCHY_PATH=/usr/share/omarchy \
  PATH=/usr/bin:/bin \
  Hyprland --verify-config \
  --config "$verify_home/.config/hypr/hyprland.lua"
```

Result: `config ok`.

Exercised shell IPC, keyboard selection, terminal launch, workspaces, graphics,
audio, clipboard, SPICE, and notifications:

```bash
env OMARCHY_PATH=/usr/share/omarchy PATH=/usr/bin:/bin \
  omarchy-shell shell ping
env OMARCHY_PATH=/usr/share/omarchy PATH=/usr/bin:/bin \
  omarchy menu summon apps
wtype -d 40 "Alacritty"
wtype -k Return
hyprctl dispatch workspace 3
hyprctl dispatch workspace 2
glxinfo -B
wpctl status
timeout 3 speaker-test -D pipewire -c 2 -t sine -f 440 -l 1
wl-copy
wl-paste
omarchy-notification-send -g "✓" \
  "Quattro ARM64" "Quickshell notification path is live"
```

Captured each visually distinct state with:

```bash
env OMARCHY_PATH=/usr/share/omarchy PATH=/usr/bin:/bin \
  omarchy capture screenshot fullscreen save
```

The complete result, screenshot paths, remaining host/base-set differences,
and final integrity hashes are recorded in
[`desktop-validation-2026-07-29.md`](desktop-validation-2026-07-29.md).

Before privileged installation, recoverable copies of the current initramfs,
Limine configuration, mkinitcpio configuration and preset, and every file
overwritten by the settings package scriptlet were placed under:

```text
~/Projects/omarchy-pkgs-quattro-arm64/build-output/pre-install-system-2026-07-29/
```

## 2026-07-30: Persistent session cutover preparation

Verified the post-checkpoint reboot, exact boot hashes, installed packages,
remote Git branch parity, active session environment, and current UI services.
The system returned to the expected 3.x login environment with no failed
units.

Archived the user state that the cutover could affect:

```bash
tar -C ~ -cpf \
  ~/Projects/omarchy-pkgs-quattro-arm64/build-output/pre-persistent-cutover-2026-07-30-002942.tar \
  .bashrc .bash_profile .config/hypr .config/uwsm .config/omarchy \
  .config/autostart .config/systemd/user .local/state/omarchy
```

The archive SHA-256 is:

```text
a12466e3e292a4f3b2b9ddf6f51b1c6b2ca78f33b408a02f99793cbc5198f2c5
```

Suppressed live Hyprland autoreload, installed the previously absent Quattro
Lua entrypoints, and verified the new config explicitly:

```bash
hyprctl keyword misc:disable_autoreload true
env OMARCHY_PATH=/usr/share/omarchy PATH=/usr/bin:/bin \
  omarchy-refresh-hyprland
env HOME="$HOME" OMARCHY_PATH=/usr/share/omarchy PATH=/usr/bin:/bin \
  Hyprland --verify-config --config ~/.config/hypr/hyprland.lua
hyprctl keyword misc:disable_autoreload false
```

Result: `config ok`. No existing Lua user file was replaced, and the legacy
`*.conf` tree was preserved.

Moved the exact known-default legacy UWSM environment, Walker autostart, and
retired user services to:

```text
~/.local/state/omarchy/cutover-backups/2026-07-30-002942/
```

Updated `.bashrc` to load the package-backed Quattro runtime while preserving
the VM-specific alias. Enabled the package-backed internal-monitor recovery
and sleep-lock units. No legacy package was removed before the persistent
login test.

Started the Quattro shell with explicit live-session environment overrides,
waited for IPC, stopped the exact legacy UI process IDs, and restarted the
shell after handoff:

```bash
uwsm-app -s b -t service \
  -u omarchy-quattro-shell-runtime.service \
  -d "Quattro shell ARM64 persistent-cutover validation" \
  -p "Environment=OMARCHY_PATH=/usr/share/omarchy" \
  -p "Environment=PATH=/usr/bin:/bin" \
  -- quickshell -n -p /usr/share/omarchy/shell
systemctl --user restart omarchy-quattro-shell-runtime.service
```

Re-ran menu, keyboard terminal launch, notifications, workspaces, VirGL,
software-rendering override, audio, clipboard, SPICE, failed-unit, visual, and
boot-hash checks. The detailed result and rollback instructions are in
[`persistent-cutover-2026-07-30.md`](persistent-cutover-2026-07-30.md).

## 2026-07-30: Persistent Quattro proof boot

Verified that the new login selected Quattro rather than returning to the
mixed 3.x session:

```bash
systemctl --user show-environment
ps -eo pid,ppid,stat,comm,args
hyprctl configerrors
rg 'Using config|Lua config' /run/user/1000/hypr/*/hyprland.log
omarchy-shell shell ping
```

Hyprland loaded `~/.config/hypr/hyprland.lua`, UWSM exported
`OMARCHY_PATH=/usr/share/omarchy`, and Quickshell started directly as a
Hyprland child. The previous transient validation service was absent and no
legacy UI process returned.

Inspected the user-supplied notification image at:

```text
~/utm/quattro-desktop-notifications.png
```

The notification layout was visually clean, but Quattro autostart reported
that `udiskie` was missing. Installed the unchanged signed Arch Linux ARM
package and its three missing dependencies:

```bash
pkexec pacman -S --noconfirm --needed udiskie
```

Verified the package with `pacman -Qk`, relaunched the exact autostart command
through Hyprland/UWSM, and confirmed the process remained active.

Restarted the persistent shell through the normal user command:

```bash
omarchy restart shell
```

The replacement process remained a Hyprland child, reclaimed notifications,
and returned `ok` from IPC without temporary environment overrides.

Audited the 46 pending Quattro migrations but did not run or fake-complete
them. Runtime finalization intentionally does not stamp migrations for an
existing user, and the queue includes NetworkManager migration plus
conditional initramfs/Limine rebuilds. Those operations belong to a later
system-integration phase and exceed this milestone's no-boot-change boundary.

Repeated Lua config reload, menu, keyboard terminal launch, notification,
workspace, VirGL, software-rendering override, audio, clipboard, SPICE,
failed-unit, visual, and boot-hash checks. With Lua active, workspace IPC used:

```bash
hyprctl dispatch 'hl.dsp.focus({ workspace = "3" })'
```

The complete proof-boot result is recorded in
[`persistent-session-proof-2026-07-30.md`](persistent-session-proof-2026-07-30.md).

## 2026-07-30: SPICE dynamic-resize recovery

A manual host resize changed the UTM window briefly and then snapped back.
Captured the DRM connector and Hyprland monitor state at 100 ms intervals:

```text
01:27:22.613 kernel=800x600  hypr=1280x800
01:27:28.860 kernel=1280x800 hypr=1280x800
```

`spice-vdagent` logged failed XRandR operations and restored the previous
configuration. The existing `omarchy-hyprland-monitor-watch` process was
excluded as the cause because its source only reacts to added/removed outputs
and clamshell state.

Proved the mode itself was valid with a reversible Hyprland Lua update, then
captured a nonstandard `1512x909` UTM request and applied it while the connector
still advertised it:

```bash
hyprctl eval \
  'hl.monitor({ output = "Virtual-1", mode = "1512x909@60", position = "auto", scale = 1 })'
```

The connector and compositor remained at `1512x909` for the complete trace,
past the previous six-second rollback window.

Added an internal `omarchy-hyprland-spice-resize` helper and normal Quattro
autostart entry. The helper is gated on the SPICE virtio port and a DRM card
bound to `virtio_gpu`, listens to DRM kernel events, and preserves active
monitor position and scale. Added focused shell coverage for changed,
unchanged, unsupported, and disconnected states.

Validation:

```bash
bash -n \
  bin/omarchy-hyprland-spice-resize \
  test/shell.d/monitor-spice-resize-test.sh
./test/shell.d/monitor-spice-resize-test.sh
./test/shell.d/monitor-recovery-test.sh
OMARCHY_PKGS_PATH=~/Projects/omarchy-pkgs-quattro-arm64 ./test/shell
```

The focused tests passed. The aggregate shell suite passed the new monitor
test and later reported the existing sleep-lock timing-budget failure.

Committed and pushed the implementation:

```text
227b6e0ec245ecdf0d8175aa05be5e03d0e36b61
Follow SPICE virtio display resizes
```

Built both owning packages from that exact local commit with
`OMARCHY_SRC=~/Projects/omarchy-quattro-arm64`:

```text
omarchy-dev-4.0.0.r1471.g227b6e0-1-any.pkg.tar.xz
SHA-256: 3ceee4ed42b2997076c9f8edc2c056f2e93d112242aca23a86d469270007f353

omarchy-settings-dev-4.0.0.r1471.g227b6e0-1-any.pkg.tar.xz
SHA-256: aa2c5cc80b0d0bffd599b215137bdf44ccec82648483c3efb80b68cca42c2c2f
```

Inspected `.PKGINFO`, dependency resolution, file modes, and the exact helper
and autostart payloads before installing both packages in one local pacman
transaction. There were no unresolved dependencies. The settings package
reported its three pre-existing backup-array warnings during build.

Stopped the checkout-launched helper and started the installed command through
Hyprland/UWSM:

```text
/bin/bash /usr/bin/omarchy-hyprland-spice-resize
app-Hyprland-omarchy-hyprland-spice-resize-*.scope
```

The installed package handled another manual UTM resize. Eight seconds later,
both the connector and Hyprland remained at `800x600`; no new SPICE restore
event occurred. Quickshell IPC, empty Hyprland config errors, VirGL, and the
absence of a software-rendering override were rechecked.

The protected hashes remained unchanged:

```text
2662962bab816958bad80f3c24e275f2e306b984bdf1f81dc235342382c8048f  /boot/initramfs-linux.img
add658562939b9abb73bf6fe7865fb177cd8fbfa5a73479467cf3469da57ac44  /boot/limine.conf
6edf91b6ee62aff521de9666d6f8c790be086ecec48352f2dd580d66a6831dd3  /etc/mkinitcpio.conf
a0bf23d62d7d74bfa597e38af7cc841837ba4a353ed8f8b10b5dd3a69dab5814  /etc/mkinitcpio.d/linux-aarch64.preset
```

## 2026-07-30: Resize-helper persistence boot

After the powered-off pre-reboot safety checkpoint, booted the original VM and
verified the complete package-backed session again. The boot began at
`2026-07-30 01:48:02 EDT`.

Normal Quattro autostart launched exactly one resize helper as a direct child
of Hyprland:

```text
Hyprland PID 1104
resize helper PID 1183, parent 1104
/bin/bash /usr/share/omarchy/bin/omarchy-hyprland-spice-resize
```

The running command came from the packaged `/usr/share/omarchy/bin` symlink,
not the source checkout or a temporary service. The matching UWSM scope was
active.

Rechecked:

```bash
uname -a
uptime -s
pacman -Q omarchy-dev omarchy-settings-dev udiskie hyprland \
  quickshell-git spice-vdagent
systemctl --user show-environment
hyprctl configerrors
omarchy-shell shell ping
glxinfo -B
systemctl --failed --no-legend
systemctl --user --failed --no-legend
```

Hyprland again selected `~/.config/hypr/hyprland.lua`, Quickshell owned
notifications and returned `ok`, VirGL remained direct, both SPICE services
were active, and there were zero failed units.

Armed a 100 ms connector/compositor trace and performed the final manual UTM
resize:

```text
01:49:56.604 kernel=800x600  hypr=1376x909
01:49:56.713 kernel=800x600  hypr=800x600
01:50:19.340 kernel=1512x909 hypr=1512x909
```

The installed helper synchronized the first transition in approximately
109 ms; the second was synchronized by the next sample. The final size stayed
at `1512x909`.

`spice-vdagent` still emitted its known XRandR failure and
`Restoring previous config` warning. The warning no longer described the
resulting display state: neither the connector nor Hyprland reverted, and the
UTM window remained at the requested size.

The protected hashes remained exact after this second proof boot and resize:

```text
2662962bab816958bad80f3c24e275f2e306b984bdf1f81dc235342382c8048f  /boot/initramfs-linux.img
add658562939b9abb73bf6fe7865fb177cd8fbfa5a73479467cf3469da57ac44  /boot/limine.conf
6edf91b6ee62aff521de9666d6f8c790be086ecec48352f2dd580d66a6831dd3  /etc/mkinitcpio.conf
a0bf23d62d7d74bfa597e38af7cc841837ba4a353ed8f8b10b5dd3a69dab5814  /etc/mkinitcpio.d/linux-aarch64.preset
```

## 2026-07-30: Phase 2 working-clone audit

The powered-off gold VM was duplicated as:

```text
Quattro-ARM64-Phase-2-Working-2026-07-30
```

The clone booted at `2026-07-30 02:06:16 EDT`. Repeated the package-backed
desktop, repository, graphics, service, display, and protected-hash checks.
The clone exactly inherited the gold state.

Inspected the current network stack:

```bash
ip -brief link
ip -brief address
ip route
networkctl status enp0s1
resolvectl status enp0s1
systemctl is-enabled systemd-networkd.service systemd-resolved.service \
  iwd.service NetworkManager.service
systemctl is-active systemd-networkd.service systemd-resolved.service \
  iwd.service NetworkManager.service
```

Result: Archboot's
`/etc/systemd/network/enp0s1-ethernet.network` supplied DHCP through active
networkd; systemd-resolved supplied DNS; iwd was active; NetworkManager was
not installed.

Read the complete NetworkManager migration and fresh-install service setup:

```bash
sed -n '1,280p' migrations/1782002156.sh
sed -n '1,260p' install/hardware/network.sh
sed -n '1,220p' install/config/enable-services.sh
sed -n '1,360p' bin/omarchy-migrate
```

The migration runner has no supported single-migration mode. The complete
46-item queue was therefore left pending. Migrations `1784476564.sh`,
`1784917531.sh`, and `1785273276.sh` were explicitly excluded because they can
modify the initramfs or Limine-managed boot image.

Audited the full 143-entry base manifest with a provider-aware `pacman -T`
transaction. Installed packages and providers satisfy 122 entries. Of the 21
remaining names, nine are available unchanged from Arch Linux ARM, eight have
Omarchy recipes, three have direct name or upstream packaging alternatives,
and the remaining optional OBS application needs ARM recipe work. The
per-package matrix is in `dependency-audit.md`.

## 2026-07-30: NetworkManager recovery preparation

Archived the exact pre-cutover configuration and unit symlinks:

```text
~/.local/state/omarchy/phase2-network-backup-20260730-021354/system-network-state.tar
SHA-256: 2aa6f88a1eccfde208a0050046c5f7b758a3b16428a65ed2be2878ee54e2e5ec
```

Created and syntax-checked the root rollback command:

```text
~/.local/state/omarchy/phase2-network-backup-20260730-021354/rollback-to-networkd
SHA-256: 0bfd3385d18d58064b6d5f370af1fa232e429ca24b2d945b5b20642b386e9c99
```

The rollback can be invoked from a local terminal or TTY with:

```bash
pkexec \
  ~/.local/state/omarchy/phase2-network-backup-20260730-021354/rollback-to-networkd
```

Updated `~/utm/QUATTRO-ARM64-RECOVERY-PROMPT.md` with the working clone,
archive, rollback command, and migration exclusions before changing a system
package or service.

## 2026-07-30: Controlled NetworkManager cutover

Inspected the signed transaction, then installed NetworkManager without
enabling it:

```bash
pacman -Sp --print-format '%n %v %a %l' networkmanager
pkexec pacman -S --noconfirm --needed networkmanager
```

The 12-package transaction came entirely from Arch Linux ARM `core` and
`extra`. `pacman -Qk` reported zero missing files for NetworkManager, libnm,
and wpa_supplicant. Networkd remained active and connectivity remained healthy
after package installation.

Started NetworkManager alongside networkd:

```bash
pkexec systemctl enable --now NetworkManager.service
nmcli general status
nmcli -f DEVICE,TYPE,STATE,CONNECTION device status
nmcli -f GENERAL,IP4,IP6 device show enp0s1
```

NetworkManager detected `virtio_net`, created `Wired connection 1`, and
obtained `192.168.64.4/24` while networkd temporarily retained
`192.168.64.3/24`.

The first transition used a three-minute systemd rollback timer. NetworkManager
remained healthy, but the timer expired before the next validation turn and
correctly restored networkd. The journal proves that this was the scheduled
rollback, not a service failure.

Repeated the transition with the validated atomic command:

```text
~/.local/state/omarchy/phase2-network-backup-20260730-021354/cutover-to-networkmanager
SHA-256: 7bb9bdb13922ad95ad4178e187edc0998e57cbdba3c862c9eb0c5c3c4b875f2f
```

It armed a ten-minute independent rollback, stopped and disabled the five
networkd units from the Quattro migration, masked both wait-online services,
reloaded NetworkManager, restarted resolved, and required NetworkManager state
100, a default route, DNS resolution, and HTTPS. It canceled the timer after
every assertion passed.

Post-cutover validation:

```text
NetworkManager: enabled, active, full connectivity
enp0s1:         192.168.64.4/24
gateway:        192.168.64.1
networkd:       disabled, inactive
resolved:       enabled, active
rollback timer: absent
```

Restarted the single shell through:

```bash
omarchy restart shell
omarchy-shell shell summon omarchy.network
omarchy capture screenshot fullscreen save
omarchy-shell shell hide omarchy.network
```

The replacement Quickshell process returned `ok` and logged no warnings. The
network panel screenshot was visually inspected at:

```text
~/Pictures/screenshot-2026-07-30_02-28-47.png
```

It showed the active Ethernet address and gateway, traffic, latency, packet
loss, totals, and DNS controls without clipping or stale state.

Hyprland configuration, the SPICE resize helper, direct VirGL, display mode,
failed-unit counts, pending-migration count, and protected hashes were
rechecked. All passed; the queue remained at 46 and the boot hashes remained
exact. The complete live result and reboot proof are in
`phase2-networkmanager-2026-07-30.md`.

## 2026-07-30: NetworkManager persistence boot

Rebooted only the Phase 2 working clone. The new boot began at
`2026-07-30 02:37:20 EDT`.

Validated service ownership before making any change:

```bash
systemctl is-enabled NetworkManager.service systemd-networkd.service
systemctl is-active NetworkManager.service systemd-networkd.service \
  systemd-resolved.service
nmcli general status
nmcli -f DEVICE,TYPE,STATE,CONNECTION device status
nmcli -f GENERAL,IP4,IP6 device show enp0s1
journalctl -b -u NetworkManager.service -u systemd-resolved.service \
  -p warning..alert
journalctl -b -u systemd-networkd.service
```

NetworkManager returned enabled and active, while networkd and all five
networkd sockets remained disabled and inactive. The disabled network
generator was also inactive after reboot. The networkd current-boot journal
was empty.

`Wired connection 1` returned with UUID
`4febe398-240f-3ea4-9ecf-64c61a0411f8`, NetworkManager state 100, full IPv4
and IPv6 connectivity, `192.168.64.4/24`, gateway `192.168.64.1`, and resolved
DNS. A DNS lookup and HTTPS request to `archlinux.org` passed. NetworkManager
and resolved had no current-boot warnings.

Revalidated the complete desktop:

```bash
systemctl --user show-environment
omarchy-shell shell ping
hyprctl configerrors
hyprctl -j monitors
glxinfo -B
systemctl is-active spice-vdagentd.service
systemctl --user is-active spice-vdagent.service
systemctl --user is-active pipewire.service pipewire-pulse.service \
  wireplumber.service
systemctl --failed --no-legend
systemctl --user --failed --no-legend
```

Quickshell, Hyprland, the package-owned resize helper, both SPICE agents, and
the audio services returned normally. Shell IPC was `ok`, Hyprland errors were
empty, no legacy shell process returned, VirGL remained direct, and there were
zero failed units.

Summoned and visually inspected the post-reboot network panel:

```text
~/Pictures/screenshot-2026-07-30_02-38-48.png
```

The panel showed the active `.4` address, `.1` gateway, traffic, 12 ms latency,
zero packet loss, totals, and DNS controls without clipping, stale state, or
Quickshell warnings.

Performed a final manual host-driven UTM resize. The requested `800x600` size
stayed put. The DRM connector and Hyprland agreed after the rollback window:

```text
kernel preferred: 800x600
Hyprland active:   800x600@60.317, scale 1
```

The known `spice-vdagent` XRandR failure and `Restoring previous config`
warning appeared, but the connector, compositor, and UTM window did not
revert.

The migration queue remained at 46, no rollback timer existed, and all four
protected hashes remained exact. This completed the isolated NetworkManager
persistence phase without running a migration or touching the boot stack.

## 2026-07-30: Phase 3 base-package clone audit

The proven Phase 2 state was duplicated as:

```text
Quattro-ARM64-Phase-3-Base-Packages-Working-2026-07-30
```

The Phase 2 checkpoint and powered-off gold VM remain unchanged. The Phase 3
clone booted at `2026-07-30 02:47:44 EDT` with:

```text
kernel:             7.1.5-2-aarch64-ARCH
NetworkManager:     enabled and active
systemd-networkd:   disabled and inactive
enp0s1:             192.168.64.4/24
Quickshell IPC:     ok
Hyprland errors:    none
display:            1280x800@74.994, scale 1
renderer:           direct virgl (Apple M4 Pro), OpenGL 4.1
failed units:       zero system and user
pending migrations: 46
```

All three development repositories were clean at their pushed commits. The
four protected boot hashes remained exact. A manual post-reboot host resize
stayed at the requested dimensions after the previous rollback window.

## 2026-07-30: Phase 3 native package builds

After NetworkManager satisfied one more manifest entry, 20 of the 143 literal
base-manifest names remained unsatisfied. Four already-declared recipes were
built first:

```bash
./bin/repo build --arch aarch64 --package \
  cliamp omacut omawrite tobi-try
```

All four completed. Their artifacts were preserved before the builder cleanup
at:

```text
build-output/phase3-native-batch1-20260730-0310/
```

The x86_64-only metadata on three native-source recipes was changed to include
`aarch64`, then validated with `bash -n`, `makepkg --printsrcinfo`, and a clean
container build:

```bash
./bin/repo build --arch aarch64 --package \
  asdcontrol hyprland-preview-share-picker tensaku
```

All three completed. Their artifacts were preserved at:

```text
build-output/phase3-native-batch2-20260730-0315/
```

Package-repository commit `74775e1` contains only the three architecture
declarations and is pushed to `origin/quattro-aarch64-utm`.

Every compiled payload was inspected with `file` and `readelf` and reported
ELF64 little-endian AArch64. `tobi-try` is an architecture-independent Ruby
application. Package metadata, contents, install scriptlets, SHA-256 hashes,
and dry pacman transactions were inspected. The first batch requires only
`yt-dlp` and its native repository dependencies; the second batch already has
all runtime dependencies on the host.

At that checkpoint, no Phase 3 package had been installed system-wide.
Building changed only Docker state and ignored package-output directories.

## 2026-07-30: Phase 3 staged package installation

Installed the eight missing unchanged packages from signed Arch Linux ARM
repositories:

```bash
pkexec pacman -S --noconfirm --needed \
  bluez-utils dua-cli foot gpu-screen-recorder lua51 moonlight-qt \
  mpv-mpris yt-dlp
```

The transaction installed the eight targets and seven dependencies. Every
target passed `pacman -Qk`; desktop, network, graphics, unit, and protected
hash checks passed immediately afterward.

The first seven-package local transaction stopped without changing the host
because of legacy file collisions. Inspection found:

```text
/usr/bin/asdcontrol                unowned, version 0.4
/etc/sudoers.d/asdcontrol          unowned
/usr/bin/try                       unowned, version 1.9.3
/usr/bin/lib/{tui.rb,fuzzy.rb}     unowned
hyprland-preview-share-picker-git  installed, no reverse dependencies
```

The existing unowned `try` payload matched current upstream commit
`13869f447d88dfe21954620e11655b76713bb8e1`, while the package recipe was
1.8.1. Updated and rebuilt `tobi-try 1.9.3-1`; all three packaged files are
byte-for-byte identical to the working unowned files. Added an explicit
`hyprland-preview-share-picker-git` conflict to the stable share-picker
package and rebuilt it. Both clean ARM64 builds passed and were preserved in:

```text
build-output/phase3-native-batch3-20260730-0311/
```

The fixes were committed and pushed separately:

```text
752d420  Update tobi-try to 1.9.3
23d81b0  Conflict share picker with git variant
```

Created a recoverable archive of every collided path before moving the
unowned files:

```text
~/.local/state/omarchy/phase3-collision-backup-20260730-031300/legacy-collision-files.tar
SHA-256: ed13dd2d873bbe963896906b313b4e48a447f3739d82a6cb554e9f3b2275fd7c
```

The unowned files remain under the adjacent `moved-unowned/` directory.
Removed only `hyprland-preview-share-picker-git`, which had no reverse
dependencies, then installed:

```text
asdcontrol                       1:0.6.0-1
cliamp                           1.62.0-1
hyprland-preview-share-picker    0.2.1-1
omacut                           0.2.0-1
omawrite                         0.4.0-1
tensaku                          0.26.6-1
tobi-try                         1.9.3-1
```

Every package passed `pacman -Qk`; `asdcontrol` was checked through `pkexec`
because its sudoers directory is intentionally not traversable by the normal
user. All collided live paths are now owned by their intended packages.

The complete base manifest now resolves 138 of 143 names. The only missing
literal names are:

```text
dotnet-runtime
obs-studio
obsidian
pinta
qemu-user-static-binfmt
```

Quickshell IPC, empty Hyprland errors, NetworkManager full connectivity,
direct VirGL, zero failed units, and all protected hashes passed after the
transactions. Tensaku's optional wiring command and the Quattro migration and
finalization commands were not run.

## 2026-07-30: Phase 3 .NET and Pinta completion

Added an AArch64 package for Microsoft's official .NET 10 SDK and changed the
Pinta recipe to select its runtime identifier by `CARCH`:

```text
aarch64 -> linux-arm64
x86_64  -> linux-x64
```

Pinta also updates `Tmds.DBus` from `0.22.0` to `0.92.0`. Clean container
builds were inspected before installation. Final artifacts:

```text
build-output/phase3-native-batch5-20260730-0326/dotnet-sdk-bin-10.0.10.sdk302-1-aarch64.pkg.tar.xz
SHA-256: a5ace2eb5c025e5b6061d80a6d43486c4aa3322e4a722cea64b678bcec981b9f

build-output/phase3-native-batch5-20260730-0326/pinta-3.1.2-2-aarch64.pkg.tar.xz
SHA-256: 61e79f76a8d7978e51209af812a8077d7aecd180e431c0c5f441c2d78473bf4a
```

Installed versions:

```text
dotnet-sdk-bin 10.0.10.sdk302-1
pinta 3.1.2-2
```

The SDK provides `dotnet-host`, `dotnet-runtime`,
`dotnet-targeting-pack`, and `dotnet-sdk`. Both packages passed file and
dependency checks. Pinta launched through UWSM and its UI was inspected at:

```text
~/Pictures/screenshot-2026-07-30_03-26-51.png
```

Package-repository commits `f49bdf2` and `d95da3e` are pushed.

## 2026-07-30: Phase 3 Obsidian completion

Packaged upstream Obsidian `1.12.7` from its official ARM64 AppImage. The
first package build exposed mode `0700` on extracted icon directories;
revision 2 normalizes every icon directory to `0755`.

Before installation, the existing unowned ARM AppImage was moved to:

```text
~/.local/state/omarchy/phase3-collision-backup-20260730-031300/moved-unowned/obsidian-legacy.AppImage
```

Final artifact:

```text
build-output/phase3-native-batch7-20260730-0334/obsidian-appimage-1.12.7-2-aarch64.pkg.tar.xz
SHA-256: 4cf5d2d2441f29af1a7862b426980df8276e3e4bf01e0aad29bce401b906f39e
```

The package owns 36 files with none missing and provides the manifest name
`obsidian`. The application launched through UWSM, held
`/dev/dri/renderD128`, and showed no clipping or layout defects:

```text
~/Pictures/screenshot-2026-07-30_03-34-34.png
```

Package-repository commits `8ed9c0d` and `9468558` are pushed.

## 2026-07-30: Phase 3 OBS Studio completion

Based the ARM recipe on Arch's OBS package and built upstream tag `32.2.1`
natively. The optional browser plugin is disabled; Wayland, PipeWire,
WebSocket, scripting, x264, FDK AAC, VST, and WebRTC remain enabled.

Revision 1 built and installed, but its launch exposed missing mbedTLS sonames
in `obs-outputs.so`. The signed Arch Linux ARM `mbedtls3 3.6.6-1` package
claimed the six required top-level symlinks while installing incorrect
relative targets. Reinstalling that package reproduced all six
`pacman -Qkk` failures.

Revision 2 depends on signed repository package `mbedtls 3.6.5-1` instead.
The broken `mbedtls3` package was removed, the corrected OBS package was
installed, and both packages then passed complete file checks. Final artifact:

```text
build-output/phase3-native-batch9-20260730-0357/obs-studio-32.2.1-2-aarch64.pkg.tar.xz
SHA-256: a98c593f3fef38dc7f5d19a821475dd30f930742016a1ed808ccf9a194701306
```

`ldd /usr/lib/obs-plugins/obs-outputs.so` resolved all three mbedTLS
libraries. The corrected live launch reported:

```text
Platform: Wayland
OpenGL adapter: Mesa virgl (Apple M4 Pro)
OpenGL: 4.1 Core Profile
loaded: obs-outputs.so, linux-pipewire.so, obs-websocket.so
audio: PipeWire desktop monitor and microphone capture started
encoders: x264, AAC, Opus, FDK AAC, PCM, ALAC, FLAC
```

OBS held `/dev/dri/renderD128`, had no software renderer overrides, and shut
down with zero reported memory leaks. Visual reference:

```text
~/Pictures/screenshot-2026-07-30_03-59-07.png
```

Package-repository commits `8f6bc12` and `d0f3fdc` are pushed.

## 2026-07-30: Architecture-resolved base manifest completed

Arch Linux ARM has:

```text
qemu-user-binfmt 11.0.2-4 aarch64
```

It does not have the manifest's x86 package name
`qemu-user-static-binfmt`. Added `omarchy-pkg-base-list` to preserve the
literal name on x86_64 and substitute `qemu-user-binfmt` only on AArch64.
Reinstall, Quattro upgrade, and system acceptance paths now consume the same
resolver. Focused tests pass both mappings and comment/blank filtering.

Source commit:

```text
8eb138c19fddb1c42b020047052e6c9674e135a9
```

Installed the signed ARM package:

```bash
pkexec pacman -S --noconfirm --needed qemu-user-binfmt
```

The transaction installed matching `qemu-user 11.0.2-4` and registered
foreign handlers under `/proc/sys/fs/binfmt_misc`, including
`qemu-x86_64`. Final provider-aware audit:

```text
resolved_manifest_entries=143
missing=0
```

Both QEMU packages pass file checks. The aggregate shell suite reaches and
passes the new resolver test when supplied the nonstandard sibling checkout
paths. Two unrelated existing checks remain red: missing CLI metadata on
`omarchy-update-system-pkgs-when-conflicted`, and the sleep-lock timing budget
at approximately 1.60 seconds in this VM.

The final desktop health check retained Quickshell IPC, empty Hyprland
configuration errors, NetworkManager connectivity, direct VirGL on the Apple
M4 Pro, zero failed system/user units, and exact protected hashes. No
migration, finalization, kernel, initramfs, Limine, UEFI, partition, or
filesystem action was run.

## 2026-07-30: Phase 4 Retina display and legacy cleanup

The completed Phase 3 VM was duplicated as:

```text
Quattro-ARM64-Phase-4-Legacy-Cleanup-Working-2026-07-30
```

After UTM Retina mode exposed a `3006x1818@60` display at scale 1,
`~/.config/hypr/monitors.lua` was backed up and its scale override changed
from `auto` to `2`. The active mode remains dynamic rather than hard-coded.
The user completed a host-window resize acceptance check at
`2826x1818@60`, scale 2, and the requested window size stayed put.

Audited installed packages by exact name against
`remove_retired_default_packages()` in `bin/omarchy-upgrade-to-quattro`.
Before recursive removal, recorded package reasons and marked these current
base providers explicit, matching the normal Quattro upgrade path:

```text
bluez bluez-tools fakeroot libsecret pacman-contrib wireplumber
```

Created a complete rollback bundle at:

```text
~/.local/state/omarchy/phase4-retired-ui-backup-20260730-044500/
```

The first inspected transaction removed 19 requested retired UI packages and
11 now-unused dependencies:

```text
walker elephant elephant-bluetooth elephant-calc elephant-clipboard
elephant-desktopapplications elephant-files elephant-menus
elephant-providerlist elephant-runner elephant-symbols elephant-todo
elephant-unicode elephant-websearch waybar mako swaybg swayosd polkit-gnome
libmpdclient jsoncpp gtkmm3 pangomm gtk-layer-shell gpsd pps-tools cairomm
atkmm glibmm libsigc++
```

Inactive UI configurations and the unowned Walker pacman hook were moved into
the rollback bundle. Quickshell's menu and notification surfaces passed
visual checks afterward.

The second inspected transaction removed ten requested retired utilities and
five now-unused dependencies:

```text
blueberry bluetui gnome-bluetooth hypridle hyprlock playerctl satty
wayfreeze-git wf-recorder wiremix xapp xapp-symbolic-icons libgnomekbd
libxklavier python-setproctitle
```

The inactive Wiremix configuration and launcher were moved into the batch
rollback directory. `omarchy capture screenshot fullscreen save` continued
to work after the old capture utilities were gone.

The two transactions removed 45 packages and freed 470.38 MiB. Pre-reboot
validation found 982 installed packages, 201 explicit packages, 37 foreign
packages, zero orphans, and zero failed system or user units. All 143
architecture-resolved manifest entries remain satisfied. Quickshell IPC,
empty Hyprland errors, NetworkManager, audio, direct VirGL, dynamic Retina
resizing, 46 pending migrations, and the four protected hashes all remain
healthy.

The only exact canonical retired package names still installed are:

```text
claude-code
dust
impala
iwd
localsend-bin
opencode
```

The four applications are retained to preserve user choices. `impala` and
`iwd` are deferred network rollback assets. The active `greetd` login manager
is protected.

## 2026-07-30: Phase 4 cleanup proof reboot

The controlled reboot began at `2026-07-30 05:09:02 EDT`. `greetd`,
start-hyprland, Hyprland, Quickshell, and exactly one package-owned SPICE
resize helper returned through the normal persistent path. Hyprland selected
the Lua user config, UWSM exported `/usr/share/omarchy`, and the current-boot
logs contained no Quickshell warnings, Hyprland errors, or `greetd` errors.

The reboot reproduced 982 installed packages, 201 explicit packages, 37
foreign packages, zero orphans, 143 satisfied manifest entries, and 46
pending migrations. Both removal batches remained absent. The six normalized
base providers remained installed and explicit. Core Omarchy, settings,
Quickshell, and Hyprland packages passed file checks.

NetworkManager restored the `.4` address and `.1` gateway; DNS and HTTPS
passed. PipeWire, PipeWire Pulse, and WirePlumber were active with the SPICE
audio device present. Both SPICE agents and Quickshell's clipboard watchers
returned. Direct VirGL remained active on the Apple M4 Pro with OpenGL 4.1,
no software-rendering override, and zero failed system or user units.

The Quickshell root menu, notification surface, and a newly launched terminal
passed visual inspection:

```text
~/Pictures/screenshot-2026-07-30_05-11-17.png
~/Pictures/screenshot-2026-07-30_05-11-25.png
~/Pictures/screenshot-2026-07-30_05-11-52.png
```

Lua workspace dispatch moved from workspace 1 to 3 and back. The user resized
the UTM window and waited beyond the old rollback interval. The guest stayed
at `2828x1818@60`, scale 2, logical `1414x909`, with the DRM preferred mode
matching Hyprland. The user also copied `phase4-clipboard-ok` on macOS and
pasted it into the guest, proving host-to-guest SPICE clipboard transfer.

The four protected hashes remained exact. No migration, finalization, kernel,
initramfs, Limine, UEFI, partition, or filesystem action ran. Phase 4 legacy
cleanup is complete.

## 2026-07-30: Phase 5 iwd and migration audit

The completed Phase 4 VM was duplicated as:

```text
Quattro-ARM64-Phase-5-System-Integration-Working-2026-07-30
```

The new boot reproduced the 982-package Phase 4 state, 143/143 manifest
resolution, 46 pending migrations, zero orphans or failed units, a healthy
desktop and network, and the exact protected hashes.

NetworkManager owned the only hardware link, `enp0s1` virtio Ethernet. iwd
was still enabled and active despite the absence of a Wi-Fi device. The audit
found an unowned Omarchy 3 drop-in:

```text
/etc/NetworkManager/conf.d/iwd.conf
[device]
wifi.backend=iwd
```

Quattro retired `impala` and `iwd` but left this configuration behind,
creating a future Wi-Fi failure on upgraded machines. Added an exact-content
cleanup to the live-upgrade command. It backs up and removes only the known
legacy file, preserves package-owned or customized variants, and avoids
reloading NetworkManager mid-upgrade.

Focused upgrade and network-transition tests pass. The fix is pushed as:

```text
1288ab0058e6d52631bb7acad2c4315f2686c495
```

Read and classified every one of the 46 pending migrations against the live
VM. The broad queue remains intentionally pending: it includes removal of the
preserved `dust` application, possible Snapper snapshot deletion, system and
package transitions, and three conditional boot-image paths. The complete
matrix is in `docs/aarch64-port/phase5-system-integration-2026-07-30.md`.

## 2026-07-30: Phase 5 live network fallback retirement

Created the mode-`0700`, 9.6 MiB rollback bundle:

```text
~/.local/state/omarchy/phase5-iwd-retirement-backup-20260730-053447/
```

It contains cached signed packages, database records, the non-directory
package payload, exact network state, SHA-256 records, and an executable
rollback. The first payload-tar attempt accidentally included directory
entries and began recursing through `/usr`; it was stopped and its incomplete
archive was deleted before any system mutation. The replacement archive uses
81 regular files and symlinks with no-recursion mode.

The live iwd drop-in was hash-verified and moved into the rollback directory.
After reloading NetworkManager configuration, Ethernet state 100, the `.4`
address, `.1` gateway, default route, DNS, HTTPS, Quickshell, and Hyprland all
passed before any service change.

iwd was disabled and stopped. The same proof passed before the final exact
package transaction:

```text
impala 0.7.4-1
iwd    3.12-1
ell    0.83-1
```

The transaction freed 7.33 MiB. Live validation found 979 installed packages,
199 explicit packages, 37 foreign packages, zero orphans, all 143 manifest
entries satisfied, all 46 migrations pending, and zero failed system or user
units. NetworkManager and `wpa_supplicant` pass package checks. The remaining
canonical retired names are only `claude-code`, `dust`, `localsend-bin`, and
`opencode`, all intentionally preserved applications.

The Quickshell network panel passed visual inspection after dismissing the
unrelated migration notification that initially overlapped it:

```text
~/Pictures/screenshot-2026-07-30_05-45-41.png
```

Quickshell, Hyprland, audio, SPICE, Retina scale 2, dynamic resize, and direct
VirGL remained healthy. Every protected hash remained exact. No migration,
Snapper, zram, boot, partition, or filesystem action ran. One controlled
reboot remains.

## 2026-07-30: Phase 5 proof reboot

The controlled reboot began at `2026-07-30 05:54:14 EDT`. The exact
post-transaction package state returned:

```text
installed packages:  979
explicit packages:   199
foreign packages:    37
orphans:             0
manifest entries:    143
manifest missing:    0
pending migrations:  46
```

`impala`, `iwd`, and `ell` remained absent. The iwd unit was `not-found`, its
current-boot journal was empty, and NetworkManager configuration contained no
iwd reference. NetworkManager returned enabled and active with full
connectivity on the same `Wired connection 1` UUID,
`192.168.64.4/24` address, and `192.168.64.1` gateway. DNS and HTTPS passed.
NetworkManager and `wpa_supplicant` had zero missing package files.
`systemd-networkd` remained disabled and inactive with no current-boot
activity.

`greetd`, Hyprland, Quickshell, PipeWire, PipeWire Pulse, WirePlumber, both
SPICE agents, and exactly one package-owned resize helper returned normally.
Hyprland selected the Lua user configuration, UWSM exported
`OMARCHY_PATH=/usr/share/omarchy`, no retired UI process returned, and there
were no software-rendering overrides or failed system/user units.

Post-reboot visual evidence:

```text
network panel: ~/Pictures/screenshot-2026-07-30_05-56-34.png
root menu:     ~/Pictures/screenshot-2026-07-30_05-56-52.png
terminal:      ~/Pictures/screenshot-2026-07-30_05-57-21.png
```

The network panel showed the active Ethernet address, gateway, traffic,
latency, packet loss, and DNS controls with no clipping or stale Wi-Fi state.
Lua workspace dispatch moved from workspace 1 to 2 and back. A short audio
sample was audible at 20 percent, after which the sink was restored to its
prior zero-volume state.

The user resized UTM smaller and larger and waited beyond the old rollback
interval. Final DRM and Hyprland state agreed at `2700x1818@60`, scale 2,
logical `1350x909`, and the window stayed put. The user copied
`phase5-network-retired-ok` on macOS and pasted it into the guest, proving
host-to-guest SPICE clipboard transfer.

Direct VirGL remained active on the Apple M4 Pro with OpenGL 4.1. All four
protected hashes remained exact, all 46 migration markers remained pending,
and no Snapper, zram, kernel, initramfs, Limine, UEFI, partition, or
filesystem action ran. Phase 5 system integration is complete.
