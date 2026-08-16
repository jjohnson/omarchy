#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

expected_x86=$(printf '%s\n%s' \
  "$ROOT/default/pacman/pacman-edge.conf" \
  "$ROOT/default/pacman/mirrorlist-edge")
actual_x86=$(OMARCHY_PATH="$ROOT" "$ROOT/bin/omarchy-pkg-pacman-config" x86_64 edge)
[[ $actual_x86 == "$expected_x86" ]] ||
  fail "x86_64 keeps the channel-specific Omarchy mirrors" "$actual_x86"
pass "x86_64 keeps the channel-specific Omarchy mirrors"

expected_aarch64=$(printf '%s\n%s' \
  "$ROOT/default/pacman/pacman-edge-aarch64.conf" \
  "$ROOT/default/pacman/mirrorlist-aarch64")
for architecture in aarch64 arm64; do
  actual_aarch64=$(OMARCHY_PATH="$ROOT" "$ROOT/bin/omarchy-pkg-pacman-config" "$architecture" edge)
  [[ $actual_aarch64 == "$expected_aarch64" ]] ||
    fail "$architecture selects Arch Linux ARM package defaults" "$actual_aarch64"
done
pass "AArch64 selects Arch Linux ARM package defaults"

if OMARCHY_PATH="$ROOT" "$ROOT/bin/omarchy-pkg-pacman-config" riscv64 edge >/dev/null 2>&1; then
  fail "unsupported package architectures are rejected"
fi
pass "unsupported package architectures are rejected"

for channel in stable rc edge; do
  config="$ROOT/default/pacman/pacman-$channel-aarch64.conf"
  if grep -q '^\[multilib\]$' "$config"; then
    fail "$channel AArch64 package defaults exclude multilib"
  fi
  for repository in core extra alarm aur omarchy; do
    grep -q "^\\[$repository\\]$" "$config" ||
      fail "$channel AArch64 package defaults include $repository"
  done
done
pass "AArch64 package defaults include the Arch Linux ARM repositories"
