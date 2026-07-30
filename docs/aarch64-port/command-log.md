# Quattro AArch64 UTM Command Log

This log records the commands and meaningful results from the first Quattro
AArch64 desktop milestone. Commands are run as the normal user unless a
privileged command is explicitly shown.

## 2026-07-29: Prior-session baseline

Read the complete validated 3.x UTM procedure before inspecting or changing the
guest:

```bash
sed -n '1,240p' /home/jj/utm/arm64-utm-3x-happy-path.md
sed -n '241,520p' /home/jj/utm/arm64-utm-3x-happy-path.md
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
  /home/jj/Projects/omarchy-pkgs-quattro-arm64
git clone --branch quattro --single-branch \
  https://github.com/omacom-io/omarchy-iso.git \
  /home/jj/Projects/omarchy-iso-quattro-arm64
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
