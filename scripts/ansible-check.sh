#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=ansible-check
source "$(dirname "$0")/vm-libvirt-common.sh"

require_command ansible
require_command ansible-playbook

printf '%s\n' 'Checking Ansible syntax for implemented playbooks...'
for playbook in ansible/playbooks/*.yml; do
  ansible-playbook -i ansible/inventory/live.yml "$playbook" --syntax-check >/dev/null
done

if command -v ansible-lint >/dev/null 2>&1; then
  printf '%s\n' 'Running ansible-lint for implemented Ansible content...'
  ansible-lint ansible
else
  printf '%s\n' 'ansible-lint not found; syntax checks passed but lint gate was skipped.'
fi

printf '%s\n' 'Ansible tooling checks completed.'
