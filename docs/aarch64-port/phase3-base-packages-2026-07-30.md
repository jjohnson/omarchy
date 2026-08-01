# Quattro ARM64 Phase 3 Base Packages

Date: 2026-07-30

## Scope and Checkpoint

This phase runs in:

```text
Quattro-ARM64-Phase-3-Base-Packages-Working-2026-07-30
```

It was duplicated from the proven Phase 2 NetworkManager checkpoint. The gold
VM and Phase 2 checkpoint remain unchanged. This phase may install ordinary
desktop packages, but it must not alter partitions, filesystems, the kernel,
initramfs, Limine, UEFI entries, or migration markers.

The Phase 3 boot began at `2026-07-30 02:47:44 EDT`. NetworkManager,
Quickshell, Hyprland, the package-owned SPICE resize helper, VirGL, audio, and
both SPICE agents returned normally. There were zero failed system or user
units, no Hyprland configuration errors, and all 46 migrations remained
pending. A manual host resize stayed at the requested size.

Protected hashes before package work:

```text
2662962bab816958bad80f3c24e275f2e306b984bdf1f81dc235342382c8048f  /boot/initramfs-linux.img
add658562939b9abb73bf6fe7865fb177cd8fbfa5a73479467cf3469da57ac44  /boot/limine.conf
6edf91b6ee62aff521de9666d6f8c790be086ecec48352f2dd580d66a6831dd3  /etc/mkinitcpio.conf
a0bf23d62d7d74bfa597e38af7cc841837ba4a353ed8f8b10b5dd3a69dab5814  /etc/mkinitcpio.d/linux-aarch64.preset
```

## Native Build Results

Seven remaining base-manifest packages completed clean ARM64 container builds:

| Package | Version | Result |
| --- | --- | --- |
| `asdcontrol` | `1:0.6.0-1` | ELF64 AArch64 |
| `cliamp` | `1.62.0-1` | ELF64 AArch64 |
| `hyprland-preview-share-picker` | `0.2.1-1` | ELF64 AArch64 |
| `omacut` | `0.2.0-1` | ELF64 AArch64 |
| `omawrite` | `0.4.0-1` | ELF64 AArch64 |
| `tensaku` | `0.26.6-1` | ELF64 AArch64 plus shell helper |
| `tobi-try` | `1.9.3-1` | Ruby application |

The first four recipes already declared AArch64. `asdcontrol`, the Hyprland
share picker, and `tensaku` needed only architecture metadata changes; their
native builds required no source patch. The changes are pushed in
`omarchy-pkgs` commit `74775e1e3f8a0165b7d5e5e5074c80a4fe961462`.

Package contents and scriptlets were inspected. `asdcontrol` installs a
narrowly scoped passwordless sudoers rule for `/usr/bin/asdcontrol`, which is
its existing package behavior. This VM has no USB Apple display, so the
package is not needed for hardware operation here even though its ARM64 build
is proven.

The combined dry transactions resolved from the local artifacts and signed
Arch Linux ARM repositories before installation.

Artifact SHA-256 values:

```text
bd811a6dc7f50581eb380ce47519e76cc8b5a34bdd09ece89ee9e135685125d2  asdcontrol-1:0.6.0-1-aarch64.pkg.tar.xz
d496d8abd20e4fd16323212ec4870245dd779add1ea6deeb1863ba6674785583  cliamp-1.62.0-1-aarch64.pkg.tar.xz
650eb80de97ea40a38f5d527e43ca000be951d74575f226a1e46e9f89915c0a8  hyprland-preview-share-picker-0.2.1-1-aarch64.pkg.tar.xz
73e2e2b912500264a797f11c1603714a924f00de0b5c42e4e362515ac3ecd39d  omacut-0.2.0-1-aarch64.pkg.tar.xz
6b548e42937b5654f3339efa1003ea898ac45acd6d3c2ddc3a03c9b6c7fa6683  omawrite-0.4.0-1-aarch64.pkg.tar.xz
a5b44c2d050ebc8986e8cf8410815aac8d779e6d6217166201dfa1c99994a51b  tensaku-0.26.6-1-aarch64.pkg.tar.xz
c3f7ab9712420b3856390afe528d597fd3d2fd5d35b6f832a1221f4c2aae365f  tobi-try-1.9.3-1-aarch64.pkg.tar.xz
```

