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
  /home/jj/Projects/gradle-arch-package-arm64
git -C /home/jj/Projects/gradle-arch-package-arm64 rev-parse HEAD
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
cd /home/jj/Projects/omarchy-pkgs-quattro-arm64/pkgbuilds/omarchy-settings-dev
OMARCHY_SRC=/home/jj/Projects/omarchy-quattro-arm64 \
  makepkg --cleanbuild --force --nodeps --noconfirm

cd /home/jj/Projects/omarchy-pkgs-quattro-arm64/pkgbuilds/omarchy-dev
OMARCHY_SRC=/home/jj/Projects/omarchy-quattro-arm64 \
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
  /home/jj/Projects/omarchy-pkgs-quattro-arm64/build-output/pre-finalize-user-2026-07-29.tar \
  <existing user state paths>
```

The first installation attempt stopped before changing packages because 13
legacy unowned files overlapped `omarchy-settings-dev`. After comparing those
files with the package payload, the final transaction used exact
`--overwrite` arguments for those paths only:

```bash
pkexec \
  /home/jj/Projects/omarchy-pkgs-quattro-arm64/build-output/install-aarch64-runtime.sh
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
OMARCHY_PATH=/home/jj/.local/share/omarchy
PATH=...:/home/jj/.local/share/omarchy/bin:...:/usr/bin:...
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
/home/jj/Projects/omarchy-pkgs-quattro-arm64/build-output/pre-install-system-2026-07-29/
```

## 2026-07-30: Persistent session cutover preparation

Verified the post-checkpoint reboot, exact boot hashes, installed packages,
remote Git branch parity, active session environment, and current UI services.
The system returned to the expected 3.x login environment with no failed
units.

Archived the user state that the cutover could affect:

```bash
tar -C /home/jj -cpf \
  /home/jj/Projects/omarchy-pkgs-quattro-arm64/build-output/pre-persistent-cutover-2026-07-30-002942.tar \
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
env HOME=/home/jj OMARCHY_PATH=/usr/share/omarchy PATH=/usr/bin:/bin \
  Hyprland --verify-config --config /home/jj/.config/hypr/hyprland.lua
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
/home/jj/.local/state/omarchy/phase2-network-backup-20260730-021354/system-network-state.tar
SHA-256: 2aa6f88a1eccfde208a0050046c5f7b758a3b16428a65ed2be2878ee54e2e5ec
```

Created and syntax-checked the root rollback command:

```text
/home/jj/.local/state/omarchy/phase2-network-backup-20260730-021354/rollback-to-networkd
SHA-256: 0bfd3385d18d58064b6d5f370af1fa232e429ca24b2d945b5b20642b386e9c99
```

The rollback can be invoked from a local terminal or TTY with:

```bash
pkexec \
  /home/jj/.local/state/omarchy/phase2-network-backup-20260730-021354/rollback-to-networkd
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
/home/jj/.local/state/omarchy/phase2-network-backup-20260730-021354/cutover-to-networkmanager
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
/home/jj/Pictures/screenshot-2026-07-30_02-28-47.png
```

It showed the active Ethernet address and gateway, traffic, latency, packet
loss, totals, and DNS controls without clipping or stale state.

Hyprland configuration, the SPICE resize helper, direct VirGL, display mode,
failed-unit counts, pending-migration count, and protected hashes were
rechecked. All passed; the queue remained at 46 and the boot hashes remained
exact. The complete live result and remaining reboot proof are in
`phase2-networkmanager-2026-07-30.md`.
