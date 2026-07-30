# Configure pacman after package installation completes. Offline target package
# installs use the live ISO's offline pacman.conf until this final restore.
mapfile -t pacman_defaults < <(
  omarchy-pkg-pacman-config "$(uname -m)" "${OMARCHY_MIRROR:-stable}"
)
cp -f "${pacman_defaults[0]}" /etc/pacman.conf
cp -f "${pacman_defaults[1]}" /etc/pacman.d/mirrorlist

# omarchy-settings skips this override until cups-browsed is actually present
# to avoid pacman creating cups-browsed.conf.pacnew during ISO package install.
if [[ -f $OMARCHY_PATH/etc-overrides/cups-cups-browsed.conf && -d /etc/cups ]]; then
  cp -f "$OMARCHY_PATH/etc-overrides/cups-cups-browsed.conf" /etc/cups/cups-browsed.conf
  rm -f /etc/cups/cups-browsed.conf.pacnew
fi

source "$OMARCHY_INSTALL/hardware/pacman.sh"
