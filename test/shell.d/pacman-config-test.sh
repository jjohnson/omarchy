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

expected_arm=$(printf '%s\n%s' \
  "$ROOT/default/pacman/pacman-edge-aarch64.conf" \
  "$ROOT/default/pacman/mirrorlist-aarch64")
actual_arm=$(OMARCHY_PATH="$ROOT" "$ROOT/bin/omarchy-pkg-pacman-config" aarch64 edge)
[[ $actual_arm == "$expected_arm" ]] ||
  fail "aarch64 selects Arch Linux ARM package defaults" "$actual_arm"
pass "aarch64 selects Arch Linux ARM package defaults"

if OMARCHY_PATH="$ROOT" "$ROOT/bin/omarchy-pkg-pacman-config" riscv64 edge >/dev/null 2>&1; then
  fail "unsupported package architectures are rejected"
fi
pass "unsupported package architectures are rejected"

if grep -q '^\[multilib\]$' "$ROOT/default/pacman/pacman-edge-aarch64.conf"; then
  fail "aarch64 package defaults exclude multilib"
fi
for repository in core extra alarm aur omarchy; do
  grep -q "^\\[$repository\\]$" "$ROOT/default/pacman/pacman-edge-aarch64.conf" ||
    fail "aarch64 package defaults include $repository"
done
pass "aarch64 package defaults include the Arch Linux ARM repositories"
