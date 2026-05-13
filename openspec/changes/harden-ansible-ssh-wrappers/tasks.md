## 1. Inventory Current SSH Usage

- [ ] 1.1 List every `ansible-playbook`, `ansible`, `ssh`, and `rsync` wrapper invocation that connects to the live ISO or installed VM.
- [ ] 1.2 Identify which invocations should use the shared Ansible SSH transport policy and which are VM-only helpers with separate behavior.
- [ ] 1.3 Confirm global `ansible.cfg` keeps host-key checking enabled by default.

## 2. Shared SSH Transport Helper

- [ ] 2.1 Add a shared shell helper that validates SSH transport variables.
- [ ] 2.2 Generate one reusable Ansible `--ssh-common-args` value from the validated variables, using the approved defaults when unset.
- [ ] 2.3 Keep temporary live ISO host-key relaxation scoped to wrapper invocations only.
- [ ] 2.4 Ensure project-local control socket directories are created only when needed and are safe to clean.

## 3. Makefile Integration

- [ ] 3.1 Add documented defaults for `ANSIBLE_SSH_CONNECT_TIMEOUT=10`, `ANSIBLE_SSH_SERVER_ALIVE_INTERVAL=30`, `ANSIBLE_SSH_SERVER_ALIVE_COUNT_MAX=6`, `ANSIBLE_SSH_CONTROL_MASTER=auto`, `ANSIBLE_SSH_CONTROL_PERSIST=10m`, and `ANSIBLE_SSH_CONTROL_PATH_DIR=var/ssh-control`.
- [ ] 3.2 Expose the new variables in `make help`.
- [ ] 3.3 Ensure operator-facing Ansible targets pass the shared SSH policy through the wrapper layer.

## 4. Wrapper Migration

- [ ] 4.1 Replace duplicated `--ssh-common-args` strings in Ansible wrapper scripts with the shared helper output.
- [ ] 4.2 Keep VM-only helpers aligned where they connect to the temporary live ISO, without making reusable Ansible roles depend on libvirt.
- [ ] 4.3 Preserve existing `ANSIBLE_LIVE_HOST`, `ANSIBLE_LIVE_PORT`, and `ANSIBLE_LIVE_USER` behavior.

## 5. Documentation

- [ ] 5.1 Update README or workflow docs with the new SSH transport variables and defaults.
- [ ] 5.2 Update Ansible live ISO and libvirt docs with `tmux` or `screen` guidance.
- [ ] 5.3 Update `skills/ansible-gentoo-installer.md` with wrapper hardening expectations.
- [ ] 5.4 Update `skills/makefile-control-plane.md` with variable documentation rules for SSH transport controls.

## 6. Validation

- [ ] 6.1 Run `make ansible-check`.
- [ ] 6.2 Run `make secret-check`.
- [ ] 6.3 Run `make release-check`.
- [ ] 6.4 Run `openspec validate harden-ansible-ssh-wrappers --strict`.
- [ ] 6.5 Run `openspec validate --all --strict`.
