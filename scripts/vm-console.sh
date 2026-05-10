#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=vm-console
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command virsh
validate_vm_config
require_libvirt_connection
require_project_owned_domain_if_exists
domain_exists || die "domain is not defined; run make vm-define first: $VM_NAME"

printf 'Opening virsh console for %s. Use Ctrl+] to exit.\n' "$VM_NAME"
printf 'If the ISO does not show a serial login, use make vm-viewer.\n'
exec virsh --connect "$LIBVIRT_URI" console "$VM_NAME"