## Staged Installation

The first host transaction installed eight unchanged packages plus seven
dependencies from signed Arch Linux ARM repositories:

```text
bluez-utils
dua-cli
foot
gpu-screen-recorder
lua51
moonlight-qt
mpv-mpris
yt-dlp
```

Every target passed `pacman -Qk`. Quickshell IPC, Hyprland configuration,
NetworkManager, VirGL, failed-unit counts, and protected hashes remained
healthy before the local-package transaction.

The first local transaction made no change because it found three legacy
collisions:

- unowned `asdcontrol 0.4` files;
- an unowned `try 1.9.3` installation under `/usr/bin`;
- installed `hyprland-preview-share-picker-git 0.2.1.r9.ge2f30ff-1`.

The repository's `tobi-try 1.8.1` recipe would have been a downgrade. It was
updated to 1.9.3 at upstream commit
`13869f447d88dfe21954620e11655b76713bb8e1`. Its rebuilt main script and both
libraries are byte-for-byte identical to the working unowned 1.9.3 files. The
stable share-picker recipe gained a conflict with its `-git` variant so
package replacement is explicit.

Those fixes are pushed as atomic package-repository commits:

```text
752d420  Update tobi-try to 1.9.3
23d81b0  Conflict share picker with git variant
```

Before replacement, every collided path was archived at:

```text
~/.local/state/omarchy/phase3-collision-backup-20260730-031300/legacy-collision-files.tar
SHA-256: ed13dd2d873bbe963896906b313b4e48a447f3739d82a6cb554e9f3b2275fd7c
```

The four unowned paths were moved into the adjacent `moved-unowned/`
directory. The complete installed `-git` payload is also in the tar archive.
Pacman then removed only the dependency-free `-git` package and installed the
seven inspected local packages.

All seven targets now pass package-file checks, including a privileged
`pacman -Qk asdcontrol` check for its protected sudoers file. The installed
commands report:

```text
asdcontrol 0.6.0
hyprland-preview-share-picker v0.2.1-r0-release
try 1.9.3
tensaku 0.26.6
```

No optional Tensaku wiring or migration/finalization command was run.

## Application and Runtime Completion

The final four application/runtime names were satisfied by inspected local
ARM64 packages:

| Manifest name | Installed provider | Version | Result |
| --- | --- | --- | --- |
| `dotnet-runtime` | `dotnet-sdk-bin` | `10.0.10.sdk302-1` | Official Microsoft ARM64 SDK; provides host, runtime, targeting pack, and SDK |
| `pinta` | `pinta` | `3.1.2-2` | Native ARM64 .NET build |
| `obsidian` | `obsidian-appimage` | `1.12.7-2` | Official upstream ARM64 AppImage |
| `obs-studio` | `obs-studio` | `32.2.1-2` | Native ARM64 build with Wayland, PipeWire, WebSocket, scripting, x264, FDK AAC, and WebRTC |

The package changes are pushed as separate commits:

```text
f49bdf2  Add AArch64 .NET SDK package
d95da3e  Build Pinta on aarch64
8ed9c0d  Package Obsidian for aarch64
9468558  Normalize Obsidian icon permissions
8f6bc12  Build OBS Studio on aarch64
d0f3fdc  Use native mbedTLS for ARM OBS
```

Final artifact SHA-256 values:

```text
a5ace2eb5c025e5b6061d80a6d43486c4aa3322e4a722cea64b678bcec981b9f  dotnet-sdk-bin-10.0.10.sdk302-1-aarch64.pkg.tar.xz
61e79f76a8d7978e51209af812a8077d7aecd180e431c0c5f441c2d78473bf4a  pinta-3.1.2-2-aarch64.pkg.tar.xz
4cf5d2d2441f29af1a7862b426980df8276e3e4bf01e0aad29bce401b906f39e  obsidian-appimage-1.12.7-2-aarch64.pkg.tar.xz
a98c593f3fef38dc7f5d19a821475dd30f930742016a1ed808ccf9a194701306  obs-studio-32.2.1-2-aarch64.pkg.tar.xz
```

