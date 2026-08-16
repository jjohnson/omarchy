architecture="${OMARCHY_ARCHITECTURE:-$(uname -m)}"
if [[ $architecture == "aarch64" || $architecture == "arm64" ]]; then
  system_root="${OMARCHY_SYSTEM_ROOT:-}"
  graphics_sysfs="${OMARCHY_GRAPHICS_SYSFS:-/sys/class/graphics}"
  install -Dm644 \
    "$OMARCHY_INSTALL/hardware/99-omarchy-aarch64-kernel.hook" \
    "$system_root/etc/pacman.d/hooks/99-omarchy-aarch64-kernel.hook"

  plymouth_dropin="$system_root/etc/limine-entry-tool.d/aarch64-virtio-plymouth.conf"

  virtio_framebuffer=false
  for name_file in "$graphics_sysfs"/fb*/name; do
    [[ -f $name_file ]] || continue
    [[ $(<"$name_file") == "virtio_gpudrmfb" ]] || continue
    virtio_framebuffer=true
    break
  done

  if [[ $virtio_framebuffer == true ]]; then
    mkdir -p "$(dirname -- "$plymouth_dropin")"
    printf '%s\n' \
      'KERNEL_CMDLINE[default]+=" plymouth.ignore-serial-consoles"' \
      >"$plymouth_dropin"
  else
    rm -f "$plymouth_dropin"
  fi
fi
