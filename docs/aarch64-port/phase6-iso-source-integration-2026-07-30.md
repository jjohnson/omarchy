# Quattro ARM64 Phase 6 ISO Source Integration

Date: 2026-07-30

## Scope

This phase runs in the
`Quattro-ARM64-Phase-6-Working-2026-07-30` clone. It is source-only: do not
build or boot an ISO yet and do not alter the installed kernel, initramfs,
Limine configuration, UEFI entries, partitions, filesystems, or desktop.

The Phase 6 clone reproduced the completed Phase 5 state:

```text
kernel:             7.1.5-2-aarch64-ARCH
installed packages: 979
explicit packages:  199
foreign packages:   37
orphans:            0
Quickshell IPC:      ok
Hyprland errors:     none
failed units:        zero system and user
renderer:            direct VirGL (Apple M4 Pro), OpenGL 4.1
```

The repositories began clean at:

```text
omarchy:      b1dee8d0e16e5b9a1c1e0c84d14ba44af3e97e85
omarchy-pkgs: d0f3fdc804540fedae054751e89124f04f2fb707
omarchy-iso:  a76f599eaae524d9fb9e135473320e4e66696cb7
```

## Validated Architecture Facts

The previous ISO plan's `linux -> linux` assumption is incorrect for Arch
Linux ARM. Synchronized package metadata and the installed VM prove:

```text
linux         -> linux-aarch64
linux-headers -> linux-aarch64-headers
```

`linux-aarch64 7.1.5-2` provides `linux=7.1.5`, and
`linux-aarch64-headers 7.1.5-2` provides `linux-headers=7.1.5`.

The pinned archiso v87 source has explicit AArch64 support:

- UEFI code `AA64`;
- GRUB target `arm64-efi`;
- architecture-specific profile package files;
- AArch64 QEMU/firmware handling.

Arch Linux ARM does not publish the `archiso` package. Its repository does
provide every dependency needed to run the pinned source directly. The
AArch64 `grub` package includes `/usr/lib/grub/arm64-efi`, and Limine includes
a valid 307,200-byte ARM64 EFI application at
`/usr/share/limine/BOOTAA64.EFI`.

The upstream x86_64 releng list has 128 packages. After exact ARM filtering,
microcode removal, and `linux-aarch64` substitution, the generated AArch64
list has 116 packages. All 116 resolve from the actual Arch Linux ARM
repositories.

## Kernel Staging Blocker and Resolution

The kernel package layout required more than a package-name substitution:

- `linux-aarch64` owns `/boot/Image` and `/boot/Image.gz`;
- it does not install `/usr/lib/modules/<kver>/vmlinuz`;
- pinned archiso copies only `/boot/vmlinuz-*` and
  `/boot/initramfs-*.img`.

The ISO profile now carries an AArch64-only post-transaction hook. After
`linux-aarch64` installs, it:

1. stages `/boot/Image` as `/boot/vmlinuz-linux-aarch64`;
2. installs an archiso-specific `linux-aarch64.preset`;
3. builds `/boot/initramfs-linux-aarch64.img`;
4. removes the package preset's unused normal-host initramfs images.

This keeps the pinned archiso submodule unchanged and satisfies its existing
kernel-copy contract.

## Source Changes

The ISO source now:

- accepts `--arch x86_64|aarch64`, defaulting to x86_64;
- uses separate architecture caches and Docker platforms;
- selects `menci/archlinuxarm:latest` for AArch64;
- runs the pinned archiso source when the ARM repository has no `archiso`
  package;
- selects UEFI GRUB only on ARM;
- maps Node.js `linux-x64` to `linux-arm64`;
- transforms releng, target-bootstrap, base, and optional package lists;
- indexes both Arch Linux ARM `.pkg.tar.xz` archives and locally built
  `.pkg.tar.zst` archives in the offline repository;
- uses Arch Linux ARM `core`, `extra`, `alarm`, and `aur` repositories;
- selects `linux-aarch64` for both the live environment and target;
- selects Limine `BOOTAA64.EFI` and `limine_aa64.efi`;
- builds a local `omarchy-keyring` before contacting the absent published ARM
  repository when `--local-source` is used.

The target Omarchy source now:

- chooses architecture-correct pacman defaults during install and refresh;
- omits x86 multilib on ARM and retains Arch Linux ARM's `alarm` and `aur`
  repositories;
- selects the bundled Node.js `linux-arm64` archive during first-install
  finalization.

No source change was needed in `omarchy-pkgs` during this slice.

Committed source checkpoints:

```text
omarchy:      21d07dc2 Add ARM64 package and Node defaults
omarchy-pkgs: d0f3fdc8 unchanged
omarchy-iso:  1a7db27  Add generic AArch64 ISO inputs
```

## Verification

Passing checks:

```text
ISO Bash syntax checks
ISO Python byte compilation
ISO test/architecture-test.sh
Omarchy focused pacman-config test
Omarchy focused Node archive test
Omarchy full ./test/shell with sibling paths supplied
git diff --check in both changed repositories
```

The architecture test verifies:

- supported and rejected architecture values;
- Docker, Node, and kernel mappings;
- `linux-aarch64`, `linux-aarch64-headers`, and binfmt substitutions;
- ARM UEFI-only profile selection;
- `BOOTAA64.EFI` and `limine_aa64.efi`;
- the live-kernel hook and preset contract;
- ARM repository families with no multilib.

`./test/cli` has one pre-existing failure: upstream command
`omarchy-update-system-pkgs-when-conflicted` lacks an
`omarchy:summary`. That file is unchanged by this port.

`shellcheck` is not installed in the VM, so it could not be run. `bash -n`,
the focused tests, and the full shell suite cover the changed shell paths.

## Remaining Green-Build Blocker

No ISO was built. The published Omarchy AArch64 repository still returns
HTTP 404. The current local ISO package builder creates the keyring and three
top-level Omarchy packages, but a fresh ARM offline mirror still needs the
complete custom/provider package closure from `omarchy-pkgs`, including the
Limine hooks, Quickshell, fonts, and application providers.

The next source step is to make the local package builder produce that exact
AArch64 closure (or consume a published AArch64 repository), then run the
first real ISO build in a new disposable clone.

## Protected System Proof

The installed boot assets are unchanged:

```text
2662962bab816958bad80f3c24e275f2e306b984bdf1f81dc235342382c8048f  /boot/initramfs-linux.img
add658562939b9abb73bf6fe7865fb177cd8fbfa5a73479467cf3469da57ac44  /boot/limine.conf
6edf91b6ee62aff521de9666d6f8c790be086ecec48352f2dd580d66a6831dd3  /etc/mkinitcpio.conf
a0bf23d62d7d74bfa597e38af7cc841837ba4a353ed8f8b10b5dd3a69dab5814  /etc/mkinitcpio.d/linux-aarch64.preset
```

No package, service, migration marker, boot file, or filesystem state was
changed.
