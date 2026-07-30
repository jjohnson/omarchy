# Quattro ARM64 Phase 5 System Integration

Date: 2026-07-30

## Scope and Baseline

This phase runs in:

```text
Quattro-ARM64-Phase-5-System-Integration-Working-2026-07-30
```

It was duplicated from the completed Phase 4 legacy-cleanup checkpoint. The
Phase 4 VM remains powered off. This phase may retire the remaining iwd
network fallback after an exact rollback archive, but it must not run the
broad migration queue or alter Snapper, zram, the kernel, initramfs, Limine,
UEFI entries, partitions, or filesystems.

The clone booted at `2026-07-30 05:25:13 EDT` with:

```text
kernel:             7.1.5-2-aarch64-ARCH
installed packages: 982
explicit packages:  201
foreign packages:   37
orphans:            0
manifest entries:   143
manifest missing:   0
pending migrations: 46
Quickshell IPC:      ok
Hyprland errors:     none
failed units:        zero system and user
renderer:            direct virgl (Apple M4 Pro), OpenGL 4.1
```

NetworkManager restored `192.168.64.4/24` on `enp0s1` with gateway
`192.168.64.1`. PipeWire, PipeWire Pulse, WirePlumber, `greetd`, both SPICE
agents, Retina scale 2, and dynamic resizing returned normally.

The development repositories were clean at their pushed commits:

```text
omarchy:      c3b16460c2ad5cf6cc25a0d138f5755e2fe7a3b2
omarchy-pkgs: d0f3fdc804540fedae054751e89124f04f2fb707
omarchy-iso:  a76f599eaae524d9fb9e135473320e4e66696cb7
```

Protected hashes:

```text
2662962bab816958bad80f3c24e275f2e306b984bdf1f81dc235342382c8048f  /boot/initramfs-linux.img
add658562939b9abb73bf6fe7865fb177cd8fbfa5a73479467cf3469da57ac44  /boot/limine.conf
6edf91b6ee62aff521de9666d6f8c790be086ecec48352f2dd580d66a6831dd3  /etc/mkinitcpio.conf
a0bf23d62d7d74bfa597e38af7cc841837ba4a353ed8f8b10b5dd3a69dab5814  /etc/mkinitcpio.d/linux-aarch64.preset
```

## iwd and NetworkManager Audit

The VM exposes only loopback and `enp0s1`, a `virtio_net` Ethernet device. It
has no Wi-Fi radio. NetworkManager is enabled and active and is the sole owner
of the Ethernet address, route, and DNS.

The remaining network fallback is:

| Package | Version | Reason | Relationship |
| --- | --- | --- | --- |
| `impala` | `0.7.4-1` | explicit | depends on `iwd` |
| `iwd` | `3.12-1` | explicit | optional backend for NetworkManager |
| `ell` | `0.83-1` | dependency | required only by `iwd` |

The exact `pacman -Rs` preview contains only those three packages.
`wpa_supplicant 2:2.11-5` remains installed as a hard NetworkManager
dependency.

The blocker to simply removing iwd was an unowned legacy Omarchy 3 drop-in:

```text
/etc/NetworkManager/conf.d/iwd.conf

[device]
wifi.backend=iwd
```

Its SHA-256 is:

```text
654d07fff7855a7c51cf5c55478df12491e64dda5c87fbb14f1d44faf93419eb
```

The file came from the old `install/config/hardware/network.sh`. NetworkManager
read it on this boot. Removing iwd while preserving the drop-in would leave
upgraded systems explicitly selecting a missing Wi-Fi backend.

Commit `1288ab0058e6d52631bb7acad2c4315f2686c495` fixes the Quattro
live-upgrade path. It:

- recognizes only the exact known two-line legacy file;
- backs that file up before removal;
- preserves package-owned or customized variants with a warning;
- does not reload NetworkManager during the live upgrade;
- runs before the existing iwd service disablement and retired-package
  transaction.

`bash -n`, the focused Quattro upgrade test, and the NetworkManager transition
test pass. The behavioral test proves exact legacy content is backed up and
removed while a customized variant is left untouched.

## Pending Migration Audit

All 46 pending scripts were read completely and evaluated against the live
VM. No migration or marker was executed, created, removed, or forged.

Classification:

- **Satisfied**: intended state is already present or the guarded script would
  make no material change.
- **User follow-up**: an idempotent per-user adjustment is still applicable
  and should be handled with a user-state archive in a later phase.
- **System follow-up**: a non-boot system or package transition remains
  applicable but should be isolated from the iwd transaction.
- **Guarded no-op**: hardware or package predicates make the script a no-op on
  this UTM VM.
- **Blocked**: conflicts with an explicit preservation choice or can touch
  snapshots or boot assets.

