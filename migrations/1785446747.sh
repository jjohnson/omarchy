echo "Enable clipboard sharing between SPICE and Wayland sessions"

spice_port="${OMARCHY_SPICE_PORT:-/dev/virtio-ports/com.redhat.spice.0}"

systemctl --user daemon-reload
systemctl --user enable \
  omarchy-spice-clipboard-wayland-to-x11.service \
  omarchy-spice-clipboard-x11-to-wayland.service

if systemctl --user is-active --quiet graphical-session.target &&
  [[ -e $spice_port ]]; then
  systemctl --user restart \
    omarchy-spice-clipboard-wayland-to-x11.service \
    omarchy-spice-clipboard-x11-to-wayland.service
fi
