## Why

The installer is controller-driven over SSH, so transient network stalls, slow live ISO responses, and long-running Gentoo tasks can currently break an otherwise valid installation run. The current wrappers repeat short SSH option strings in many places and do not expose a documented operator policy for keepalives, connection reuse, or timeout tuning.

This change makes SSH transport behavior explicit, configurable, and consistent for Ansible wrapper targets without changing the installer sequence or adding new installation automation.

## What Changes

- Add a shared SSH transport policy for Ansible wrapper scripts that connect from the operator/controller to a temporary official Gentoo live ISO.
- Centralize construction of Ansible `--ssh-common-args` instead of repeating ad hoc SSH options in each wrapper.
- Add Makefile variables for SSH timeouts, keepalives, and connection reuse:
  - `ANSIBLE_SSH_CONNECT_TIMEOUT`
  - `ANSIBLE_SSH_SERVER_ALIVE_INTERVAL`
  - `ANSIBLE_SSH_SERVER_ALIVE_COUNT_MAX`
  - `ANSIBLE_SSH_CONTROL_MASTER`
  - `ANSIBLE_SSH_CONTROL_PERSIST`
  - `ANSIBLE_SSH_CONTROL_PATH_DIR`
- Preserve the existing security rule that global `ansible.cfg` must not disable host key checking.
- Keep temporary live ISO host-key relaxation scoped to wrapper invocations only.
- Document recommended operator usage from `tmux` or `screen` on the controller for long install runs.
- Document that this improves controller session and SSH transport robustness, but does not make target-side tasks automatically resumable.

## Capabilities

### New Capabilities

### Modified Capabilities

- `ansible-remote-control-plane`: define consistent SSH transport hardening requirements for controller-to-live-ISO Ansible wrappers.

## Impact

- Affected Makefile behavior:
  - expose documented SSH transport variables and defaults through `make help`.
- Affected scripts:
  - Ansible wrapper scripts under `scripts/ansible-*.sh`.
  - shared wrapper helpers in `scripts/vm-libvirt-common.sh` or an equivalent shared helper.
  - VM SSH helper scripts only where they share the same SSH target construction.
- Affected documentation:
  - `README.md` or relevant workflow docs.
  - `docs/live-iso-local-ansible.md`.
  - `docs/libvirt-manual-install-test.md`.
  - `docs/ansible-basic-console-install-orchestration.md`.
  - `skills/ansible-gentoo-installer.md`.
  - `skills/makefile-control-plane.md`.
- Affected validation:
  - `make ansible-check`.
  - `make release-check`.
  - `openspec validate harden-ansible-ssh-wrappers --strict`.
  - `openspec validate --all --strict`.
