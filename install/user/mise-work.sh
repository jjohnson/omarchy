# Setup default work directory (and tries)
mkdir -p "$HOME/Work"
mkdir -p "$HOME/Work/tries"

cat >"$HOME/Work/.mise.toml" <<'EOF'
[env]
_.path = "{{ cwd }}/bin"
EOF

mise trust ~/Work/.mise.toml

if [[ ${OMARCHY_SETUP_CONTEXT:-runtime} == "iso-chroot" ]]; then
  OMARCHY_PACKAGES_DIR="${OMARCHY_PACKAGES_DIR:-/opt/packages}"

  case "${OMARCHY_ARCH:-$(uname -m)}" in
    x86_64)
      NODE_ARCH=x64
      ;;
    aarch64|arm64)
      NODE_ARCH=arm64
      ;;
    *)
      echo "Error: unsupported Node.js architecture $(uname -m)" >&2
      exit 1
      ;;
  esac

  NODE_TARBALL=$(find "$OMARCHY_PACKAGES_DIR" -name "node-v*-linux-${NODE_ARCH}.tar.gz" -type f 2>/dev/null | head -n1)
  if [[ -z $NODE_TARBALL ]]; then
    echo "Error: bundled Node.js linux-${NODE_ARCH} tarball missing from $OMARCHY_PACKAGES_DIR" >&2
    exit 1
  fi

  NODE_VERSION=$(basename "$NODE_TARBALL")
  NODE_VERSION="${NODE_VERSION#node-v}"
  NODE_VERSION="${NODE_VERSION%-linux-${NODE_ARCH}.tar.gz}"
  NODE_INSTALL_DIR="$HOME/.local/share/mise/installs/node/$NODE_VERSION"

  mkdir -p "$NODE_INSTALL_DIR"
  tar -xzf "$NODE_TARBALL" --strip-components=1 -C "$NODE_INSTALL_DIR"
  mise use -g node@"$NODE_VERSION"
else
  mise use -g node@latest
fi
