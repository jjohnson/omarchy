# Quattro ARM64 Phase 8 First ISO Build

Date: 2026-07-30

## Scope

This phase ran in
`Quattro-ARM64-Phase-8-First-ISO-Build-Working-2026-07-30`. It used the
validated Phase 7 package cache to build and inspect the first Quattro
AArch64 ISO.

The build VM was not an installation target. No package was installed on the
host, no migration or finalizer ran, and the host kernel, initramfs, Limine
configuration, UEFI entries, partitions, filesystems, and installed package
set were not changed.

The ISO has not been booted. Boot and installation acceptance belong in a
separate disposable VM with a new blank disk.

## Preflight

The Phase 8 boot reproduced the protected Phase 7 state:

```text
kernel:             7.1.5-2-aarch64-ARCH
root filesystem:    Btrfs
installed packages: 979
explicit packages:  199
foreign packages:   37
orphans:            0
Quickshell IPC:      ok
Hyprland errors:     none
failed units:        zero system and user
renderer:            direct virgl (Apple M4 Pro), OpenGL 4.1
```

The repositories were clean and matched their pushed branches:

```text
omarchy:       2854bbb53d67da450e98093f3ad630cc6162ef01
omarchy-pkgs:  7f7cbb0f10c50ab60b801e283f778727bf55f229
omarchy-iso:   ac984c1d06bc39dc7aebaaa8c0b9f1641ccc6141
archiso v87:   424e78130db2af6c1ceb55b442d7914b1109ff2b
```

The Phase 7 cache still contained the 1,121-entry offline repository and the
separate build-only dependency cache.

## Host Cache Isolation

Before the full build, the normal ISO path was found to clear and bind-mount
the host's global `/var/cache/pacman/pkg`. That was unnecessary host mutation
for a container build.

The entrypoint now uses:

```text
~/.cache/omarchy/iso_<channel>_<architecture>/pacman/pkg
```

as the container package cache. The host pacman cache is neither cleared nor
mounted. Focused tests enforce that boundary. The change is pushed in:

```text
68e4bc4d4448e68bfc1f52d6b70c41bbb19e547f
```

The host cache remained exactly 2,132 archives and 2,765,056,410 regular-file
bytes through both build attempts.

## First Build Attempt

The first full command reached the live-root package transaction and exposed
two AArch64 Archiso incompatibilities:

1. The releng initramfs configuration included x86-only `microcode` and
   `memdisk` hooks. `memdisk` required the unavailable `phram` module and
   `memdiskfind` binary.
2. Pinned Archiso asked `grub-mkstandalone -O arm64-efi` to preload seven
   modules that the Arch Linux ARM GRUB package does not ship:

   ```text
   at_keyboard
   keylayouts
   usb
   usbserial_common
   usbserial_ftdi
   usbserial_pl2303
   usbserial_usbdebug
   ```

The first attempt stopped at `at_keyboard.mod` and did not produce an ISO.

The source fix:

- copies pinned `mkarchiso` to a temporary writable path and applies an
  AArch64-only patch;
- filters preloaded GRUB modules against the selected `arm64-efi` module
  directory, with one warning for each omission;
- leaves the pinned Archiso submodule unchanged;
- removes only `microcode` and `memdisk` from the AArch64 live initramfs;
- masks the package's normal host-style mkinitcpio hook during the live-root
  package transaction;
- stages `/boot/Image` and builds only the `linux-aarch64` Archiso preset;
- restores the normal package hook and removes the build-only hook from the
  live environment.

The focused architecture test, Bash syntax checks, patched `mkarchiso` syntax
check, and `git diff --check` passed. The fix is pushed in:

```text
cfe5c344f019bb33e0956636a7cc5599b841f123
```

## Bootloader Boundary

GRUB is used only as Archiso's live-media UEFI launcher. It creates
`EFI/BOOT/BOOTAA64.EFI` so generic UEFI firmware can start the installer ISO.

It is not the installed Omarchy bootloader:

- the AArch64 target bootstrap list contains `limine` and no `grub`;
- both generated installer modes select Limine;
- the orchestrator rejects non-Limine target bootloader setup;
- AArch64 target installation copies `BOOTAA64.EFI` from the Limine package
  as `limine_aa64.efi`;
- finalization runs `limine-update` and validates the Omarchy entry, ESP,
  Snapper configuration, root command line, and encrypted `cryptdevice=`
  propagation.

The Phase 8 patch changes only the disposable ISO launcher. It does not alter
the target Limine, encryption, snapshot, or rollback workflow.

## Successful Build

The second full command was:

```bash
cd ~/Projects/omarchy-iso-quattro-arm64
./bin/omarchy-iso-make --arch aarch64 --no-boot-offer \
  --local-source ~/Projects/omarchy-quattro-arm64 \
  ~/Projects/omarchy-pkgs-quattro-arm64
```

The package builder reused the completed native artifacts. The source-backed
packages were:

```text
omarchy-dev           4.0.0.r1489.g2854bbb-1  any
omarchy-settings-dev  4.0.0.r1489.g2854bbb-1  any
quickshell-git        0.3.0.r18.g10b439f-3    aarch64
```

The real live-root transaction built one successful initramfs:

