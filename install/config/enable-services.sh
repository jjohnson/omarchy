# Enable services only. Installs are followed by reboot, so don't start/reload
# daemons mid-install. UFW and hardware-gated services stay in their own scripts.
systemctl enable cups.service
systemctl enable cups-browsed.service
systemctl enable avahi-daemon.service
systemctl enable linux-modules-cleanup.service
systemctl enable docker.socket
systemctl enable systemd-resolved.service
systemctl enable NetworkManager.service
# Don't let network-online.target (pulled in by cups-browsed) hold up
# graphical.target waiting for DHCP/Wi-Fi association. Nothing in the session
# needs to block on the network. Mirrors the systemd-networkd-wait-online mask
# in install/hardware/network.sh.
systemctl mask NetworkManager-wait-online.service
systemctl enable power-profiles-daemon.service
systemctl enable sddm.service

# The package's static socket normally starts from a udev event when the SPICE
# Virtio port appears. During a fresh install the port can predate the package,
# leaving the socket and clipboard daemon inactive after reboot. Persist the
# socket dependency only for guests that actually expose the SPICE channel.
spice_port="${OMARCHY_SPICE_PORT:-/dev/virtio-ports/com.redhat.spice.0}"
if [[ -e $spice_port ]]; then
  systemctl add-wants sockets.target spice-vdagentd.socket
fi
