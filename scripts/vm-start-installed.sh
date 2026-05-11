#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=vm-start-installed
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
validate_vm_config
require_uefi_firmware
validate_artifact_paths
require_libvirt_connection

[[ -f "$VM_DISK" ]] || die "VM_DISK is missing; complete a VM install before first-boot validation: $VM_DISK"
assert_qcow2_image "$VM_DISK"
[[ -f "$VM_NVRAM" && ! -L "$VM_NVRAM" ]] || die "VM_NVRAM is missing or unsafe; run make vm-define before installing, then retry: $VM_NVRAM"

if [[ "$VM_NET_MODE" == network ]]; then
  virsh --connect "$LIBVIRT_URI" net-info "$VM_NETWORK" >/dev/null 2>&1 || die "libvirt network not found on $LIBVIRT_URI: $VM_NETWORK"
fi

if domain_exists; then
  require_project_marker_and_no_host_block_devices
  state=$(virsh --connect "$LIBVIRT_URI" domstate "$VM_NAME" 2>/dev/null || true)
  if [[ "$state" == running || "$state" == paused ]]; then
    virsh --connect "$LIBVIRT_URI" destroy "$VM_NAME"
  fi
  virsh --connect "$LIBVIRT_URI" undefine "$VM_NAME" --keep-nvram >/dev/null 2>&1 || virsh --connect "$LIBVIRT_URI" undefine "$VM_NAME" >/dev/null
fi

ensure_artifact_dirs
assert_safe_generated_file VM_XML "$VM_XML"

abs_disk=$(normalize_path "$VM_DISK")
abs_xml=$(normalize_path "$VM_XML")
abs_nvram=$(normalize_path "$VM_NVRAM")
abs_dir=$(normalize_path "$VM_DIR")
emulator=$(command -v qemu-system-x86_64)

cat > "$VM_XML" <<EOF
<domain type='kvm'>
  <name>${VM_NAME}</name>
  <description>${PROJECT_MARKER}</description>
  <metadata>
    <gentoo-ai-installer xmlns='https://example.invalid/gentoo-ai-installer'>
      <managed>true</managed>
      <artifact-dir>${VM_DIR}</artifact-dir>
      <boot-mode>installed-disk</boot-mode>
    </gentoo-ai-installer>
  </metadata>
  <memory unit='MiB'>${VM_RAM}</memory>
  <currentMemory unit='MiB'>${VM_RAM}</currentMemory>
  <vcpu placement='static'>${VM_CPUS}</vcpu>
  <os>
    <type arch='x86_64' machine='q35'>hvm</type>
    <loader readonly='yes' type='pflash'>${OVMF_CODE}</loader>
    <nvram>${abs_nvram}</nvram>
    <boot dev='hd'/>
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
      <boot order='1'/>
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
virsh --connect "$LIBVIRT_URI" start "$VM_NAME"

printf 'vm-start-installed: started %s from installed qcow2 disk\n' "$VM_NAME"
printf '  disk: %s\n' "$VM_DISK"
printf '  XML: %s\n' "$VM_XML"
printf '  note: run make vm-define to restore official live ISO boot mode later.\n'