```text
preset:      linux-aarch64
kernel:      7.1.5-2-aarch64-ARCH
mkinitcpio:  41
compression: gzip
size:        198,966,783 bytes
```

The remaining `ast`, `nfp`, `qla*`, and similar messages are missing optional
firmware warnings for unrelated hardware drivers. There was no incomplete
initramfs error.

The complete build log is:

```text
~/utm/quattro-phase8-iso-build-2.log
```

## Artifact Inspection

The generated artifact is:

```text
~/Projects/omarchy-iso-quattro-arm64/release/omarchy-2026.07.30-aarch64-local.iso
size:    4,688,142,336 bytes
SHA-256: e579204b4c39fd36837c9a470bee4d7662bd04cda6ba39d546f46ad1fc4ca53c
label:   OMARCHY_202607
```

It has a GPT with a 4.4 GiB ISO/data partition and a 16 MiB EFI System
Partition. Both the ISO filesystem and the ESP contain the same
`BOOTAA64.EFI`:

```text
type:    PE32+ EFI application, ARM64
size:    7,778,304 bytes
SHA-256: 7635c958f5dc8d51eb0d5e9408fba158d2de1862361d1e0090aeaec916d58ae5
```

The boot payload is architecture-correct:

```text
kernel:
  type:    Linux kernel ARM64 boot executable Image
  size:    44,100,096 bytes
  SHA-256: f208d7f3d2e759be71f3a6a39a7c5b2193d9e3ed15b81ddccf89e72e7e17ccd9

initramfs:
  kernel:  7.1.5-2-aarch64-ARCH
  size:    198,966,783 bytes
  SHA-256: 207eaaca7ed2772b08238184264f4cc393ba5f4b40b7f66de5b3fe4b65cface9

SquashFS:
  size:    4,420,288,512 bytes
  SHA-256: 2739c2451bef451338f10d5e1b56c142a0ffc7e22eecc3453eeccff51c92f405
  SHA-512: e8d4c4dd96b120a2013c2e6501d93b46b1bb4765abe864e3ec21ac80221b7b661d9283e78830d9d6938685af746999849f63c2a1041cf9b5e8c40d24593cb0df
```

The embedded SHA-512 self-test passed. The initramfs contains the Archiso,
loop-mount, Plymouth, SquashFS, OverlayFS, ISO9660, Virtio GPU, Virtio
network, and generic input/storage support required by the UTM profile.
`phram`, `memdiskfind`, and the memdisk hook are absent.

The live package manifest contains 464 packages, including
`linux-aarch64 7.1.5-2`, `mkinitcpio-archiso 73-1`, and
`omarchy-settings-dev`. It contains no stock `linux`, `linux-t2`,
`amd-ucode`, or `intel-ucode`.

SquashFS inspection proved:

```text
target install resolution: 928 packages
offline package archives:  1121
offline DB entries:        1121
package signatures:        1084
Gradle runtime archives:      0
build-only ARM hooks:          0
```

Representative embedded package metadata is `aarch64` or `any`, including
the kernel, Quickshell, both Omarchy packages, and the two Limine helpers.

## Host-Share Backup

The ISO was copied to the macOS/UTM shared directory:

```text
~/utm/omarchy-2026.07.30-aarch64-local.iso
~/utm/omarchy-2026.07.30-aarch64-local.iso.sha256
```

An independent read-back produced the same SHA-256 as the in-VM source. This
is the copy to attach to the separate installer-test VM.

## Protected Host Proof

After the complete build and inspection:

```text
installed packages: 979
explicit packages:  199
foreign packages:   37
orphans:            0
Quickshell IPC:      ok
Hyprland errors:     none
failed units:        zero system and user
renderer:            direct virgl (Apple M4 Pro), OpenGL 4.1
available memory:    approximately 10 GiB
available disk:      approximately 43 GiB
```

The protected hashes remain exact:

```text
2662962bab816958bad80f3c24e275f2e306b984bdf1f81dc235342382c8048f  /boot/initramfs-linux.img
add658562939b9abb73bf6fe7865fb177cd8fbfa5a73479467cf3469da57ac44  /boot/limine.conf
6edf91b6ee62aff521de9666d6f8c790be086ecec48352f2dd580d66a6831dd3  /etc/mkinitcpio.conf
a0bf23d62d7d74bfa597e38af7cc841837ba4a353ed8f8b10b5dd3a69dab5814  /etc/mkinitcpio.d/linux-aarch64.preset
```

## Next Boundary

Phase 8 is complete. Preserve the powered-off build VM as:

```text
Quattro-ARM64-Phase-8-First-ISO-Build-Complete-2026-07-30
```

Create a separate new disposable UTM VM as:

```text
Quattro-ARM64-Phase-9-Installer-Test-Working-2026-07-30
```

Give Phase 9 a new blank virtual disk and attach the shared ISO. Do not clone
the Phase 8 disk as the installer target, and do not attach any disk from the
gold, proof, package-closure, or build VMs.

Phase 9 should first prove ISO UEFI boot, live-media discovery, the installer
UI, network, and graphics. Only then should it perform a full install to its
own blank disk and validate the installed AArch64 kernel, Limine,
encryption/snapshot behavior, first boot, and Quattro desktop.
