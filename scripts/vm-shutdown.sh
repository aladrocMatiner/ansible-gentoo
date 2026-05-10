#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=vm-shutdown
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command virsh
validate_vm_config
require_libvirt_connection
require_project_owned_domain_if_exists
domain_exists || die "domain is not defined: $VM_NAME"
virsh --connect "$LIBVIRT_URI" shutdown "$VM_NAME"
