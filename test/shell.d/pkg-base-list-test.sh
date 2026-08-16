#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

manifest="$test_tmp/omarchy-base.packages"
cat >"$manifest" <<'PACKAGES'
# Package list fixture
curl
qemu-user-static-binfmt # Architecture-specific provider

ripgrep
PACKAGES

expected_x86=$'curl\nqemu-user-static-binfmt\nripgrep'
actual_x86=$(OMARCHY_PATH="$ROOT" "$ROOT/bin/omarchy-pkg-base-list" x86_64 "$manifest")
[[ $actual_x86 == "$expected_x86" ]] ||
  fail "x86_64 base package names remain unchanged" "$actual_x86"
pass "x86_64 base package names remain unchanged"

expected_aarch64=$'curl\nqemu-user-binfmt\nripgrep'
for architecture in aarch64 arm64; do
  actual_aarch64=$(OMARCHY_PATH="$ROOT" "$ROOT/bin/omarchy-pkg-base-list" "$architecture" "$manifest")
  [[ $actual_aarch64 == "$expected_aarch64" ]] ||
    fail "$architecture base packages use the repository binfmt provider" "$actual_aarch64"
done
pass "AArch64 base packages use the repository binfmt provider"
