#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

stub_bin="$test_tmp/bin"
drm_path="$test_tmp/drm"
driver_path="$test_tmp/drivers/virtio_gpu"
card_path="$drm_path/card0"
connector_path="$drm_path/card0-Virtual-1"
spice_port="$test_tmp/com.redhat.spice.0"
eval_log="$test_tmp/hyprctl-eval.log"

mkdir -p "$stub_bin" "$driver_path" "$card_path/device/virtio1" "$connector_path"
ln -s "$driver_path" "$card_path/device/virtio1/driver"
touch "$spice_port"
printf 'connected\n' >"$connector_path/status"
printf '1512x909\n1280x800\n' >"$connector_path/modes"

cat >"$stub_bin/hyprctl" <<'SH'
#!/bin/bash

if [[ $1 == "monitors" && $2 == "all" && $3 == "-j" ]]; then
  printf '%s' "${OMARCHY_TEST_MONITORS_JSON}"
elif [[ $1 == "eval" ]]; then
  printf '%s\n' "$2" >>"$OMARCHY_TEST_HYPRCTL_EVAL_LOG"
else
  exit 1
fi
SH
chmod +x "$stub_bin/hyprctl"

run_sync() {
  local monitors_json="${OMARCHY_TEST_MONITORS_JSON:-}"

  if [[ -z $monitors_json ]]; then
    monitors_json='[
      {"name":"Virtual-1","disabled":false,"width":1280,"height":800,"x":32,"y":48,"scale":1.25}
    ]'
  fi

  PATH="$stub_bin:$PATH" \
    OMARCHY_DRM_PATH="$drm_path" \
    OMARCHY_SPICE_PORT="$spice_port" \
    OMARCHY_TEST_HYPRCTL_EVAL_LOG="$eval_log" \
    OMARCHY_TEST_MONITORS_JSON="$monitors_json" \
    "$ROOT/bin/omarchy-hyprland-spice-resize" sync
}

: >"$eval_log"
run_sync
grep -F 'output = "Virtual-1"' "$eval_log" >/dev/null || fail "SPICE resize targets the virtio-gpu output"
grep -F 'mode = "1512x909@60"' "$eval_log" >/dev/null || fail "SPICE resize applies the preferred connector dimensions"
grep -F 'position = "32x48"' "$eval_log" >/dev/null || fail "SPICE resize preserves monitor position"
grep -F 'scale = 1.25' "$eval_log" >/dev/null || fail "SPICE resize preserves monitor scale"
pass "SPICE resize applies a changed virtio-gpu preferred mode"

: >"$eval_log"
OMARCHY_TEST_MONITORS_JSON='[
  {"name":"Virtual-1","disabled":false,"width":1512,"height":909,"x":0,"y":0,"scale":1}
]' run_sync
[[ ! -s $eval_log ]] || fail "SPICE resize skips an already active preferred mode"
pass "SPICE resize avoids redundant monitor updates"

: >"$eval_log"
rm "$spice_port"
run_sync
[[ ! -s $eval_log ]] || fail "SPICE resize stays inactive without a SPICE port"
pass "SPICE resize requires a SPICE virtio port"

touch "$spice_port"
rm "$card_path/device/virtio1/driver"
ln -s "$test_tmp/drivers/not-virtio-gpu" "$card_path/device/virtio1/driver"
: >"$eval_log"
run_sync
[[ ! -s $eval_log ]] || fail "SPICE resize stays inactive without virtio-gpu"
pass "SPICE resize requires a virtio-gpu display"

ln -sfn "$driver_path" "$card_path/device/virtio1/driver"
printf 'disconnected\n' >"$connector_path/status"
: >"$eval_log"
run_sync
[[ ! -s $eval_log ]] || fail "SPICE resize ignores disconnected outputs"
pass "SPICE resize ignores disconnected outputs"
