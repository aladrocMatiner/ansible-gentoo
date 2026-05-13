#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=ansible-stage3-install
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command ansible-playbook
scripts/config-check.sh
require_ansible_live_target stage3-install

profile=${PROFILE:-openrc}
case "$profile" in
  openrc|systemd) ;;
  *) die "PROFILE must be 'openrc' or 'systemd', got: $profile" ;;
esac

filesystem=${FILESYSTEM:-ext4}
case "$filesystem" in
  ext4|btrfs) ;;
  *) die "FILESYSTEM must be 'ext4' or 'btrfs', got: $filesystem" ;;
esac

stage3_flavor=${STAGE3_FLAVOR:-standard}
case "$stage3_flavor" in
  standard|hardened|musl) ;;
  *) die "STAGE3_FLAVOR must be 'standard', 'hardened', or 'musl', got: $stage3_flavor" ;;
esac

stage3_mirror=${STAGE3_MIRROR:-https://distfiles.gentoo.org/releases/amd64/autobuilds}
stage3_cache_dir=${STAGE3_CACHE_DIR:-/tmp/gentoo-ai-installer/stage3}
project_root=$(pwd -P)
inventory_file=$(mktemp --suffix=.yml)
trap 'rm -f "$inventory_file"' EXIT

cat >"$inventory_file" <<EOF
all:
  hosts:
    gentoo_live:
      ansible_connection: ssh
      ansible_host: ${ANSIBLE_LIVE_HOST}
      ansible_port: ${ANSIBLE_LIVE_PORT}
      ansible_user: ${ANSIBLE_LIVE_USER}
      ansible_python_interpreter: auto_silent
EOF

printf 'Installing official Gentoo %s/%s stage3 on %s@%s port %s\n' "$profile" "$stage3_flavor" "$ANSIBLE_LIVE_USER" "$ANSIBLE_LIVE_HOST" "$ANSIBLE_LIVE_PORT"
printf 'Stage3 mirror: %s\n' "$stage3_mirror"
printf 'Stage3 live-ISO cache: %s\n' "$stage3_cache_dir"
printf '%s\n' 'This target downloads, verifies, and extracts stage3 into /mnt/gentoo. It does not chroot, configure Portage, install packages, create users, or install a bootloader.'

ssh_common_args=$(ansible_ssh_common_args)

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
  -i "$inventory_file" \
  --ssh-common-args="$ssh_common_args" \
  -e "profile=${profile}" \
  -e "filesystem=${filesystem}" \
  -e "stage3_flavor=${stage3_flavor}" \
  -e "stage3_mirror=${stage3_mirror}" \
  -e "stage3_cache_dir=${stage3_cache_dir}" \
  -e "project_root=${project_root}" \
  ansible/playbooks/stage3-install.yml
