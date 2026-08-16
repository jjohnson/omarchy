#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

system_root="$test_tmp/root"
mkdir -p \
  "$system_root/boot" \
  "$system_root/etc/kernel" \
  "$system_root/etc/mkinitcpio.d"
printf '%s\n' "fixture kernel" >"$system_root/boot/Image"
printf '%s\n' "fixture preset" >"$system_root/etc/mkinitcpio.d/linux-aarch64.preset"
printf '%s\n' \
  "cryptdevice=UUID=fixture:root root=/dev/mapper/root rootflags=subvol=@ rw" \
  >"$system_root/etc/kernel/cmdline"

cat >"$test_tmp/mkinitcpio" <<'MKINITCPIO'
#!/bin/bash
printf '%s\n' "$*" >"$OMARCHY_TEST_MKINITCPIO_LOG"
printf '%s\n' "fixture initramfs" >"$OMARCHY_SYSTEM_ROOT/boot/initramfs-linux.img"
MKINITCPIO

cat >"$test_tmp/limine-entry-tool" <<'LIMINE'
#!/bin/bash
printf '%s\n' "$*" >"$OMARCHY_TEST_LIMINE_LOG"
cat >"$OMARCHY_SYSTEM_ROOT/boot/limine.conf" <<'CONFIG'
/+Omarchy
  //linux-aarch64
  protocol: linux
  path: boot():/fixture/Image
  module_path: boot():/fixture/initramfs-linux.img
  cmdline: cryptdevice=UUID=fixture:root root=/dev/mapper/root rootflags=subvol=@ rw
CONFIG
LIMINE
chmod +x "$test_tmp/mkinitcpio" "$test_tmp/limine-entry-tool"

OMARCHY_ARCHITECTURE=aarch64 \
  OMARCHY_SYSTEM_ROOT="$system_root" \
  OMARCHY_MKINITCPIO_COMMAND="$test_tmp/mkinitcpio" \
  OMARCHY_LIMINE_ENTRY_TOOL_COMMAND="$test_tmp/limine-entry-tool" \
  OMARCHY_TEST_MKINITCPIO_LOG="$test_tmp/mkinitcpio.log" \
  OMARCHY_TEST_LIMINE_LOG="$test_tmp/limine.log" \
  "$ROOT/bin/omarchy-update-kernel-aarch64"

[[ $(<"$test_tmp/mkinitcpio.log") == "-p linux-aarch64" ]] ||
  fail "AArch64 updater rebuilds the linux-aarch64 preset"
pass "AArch64 updater rebuilds the linux-aarch64 preset"

expected_limine_args="--add-kernel linux-aarch64 $system_root/boot/initramfs-linux.img $system_root/boot/Image --comment linux-aarch64 --no-hooks"
[[ $(<"$test_tmp/limine.log") == "$expected_limine_args" ]] ||
  fail "AArch64 updater creates a native Limine Linux entry"
pass "AArch64 updater creates a native Limine Linux entry"

hook_root="$test_tmp/hook-root"
mkdir -p "$test_tmp/graphics/fb0" "$test_tmp/graphics/fb3"
printf '%s\n' "EFI VGA" >"$test_tmp/graphics/fb0/name"
printf '%s\n' "virtio_gpudrmfb" >"$test_tmp/graphics/fb3/name"
OMARCHY_ARCHITECTURE=aarch64 \
  OMARCHY_SYSTEM_ROOT="$hook_root" \
  OMARCHY_INSTALL="$ROOT/install" \
  OMARCHY_GRAPHICS_SYSFS="$test_tmp/graphics" \
  source "$ROOT/install/hardware/aarch64-kernel.sh"

cmp \
  "$ROOT/install/hardware/99-omarchy-aarch64-kernel.hook" \
  "$hook_root/etc/pacman.d/hooks/99-omarchy-aarch64-kernel.hook" ||
  fail "AArch64 hardware setup installs the kernel maintenance hook"
pass "AArch64 hardware setup installs the kernel maintenance hook"

[[ $(<"$hook_root/etc/limine-entry-tool.d/aarch64-virtio-plymouth.conf") == \
  'KERNEL_CMDLINE[default]+=" plymouth.ignore-serial-consoles"' ]] ||
  fail "AArch64 hardware setup keeps Plymouth graphical in VirtIO guests"
pass "AArch64 hardware setup keeps Plymouth graphical in VirtIO guests"

x86_root="$test_tmp/x86-root"
OMARCHY_ARCHITECTURE=x86_64 \
  OMARCHY_SYSTEM_ROOT="$x86_root" \
  OMARCHY_INSTALL="$ROOT/install" \
  OMARCHY_GRAPHICS_SYSFS="$test_tmp/graphics" \
  source "$ROOT/install/hardware/aarch64-kernel.sh"
[[ ! -e $x86_root ]] || fail "AArch64 hardware setup is dormant on x86_64"
pass "AArch64 hardware setup is dormant on x86_64"

MODULES=()
modinfo() {
  return 1
}
source "$ROOT/etc/mkinitcpio.conf.d/thunderbolt_module.conf"
(( ${#MODULES[@]} == 0 )) ||
  fail "mkinitcpio skips an unavailable AArch64 thunderbolt module"
pass "mkinitcpio skips an unavailable AArch64 thunderbolt module"

MODULES=()
modinfo() {
  return 0
}
source "$ROOT/etc/mkinitcpio.conf.d/thunderbolt_module.conf"
[[ ${MODULES[0]:-} == "thunderbolt" ]] ||
  fail "mkinitcpio retains thunderbolt on kernels that provide it"
pass "mkinitcpio retains thunderbolt on kernels that provide it"