| Migration | Classification | Evidence on this VM |
| --- | --- | --- |
| `1778623107` | Satisfied | `mpv-mpris` is installed. |
| `1780057136` | Satisfied | Alacritty, Ghostty, and Kitty already have CSI-u bindings; Foot config is absent. |
| `1780294774` | Satisfied | User `shell.json` is absent, so packaged clock defaults apply. |
| `1780517689` | User follow-up | Browser flag files lack the yt-dlp extension path; native hosts and `yt-dlp` are already present. |
| `1780739888` | Blocked | `dua-cli` is installed, but the script would remove intentionally retained `dust`. |
| `1781043107` | User follow-up | Both legacy config and current state theme trees exist; merging/removal needs its own archive. |
| `1781063758` | Satisfied | `hyprland.lua` already loads the packaged bootstrap. |
| `1781158082` | User follow-up | Neovim's theme link still targets the legacy config tree. |
| `1781286586` | Satisfied | Tensaku is installed and Satty is absent. |
| `1781485962` | Satisfied | User input and binding hashes do not match the stock replacement predicates. |
| `1781587663` | User follow-up | Neovim remote clipboard is installed; tmux lacks the OSC 52 feature line. |
| `1781793381` | Satisfied | `udiskie` is installed and active through normal autostart. |
| `1781984677` | Blocked | Snapper config exists, but cleanup and Limine sync units are disabled; the script would rewrite root policy and enable both. |
| `1782002156` | Satisfied | NetworkManager owns the link; every networkd unit is disabled or masked. |
| `1782049344` | User follow-up | The legacy Limine Snapper notifier is active and its hidden autostart override is absent. |
| `1784401744` | Satisfied | tmux bindings are current; `sof-firmware` is present; no matching physical GPU transition applies. |
| `1784476564` | Guarded no-op | The layout is `us`, so the conditional initramfs rebuild is false. |
| `1784479832` | User follow-up | Kitty has no remote-control `listen_on` setting. |
| `1784508556` | User follow-up | Existing Chromium and Brave flags do not pin `gnome-libsecret`. |
| `1784510887` | Guarded no-op | `brave-origin-beta-bin` is absent. |
| `1784521870` | Satisfied | The replacement migration notifier is enabled and the retired path unit is absent. |
| `1784568652` | Satisfied | `NetworkManager-wait-online.service` is masked. |
| `1784672586` | Satisfied | `quickshell-git` is installed. |
| `1784763917` | Satisfied | Chromium Copy URL native hosts are installed. |
| `1784767406` | Satisfied | The obsolete Voxtype toggle is absent. |
| `1784809451` | System follow-up | `updatedb.conf` still needs the current Btrfs snapshot exclusions. |
| `1784809452` | Blocked | The script may delete root Snapper timeline snapshots. |
| `1784818437` | Guarded no-op | No fingerprint package or PAM fingerprint line exists. |
| `1784909971` | User follow-up | Ten legacy mise wrappers match the regeneration predicate. |
| `1784914435` | Satisfied | Packaged Wi-Fi power policy is installed; this VM has no wireless interface. |
| `1784917531` | Satisfied | `initramfs_async=0` is already present, so the Limine rebuild condition is false. |
| `1784960000` | Guarded no-op | The XPS audio-tuning hardware predicate is false. |
| `1784961000` | System follow-up | zram is active and empty; the script would apply sysctl state and restart it. |
| `1784970000` | Satisfied | logind exposes the packaged 15-second inhibit delay. |
| `1784989000` | Satisfied | User `shell.json` is absent, so packaged bar ordering applies. |
| `1785002349` | User follow-up | Neovim's theme link matches the legacy suffix repaired by this script. |
| `1785013000` | Satisfied | The unowned zram config has explicit local size tuning, so the script preserves it. |
| `1785090473` | Guarded no-op | No fingerprint packages are installed. |
| `1785095882` | Satisfied | The login-only migration notifier is enabled and retired links are absent. |
| `1785101000` | Guarded no-op | Tailscale is absent. |
| `1785166747` | Satisfied | Both bundled Chromium native-message hosts are installed. |
| `1785167800` | Satisfied | `omarchy-fcitx5.service` is enabled and active. |
| `1785189600` | Satisfied | No tmux alert hooks or customized `TmuxAlert` widget remain. |
| `1785273276` | Guarded no-op | T2 configuration paths are absent; this is generic UEFI virtual hardware. |
| `1785344985` | Satisfied | User `shell.json` is absent, so the packaged model-usage widget applies. |
| `1785351479` | System follow-up | Kvantum and its Qt5-only dependencies are installed with no other reverse dependencies. |

The queue is therefore not a safe unit of work for this staged existing-user
port. It mixes already-satisfied repairs with applicable user changes,
ordinary system transitions, an explicit package-preservation conflict,
snapshot deletion, and conditional boot work.

## Rollback Bundle

Before the VM transaction, the exact package, service, and network state was
captured at:

```text
/home/jj/.local/state/omarchy/phase5-iwd-retirement-backup-20260730-053447/
```

The mode-`0700` directory is approximately 9.6 MiB. It includes:

- cached signed `ell`, `iwd`, and `impala` archives and signatures;
- their package database entries, metadata, payload, and exact transaction;
- the legacy iwd file and relevant NetworkManager/networkd configuration;
- service, connection, and systemd enablement state;
- an executable rollback command.

Important hashes:

```text
654d07fff7855a7c51cf5c55478df12491e64dda5c87fbb14f1d44faf93419eb  iwd.conf
6f935b84ede15996c8da74af0d93b4aac04ec60b9cdc0cedff8fed59b675f8df  installed-payload.tar
06523ccbc901f83b23ad826f5b104c7fee21674d812b85887a9b729080adde0d  network-config.tar
0bae5a205931919f879afa01fd2af9b3ae90825bccb88a99c74373e86ab00989  rollback
```

Rollback from a working desktop or TTY:

```bash
/home/jj/.local/state/omarchy/phase5-iwd-retirement-backup-20260730-053447/rollback
```

The rollback elevates through `pkexec`, reinstalls the three cached packages,
restores the legacy drop-in, and enables iwd. A reboot is required before
relying on restored Wi-Fi so NetworkManager selects the restored backend.

## Planned Isolated Transaction

The bounded transaction is:

1. move only the exact legacy `iwd.conf` into the rollback directory;
2. reload NetworkManager configuration and prove Ethernet, DNS, and HTTPS;
3. disable and stop iwd;
4. remove exactly `impala`, `iwd`, and orphaned `ell`;
5. prove the package manifest, desktop, network, migrations, and protected
   hashes;
6. perform one controlled reboot and repeat acceptance.

No migration marker or unrelated system integration state will change.
