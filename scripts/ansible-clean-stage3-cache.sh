#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=ansible-clean-stage3-cache
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command ansible-playbook
scripts/config-check.sh
require_ansible_live_target clean-stage3-cache

stage3_cache_dir=${STAGE3_CACHE_DIR:-/tmp/gentoo-ai-installer/stage3}
target_mount=${TARGET_MOUNT:-/mnt/gentoo}
plan_only=${CLEAN_PLAN_ONLY:-no}

case "$plan_only" in
  yes|no) ;;
  *) die_code CONFIG_INVALID "CLEAN_PLAN_ONLY must be yes or no" ;;
esac

[[ "$stage3_cache_dir" == /tmp/gentoo-ai-installer/* ]] || die_code CLEANUP_PATH_INVALID "STAGE3_CACHE_DIR cleanup is allowed only under /tmp/gentoo-ai-installer on the live target: $stage3_cache_dir"
[[ "$stage3_cache_dir" != "/" ]] || die_code CLEANUP_PATH_INVALID "STAGE3_CACHE_DIR must not be /"
[[ "$stage3_cache_dir" != *".."* ]] || die_code CLEANUP_PATH_INVALID "STAGE3_CACHE_DIR must not contain parent traversal: $stage3_cache_dir"
[[ "$stage3_cache_dir" != "$target_mount" && "$stage3_cache_dir" != "$target_mount"/* ]] || die_code CLEANUP_PATH_INVALID "STAGE3_CACHE_DIR must not be inside TARGET_MOUNT: $stage3_cache_dir"
! has_glob_chars "$stage3_cache_dir" || die_code CLEANUP_PATH_INVALID "STAGE3_CACHE_DIR must not contain wildcard characters: $stage3_cache_dir"
! has_unsafe_chars "$stage3_cache_dir" || die_code CLEANUP_PATH_INVALID "STAGE3_CACHE_DIR contains unsafe characters: $stage3_cache_dir"

if [[ "$plan_only" == no && "${I_UNDERSTAND_CLEANUP_DELETE:-}" != DELETE ]]; then
  die_code CONFIRMATION_MISSING "clean-stage3-cache requires I_UNDERSTAND_CLEANUP_DELETE=DELETE"
fi

printf 'Stage3 cache cleanup on %s@%s port %s\n' "$ANSIBLE_LIVE_USER" "$ANSIBLE_LIVE_HOST" "$ANSIBLE_LIVE_PORT"
printf 'STAGE3_CACHE_DIR=%s\n' "$stage3_cache_dir"
printf 'mode=%s\n' "$([[ "$plan_only" == yes ]] && printf plan || printf clean)"

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
  -i ansible/inventory/live.yml \
  -u "$ANSIBLE_LIVE_USER" \
  --ssh-common-args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10" \
  -e "ansible_host=${ANSIBLE_LIVE_HOST}" \
  -e "ansible_port=${ANSIBLE_LIVE_PORT}" \
  -e "stage3_cache_dir=${stage3_cache_dir}" \
  -e "cleanup_plan_only=${plan_only}" \
  ansible/playbooks/clean-stage3-cache.yml
