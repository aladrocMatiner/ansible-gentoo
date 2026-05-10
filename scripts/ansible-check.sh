#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=ansible-check
source "$(dirname "$0")/vm-libvirt-common.sh"

require_command ansible
require_command ansible-playbook

printf '%s\n' 'Checking Ansible syntax for implemented playbooks...'
ansible-playbook -i ansible/inventory/live.yml ansible/playbooks/live-preflight.yml --syntax-check >/dev/null
ansible-playbook -i ansible/inventory/live.yml ansible/playbooks/detect-disks.yml --syntax-check >/dev/null
ansible-playbook -i ansible/inventory/live.yml ansible/playbooks/install-plan.yml --syntax-check >/dev/null
ansible-playbook -i ansible/inventory/live.yml ansible/playbooks/partition-plan.yml --syntax-check >/dev/null
ansible-playbook -i ansible/inventory/live.yml ansible/playbooks/mount-plan.yml --syntax-check >/dev/null
ansible-playbook -i ansible/inventory/live.yml ansible/playbooks/filesystem-plan.yml --syntax-check >/dev/null
printf '%s\n' 'Ansible tooling and syntax checks passed.'