The final artifacts are preserved in:

```text
build-output/phase3-native-batch5-20260730-0326/
build-output/phase3-native-batch7-20260730-0334/
build-output/phase3-native-batch9-20260730-0357/
```

Pinta uses an architecture-selected .NET runtime identifier and updates
`Tmds.DBus` from vulnerable `0.22.0` to `0.92.0`. It launched through UWSM and
rendered cleanly:

```text
~/Pictures/screenshot-2026-07-30_03-26-51.png
```

The existing unowned Obsidian ARM AppImage was moved intact before the
package-owned launcher was installed:

```text
~/.local/state/omarchy/phase3-collision-backup-20260730-031300/moved-unowned/obsidian-legacy.AppImage
```

The packaged application launched on the desktop, held
`/dev/dri/renderD128`, and passed visual inspection:

```text
~/Pictures/screenshot-2026-07-30_03-34-34.png
```

OBS is built without the optional Chromium browser plugin because upstream's
Linux ARM browser support and CEF bundle remain experimental. Its first
package revision exposed an Arch Linux ARM `mbedtls3 3.6.6-1` defect: the
package claimed six top-level library symlinks but installed them with
incorrect relative targets, and `pacman -Qkk mbedtls3` reported all six
missing. OBS revision 2 instead depends on repository package
`mbedtls 3.6.5-1`, whose files and sonames verify.

The corrected OBS launch proved:

- native Wayland and EGL;
- direct `Mesa virgl (Apple M4 Pro)` OpenGL 4.1;
- an open `/dev/dri/renderD128` descriptor;
- loaded `obs-outputs.so`, `linux-pipewire.so`, and `obs-websocket.so`;
- PipeWire monitor and window capture sources;
- active desktop and microphone audio capture;
- x264, AAC, Opus, FDK AAC, and lossless audio encoders;
- no software-rendering environment override;
- clean shutdown with zero reported memory leaks.

Visual reference:

```text
~/Pictures/screenshot-2026-07-30_03-59-07.png
```

DeckLink, VAAPI encoding, and virtual-camera warnings are expected for this
VirGL VM and optional hardware. They do not prevent normal recording.

## Architecture-Resolved Manifest Completion

Arch Linux ARM publishes `qemu-user-binfmt 11.0.2-4`, not
`qemu-user-static-binfmt`. Commit
`8eb138c19fddb1c42b020047052e6c9674e135a9` adds
`omarchy-pkg-base-list`, which preserves the static package name on x86_64
and substitutes only `qemu-user-binfmt` on AArch64. Upgrade, reinstall, and
acceptance paths now consume the same resolved list.

Focused tests cover comment/blank filtering and both architecture results.
The resolver emits 143 entries for AArch64. After installing the signed
`qemu-user-binfmt` package and its matching `qemu-user` dependency:

```text
resolved_manifest_entries=143
missing=0
qemu-user 11.0.2-4
qemu-user-binfmt 11.0.2-4
```

Both packages pass `pacman -Qk`. The post-transaction hook registered the
foreign binary formats, including `qemu-x86_64`, under
`/proc/sys/fs/binfmt_misc`. The `systemd-binfmt` oneshot is inactive after
registration, while the kernel registrations remain present.

The aggregate shell suite reaches and passes the new resolver test when given
the actual sibling checkout paths. Unrelated baseline failures remain:

- CLI metadata is missing for existing command
  `omarchy-update-system-pkgs-when-conflicted`;
- the sleep-lock budget test takes about 1.60 seconds in this VM and exceeds
  its existing timing threshold.

No source touched by the ARM64 resolver is implicated in either failure.

After the complete transaction set, Quickshell IPC returned `ok`, Hyprland had
no configuration errors, NetworkManager retained full connectivity, and
VirGL remained direct on the Apple M4 Pro with OpenGL 4.1. There were zero
failed system and user units. All four protected hashes remained exact.
