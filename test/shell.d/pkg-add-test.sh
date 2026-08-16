#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

stub_bin="$test_tmp/bin"
sync_dir="$test_tmp/sync"
log_file="$test_tmp/calls"
ready_file="$test_tmp/ready"
mkdir -p "$stub_bin" "$sync_dir"

cat >"$stub_bin/pacman-conf" <<'SH'
#!/bin/bash
printf '%s\n' core extra omarchy
SH
chmod +x "$stub_bin/pacman-conf"

for repository in core extra omarchy; do
  printf 'database\n' >"$sync_dir/$repository.db"
done

PATH="$stub_bin:$PATH" \
  OMARCHY_PACMAN_SYNC_DIR="$sync_dir" \
  "$ROOT/bin/omarchy-pkg-repositories-ready" ||
  fail "complete repository databases are ready"
pass "complete repository databases are ready"

rm "$sync_dir/omarchy.db"
if PATH="$stub_bin:$PATH" \
  OMARCHY_PACMAN_SYNC_DIR="$sync_dir" \
  "$ROOT/bin/omarchy-pkg-repositories-ready"; then
  fail "a missing configured repository database is rejected"
fi
pass "a missing configured repository database is rejected"

cat >"$stub_bin/omarchy-pkg-missing" <<'SH'
#!/bin/bash
[[ ${TEST_PACKAGE_INSTALLED:-0} != 1 ]]
SH

cat >"$stub_bin/omarchy-pkg-repositories-ready" <<'SH'
#!/bin/bash
[[ -f $TEST_READY_FILE ]]
SH

cat >"$stub_bin/omarchy-update-system-pkgs" <<'SH'
#!/bin/bash
printf 'update\n' >>"$TEST_LOG"
[[ ${TEST_UPDATE_FAILS:-0} != 1 ]] || exit 1
[[ ${TEST_UPDATE_LEAVES_MISSING:-0} == 1 ]] || touch "$TEST_READY_FILE"
SH

cat >"$stub_bin/pacman" <<'SH'
#!/bin/bash
printf 'pacman %s\n' "$*" >>"$TEST_LOG"
SH

cat >"$stub_bin/sudo" <<'SH'
#!/bin/bash
printf 'sudo %s\n' "$*" >>"$TEST_LOG"
"$@"
SH

chmod +x "$stub_bin"/*

run_pkg_add() {
  TEST_LOG="$log_file" \
    TEST_READY_FILE="$ready_file" \
    TEST_PACKAGE_INSTALLED="${TEST_PACKAGE_INSTALLED:-0}" \
    TEST_UPDATE_FAILS="${TEST_UPDATE_FAILS:-0}" \
    TEST_UPDATE_LEAVES_MISSING="${TEST_UPDATE_LEAVES_MISSING:-0}" \
    PATH="$stub_bin:$PATH" \
    "$ROOT/bin/omarchy-pkg-add" tailscale
}

: >"$log_file"
touch "$ready_file"
run_pkg_add
[[ $(<"$log_file") == *'pacman -S --noconfirm --needed tailscale'* ]] ||
  fail "ready repositories install without a system update" "$(<"$log_file")"
if grep -qxF update "$log_file"; then
  fail "ready repositories skip the system update"
fi
pass "ready repositories install without a system update"

: >"$log_file"
rm "$ready_file"
run_pkg_add
[[ $(head -n 1 "$log_file") == "update" ]] ||
  fail "missing repositories run a full update first" "$(<"$log_file")"
grep -q 'pacman -S --noconfirm --needed tailscale' "$log_file" ||
  fail "package installation follows repository initialization" "$(<"$log_file")"
pass "missing repositories run a full update before package installation"

: >"$log_file"
rm "$ready_file"
if TEST_UPDATE_FAILS=1 run_pkg_add >/dev/null 2>&1; then
  fail "a failed full update blocks package installation"
fi
[[ $(<"$log_file") == "update" ]] ||
  fail "a failed full update does not attempt a partial install" "$(<"$log_file")"
pass "a failed full update blocks package installation"

: >"$log_file"
rm -f "$ready_file"
if TEST_UPDATE_LEAVES_MISSING=1 run_pkg_add >/dev/null 2>&1; then
  fail "repositories still missing after update block package installation"
fi
[[ $(<"$log_file") == "update" ]] ||
  fail "repositories still missing do not permit a partial install" "$(<"$log_file")"
pass "repositories still missing after update block package installation"

: >"$log_file"
rm -f "$ready_file"
TEST_PACKAGE_INSTALLED=1 run_pkg_add
if grep -qxF update "$log_file"; then
  fail "an already installed package does not initialize repositories"
fi
pass "an already installed package does not initialize repositories"
