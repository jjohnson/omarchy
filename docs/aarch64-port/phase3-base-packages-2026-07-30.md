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
| `tobi-try` | `1.8.1-2` | Ruby application |

The first four recipes already declared AArch64. `asdcontrol`, the Hyprland
share picker, and `tensaku` needed only architecture metadata changes; their
native builds required no source patch. The changes are pushed in
`omarchy-pkgs` commit `74775e1e3f8a0165b7d5e5e5074c80a4fe961462`.

Package contents and scriptlets were inspected. `asdcontrol` installs a
narrowly scoped passwordless sudoers rule for `/usr/bin/asdcontrol`, which is
its existing package behavior. This VM has no USB Apple display, so the
package is not needed for hardware operation here even though its ARM64 build
is proven.

The combined dry transactions resolve from the local artifacts and signed
Arch Linux ARM repositories. No package from these two batches has yet been
installed on the host.

Artifact SHA-256 values:

```text
bd811a6dc7f50581eb380ce47519e76cc8b5a34bdd09ece89ee9e135685125d2  asdcontrol-1:0.6.0-1-aarch64.pkg.tar.xz
d496d8abd20e4fd16323212ec4870245dd779add1ea6deeb1863ba6674785583  cliamp-1.62.0-1-aarch64.pkg.tar.xz
9c358162c5818bd21ce79bc00005cc1f3f186a412e4408355d98a2d333d27b6a  hyprland-preview-share-picker-0.2.1-1-aarch64.pkg.tar.xz
73e2e2b912500264a797f11c1603714a924f00de0b5c42e4e362515ac3ecd39d  omacut-0.2.0-1-aarch64.pkg.tar.xz
6b548e42937b5654f3339efa1003ea898ac45acd6d3c2ddc3a03c9b6c7fa6683  omawrite-0.4.0-1-aarch64.pkg.tar.xz
a5b44c2d050ebc8986e8cf8410815aac8d779e6d6217166201dfa1c99994a51b  tensaku-0.26.6-1-aarch64.pkg.tar.xz
55723a2ac03232418684ee01677e8134e3a6e049a5b44af36d509c18fb50cd46  tobi-try-1.8.1-2-aarch64.pkg.tar.xz
```

## Remaining Base-Manifest Work

After the NetworkManager installation, 20 literal manifest names were missing.
The seven local builds above close their build availability. Eight more are
published unchanged by Arch Linux ARM:

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

Five names still need a packaging or substitution decision:

```text
dotnet-runtime
obs-studio
obsidian
pinta
qemu-user-static-binfmt
```

`dotnet-runtime` and Pinta form one ARM64 packaging chain. Obsidian has an
upstream ARM64 distribution route. OBS Studio remains optional desktop
application recipe work. Arch Linux ARM publishes `qemu-user-binfmt`, not the
literal static package name, so source-side architecture substitution is
needed before the complete manifest can be considered portable.
