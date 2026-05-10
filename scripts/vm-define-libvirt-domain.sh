#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=vm-define
source "$(dirname "$0")/vm-libvirt-common.sh"

network_xml() {
  if [[ "$VM_NET_MODE" == user ]]; then
    cat <<EOF
    <interface type='user'>
      <model type='virtio'/>
      <protocol type='tcp'>
        <source mode='bind' host='${VM_SSH_HOST}' service='${VM_SSH_HOST_PORT}'/>
        <target port='${VM_SSH_GUEST_PORT}'/>
      </protocol>
    </interface>
EOF
  else
    cat <<EOF
    <interface type='network'>
      <source network='${VM_NETWORK}'/>
      <model type='virtio'/>
    </interface>
EOF
  fi
}

load_vm_config
require_command virsh
require_command qemu-img
require_command qemu-system-x86_64
require_command isoinfo
validate_vm_config
ensure_artifact_dirs
require_libvirt_connection
require_project_owned_domain_if_exists

if [[ "$VM_NET_MODE" == network ]]; then
  virsh --connect "$LIBVIRT_URI" net-info "$VM_NETWORK" >/dev/null 2>&1 || die "libvirt network not found on $LIBVIRT_URI: $VM_NETWORK"
fi

resolved_iso=$(resolve_iso_path "$VM_ISO")

[[ -f "$VM_DISK" ]] || die "VM_DISK does not exist; run make vm-disk first: $VM_DISK"
assert_qcow2_image "$VM_DISK"
assert_safe_generated_file VM_XML "$VM_XML"
assert_safe_generated_file VM_NVRAM "$VM_NVRAM"
assert_safe_generated_file VM_KERNEL "$VM_KERNEL"
assert_safe_generated_file VM_INITRD "$VM_INITRD"

if domain_exists; then
  state=$(virsh --connect "$LIBVIRT_URI" domstate "$VM_NAME" 2>/dev/null || true)
  case "$state" in
    running|paused|blocked|idle)
      die "domain already exists and is active; run make vm-destroy before redefining: $VM_NAME"
      ;;
  esac
  virsh --connect "$LIBVIRT_URI" undefine "$VM_NAME" --nvram >/dev/null 2>&1 || virsh --connect "$LIBVIRT_URI" undefine "$VM_NAME" >/dev/null
fi

isoinfo -i "$resolved_iso" -R -x /boot/gentoo > "$VM_KERNEL"
isoinfo -i "$resolved_iso" -R -x /boot/gentoo.igz > "$VM_INITRD"

abs_iso=$(normalize_path "$resolved_iso")
abs_disk=$(normalize_path "$VM_DISK")
abs_xml=$(normalize_path "$VM_XML")
abs_kernel=$(normalize_path "$VM_KERNEL")
abs_initrd=$(normalize_path "$VM_INITRD")
emulator=$(command -v qemu-system-x86_64)

cat > "$VM_XML" <<EOF
<domain type='kvm'>
  <name>${VM_NAME}</name>
  <description>${PROJECT_MARKER}</description>
  <metadata>
    <gentoo-ai-installer xmlns='https://example.invalid/gentoo-ai-installer'>
      <managed>true</managed>
      <artifact-dir>${VM_DIR}</artifact-dir>
    </gentoo-ai-installer>
  </metadata>
  <memory unit='MiB'>${VM_RAM}</memory>
  <currentMemory unit='MiB'>${VM_RAM}</currentMemory>
  <vcpu placement='static'>${VM_CPUS}</vcpu>
  <os>
    <type arch='x86_64' machine='q35'>hvm</type>
    <kernel>${abs_kernel}</kernel>
    <initrd>${abs_initrd}</initrd>
    <cmdline>${VM_KERNEL_ARGS}</cmdline>
  </os>
  <features>
    <acpi/>
    <apic/>
  </features>
  <cpu mode='host-passthrough' check='none' migratable='on'/>
  <clock offset='utc'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>destroy</on_crash>
  <devices>
    <emulator>${emulator}</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='${abs_disk}'/>
      <target dev='vda' bus='virtio'/>
    </disk>
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <source file='${abs_iso}'/>
      <target dev='sda' bus='sata'/>
      <readonly/>
    </disk>
$(network_xml)
    <serial type='pty'>
      <target type='isa-serial' port='0'>
        <model name='isa-serial'/>
      </target>
    </serial>
    <console type='pty'>
      <target type='serial' port='0'/>
    </console>
    <graphics type='spice' autoport='yes'>
      <listen type='none'/>
    </graphics>
    <video>
      <model type='virtio'/>
    </video>
  </devices>
</domain>
EOF

virsh --connect "$LIBVIRT_URI" define "$abs_xml" >/dev/null
printf 'vm-define: defined project-owned libvirt domain %s on %s\n' "$VM_NAME" "$LIBVIRT_URI"
printf '  XML: %s\n' "$VM_XML"
printf '  ISO: %s\n' "$resolved_iso"
printf '  kernel: %s\n' "$VM_KERNEL"
printf '  initrd: %s\n' "$VM_INITRD"
printf '  disk: %s\n' "$VM_DISK"
