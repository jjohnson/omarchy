#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

mkdir -p "$test_tmp/bin"

write_mock() {
  local name="$1"
  shift
  printf '%s\n' '#!/bin/bash' "$@" > "$test_tmp/bin/$name"
  chmod +x "$test_tmp/bin/$name"
}

write_mock systemctl 'printf "%s\n" "$*" >> "$OMARCHY_TEST_SYSTEMCTL_LOG"'

run_enable_services() {
  PATH="$test_tmp/bin:$PATH" \
    OMARCHY_SPICE_PORT="$1" \
    OMARCHY_TEST_SYSTEMCTL_LOG="$test_tmp/systemctl.log" \
    /bin/bash -c "source '$ROOT/install/config/enable-services.sh'"
}

spice_port="$test_tmp/com.redhat.spice.0"
touch "$spice_port"
run_enable_services "$spice_port"

grep -Fx 'add-wants sockets.target spice-vdagentd.socket' \
  "$test_tmp/systemctl.log" >/dev/null ||
  fail "SPICE guests persist the vdagent socket dependency"
pass "SPICE guests persist the vdagent socket dependency"

: > "$test_tmp/systemctl.log"
rm "$spice_port"
run_enable_services "$spice_port"

if grep -F 'spice-vdagentd.socket' "$test_tmp/systemctl.log" >/dev/null; then
  fail "non-SPICE systems leave the vdagent socket disabled"
fi
pass "non-SPICE systems leave the vdagent socket disabled"

wayland_to_x11="$ROOT/bin/omarchy-clipboard-spice-wayland-to-x11"
x11_to_wayland="$ROOT/bin/omarchy-clipboard-spice-x11-to-wayland"
wayland_unit="$ROOT/default/systemd/user/omarchy-spice-clipboard-wayland-to-x11.service"
x11_unit="$ROOT/default/systemd/user/omarchy-spice-clipboard-x11-to-wayland.service"
first_run_units="$ROOT/install/user/first-run/enable-user-units.sh"

bash -n "$wayland_to_x11" "$x11_to_wayland"
grep -Fx 'ConditionEnvironment=WAYLAND_DISPLAY' "$wayland_unit" >/dev/null
grep -Fx 'ConditionEnvironment=DISPLAY' "$wayland_unit" >/dev/null
grep -Fx 'ConditionPathExists=/dev/virtio-ports/com.redhat.spice.0' "$wayland_unit" >/dev/null
grep -Fx 'ConditionEnvironment=WAYLAND_DISPLAY' "$x11_unit" >/dev/null
grep -Fx 'ConditionEnvironment=DISPLAY' "$x11_unit" >/dev/null
grep -Fx 'ConditionPathExists=/dev/virtio-ports/com.redhat.spice.0' "$x11_unit" >/dev/null
grep -F 'omarchy-spice-clipboard-wayland-to-x11.service' "$first_run_units" >/dev/null
grep -F 'omarchy-spice-clipboard-x11-to-wayland.service' "$first_run_units" >/dev/null
pass "SPICE clipboard bridges are session-gated and enabled for fresh users"

clipboard_migration="$ROOT/migrations/1785446747.sh"
: > "$test_tmp/systemctl.log"
touch "$spice_port"
PATH="$test_tmp/bin:$PATH" \
  OMARCHY_SPICE_PORT="$spice_port" \
  OMARCHY_TEST_SYSTEMCTL_LOG="$test_tmp/systemctl.log" \
  /bin/bash -euo pipefail "$clipboard_migration" >/dev/null
grep -F 'enable omarchy-spice-clipboard-wayland-to-x11.service omarchy-spice-clipboard-x11-to-wayland.service' \
  "$test_tmp/systemctl.log" >/dev/null ||
  fail "clipboard migration does not enable both bridge services"
grep -F 'restart omarchy-spice-clipboard-wayland-to-x11.service omarchy-spice-clipboard-x11-to-wayland.service' \
  "$test_tmp/systemctl.log" >/dev/null ||
  fail "clipboard migration does not start both bridges in an active SPICE session"
pass "existing SPICE users receive the clipboard bridges"

write_mock wl-paste '
while (( $# > 0 )); do
  if [[ $1 == "--watch" ]]; then
    shift
    break
  fi
  shift
done
printf "phase9-guest" | "$@"'
write_mock xclip '
for argument in "$@"; do
  if [[ $argument == "-o" ]]; then
    printf "phase9-host"
    exit 0
  fi
done
cat > "$OMARCHY_TEST_STATE/xclip-input"'

PATH="$test_tmp/bin:$PATH" OMARCHY_TEST_STATE="$test_tmp" "$wayland_to_x11"
[[ $(<"$test_tmp/xclip-input") == "phase9-guest" ]] ||
  fail "Wayland clipboard text was not copied into X11"
pass "Wayland clipboard text reaches SPICE's X11 selection"

write_mock clipnotify '
count_file="$OMARCHY_TEST_STATE/clipnotify-count"
count=0
[[ -f $count_file ]] && count=$(<"$count_file")
(( count < 2 )) || exit 1
printf "%s\n" "$((count + 1))" > "$count_file"'
write_mock wl-copy 'cat >> "$OMARCHY_TEST_STATE/wl-copy-output"'

PATH="$test_tmp/bin:$PATH" OMARCHY_TEST_STATE="$test_tmp" "$x11_to_wayland"
[[ $(<"$test_tmp/wl-copy-output") == "phase9-host" ]] ||
  fail "SPICE X11 clipboard text was not copied into Wayland"
pass "SPICE X11 clipboard text reaches Wayland without a feedback loop"
