#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=ansible-destructive-preview
source "$(dirname "$0")/vm-libvirt-common.sh"

preview_target=${PREVIEW_TARGET:-}
case "$preview_target" in
  partition)
    INSTALL_STATE_DISABLED=true scripts/ansible-partition-plan.sh
    ;;
  format|filesystem)
    INSTALL_STATE_DISABLED=true scripts/ansible-filesystem-plan.sh
    ;;
  mount)
    INSTALL_STATE_DISABLED=true scripts/ansible-mount-plan.sh
    ;;
  bootloader)
    scripts/ansible-bootloader-preview.sh
    ;;
  user|users|password|passwords)
    scripts/ansible-users-preview.sh
    ;;
  "")
    die_code CONFIG_INVALID "PREVIEW_TARGET is required: partition, format, mount, bootloader, or users"
    ;;
  *)
    die_code CONFIG_INVALID "unsupported PREVIEW_TARGET: $preview_target"
    ;;
esac
