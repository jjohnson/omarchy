#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

run_architecture_case() {
  local architecture="$1"
  local node_arch="$2"
  local setup_context="$3"
  local version="24.4.1"
  local case_dir="$test_tmp/$architecture-$setup_context"
  local archive_root="$case_dir/archive/node-v$version-linux-$node_arch"
  local packages_dir="$case_dir/packages"
  local test_home="$case_dir/home"
  local test_bin="$case_dir/bin"
  local mise_log="$case_dir/mise.log"

  mkdir -p "$archive_root/bin" "$packages_dir" "$test_home" "$test_bin"
  printf '#!/bin/bash\n' >"$archive_root/bin/node"
  chmod 0755 "$archive_root/bin/node"
  tar -czf "$packages_dir/node-v$version-linux-$node_arch.tar.gz" \
    -C "$case_dir/archive" "node-v$version-linux-$node_arch"

  cat >"$test_bin/mise" <<'MISE'
#!/bin/bash
printf '%s\n' "$*" >>"$MISE_LOG"
MISE
  chmod 0755 "$test_bin/mise"

  HOME="$test_home" \
    PATH="$test_bin:$PATH" \
    MISE_LOG="$mise_log" \
    OMARCHY_ARCH="$architecture" \
    OMARCHY_PACKAGES_DIR="$packages_dir" \
    OMARCHY_SETUP_CONTEXT="$setup_context" \
    bash -c 'source "$1"' _ "$ROOT/install/user/mise-work.sh"

  [[ -x $test_home/.local/share/mise/installs/node/$version/bin/node ]] ||
    fail "$architecture extracts the bundled Node.js archive during $setup_context"
  grep -qxF "use -g node@$version" "$mise_log" ||
    fail "$architecture activates the bundled Node.js version during $setup_context"
  pass "$architecture installs bundled linux-$node_arch Node.js during $setup_context"
}

run_architecture_case x86_64 x64 iso-chroot
run_architecture_case aarch64 arm64 iso-chroot
run_architecture_case aarch64 arm64 provision-owner
