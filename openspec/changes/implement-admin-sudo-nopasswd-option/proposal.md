# Proposal: implement-admin-sudo-nopasswd-option

## Summary

Add an explicit `ADMIN_SUDO_NOPASSWD` option for target admin sudo policy and enable it by default only for disposable libvirt end-to-end test installs through `VM_E2E_ADMIN_SUDO_NOPASSWD=yes`.

## Motivation

Current disposable VM installs create `testadmin` with SSH key access and sudo group membership, but no password hash. That means `sudo su -` fails because sudo requests a password that was never configured. For local test VMs, passwordless sudo is acceptable and improves operator debugging. For real installs, sudo should remain password-requiring by default unless the operator explicitly opts in.

## Problem Statement

The installer supports SSH key-based admin login without a password hash, but does not provide a safe documented way to make that admin account usable for privileged debugging in disposable VMs. Operators can SSH as the admin user, but cannot escalate with `sudo su -`.

## Scope

- Add `ADMIN_SUDO_NOPASSWD` as an explicit users/sudo policy variable.
- Keep default target behavior as password-requiring sudo for non-E2E installs.
- Add `VM_E2E_ADMIN_SUDO_NOPASSWD=yes` default for disposable libvirt E2E installs.
- Update users role, final checks, first-boot validation, config validation, docs, schema, and Makefile help.
- Record non-secret evidence indicating whether passwordless sudo was configured.

## Non-Goals

- Do not create, store, print, or commit plaintext passwords.
- Do not generate password hashes.
- Do not enable root SSH login.
- Do not weaken disk, bootloader, or host block-device safety gates.
- Do not modify already-created VMs automatically.

## Safety Considerations

- `ADMIN_SUDO_NOPASSWD=yes` changes persistent target sudo policy and is high-risk outside disposable tests.
- The default for normal installer workflows remains password-requiring sudo.
- The libvirt E2E default is scoped to disposable project-owned qcow2 VM installs.
- Final checks and first-boot validation must report and validate the chosen sudo mode.
- Secret handling remains unchanged: password hashes, SSH keys, and credentials must not be committed or logged.

## Acceptance Criteria

- `ADMIN_SUDO_NOPASSWD` is accepted with values `yes` or `no`.
- Normal `make install`, `make install-openrc`, `make install-systemd`, and `make configure-users` treat unset `ADMIN_SUDO_NOPASSWD` as `no`.
- `make vm-e2e-install` and `make vm-e2e-matrix` default to `ADMIN_SUDO_NOPASSWD=yes` via `VM_E2E_ADMIN_SUDO_NOPASSWD=yes`.
- The users role writes `NOPASSWD: ALL` only when the option is enabled.
- Final checks validate that sudoers matches the requested mode.
- First-boot validation checks `sudo -n true` when passwordless sudo is requested.
- Documentation explains the test default and the safer real-install default.
- `openspec validate implement-admin-sudo-nopasswd-option --strict` passes.
- `openspec validate --all --strict` passes.

## Affected Files

- `Makefile`
- `.env.example`
- `config/install-schema.yml`
- `scripts/config-check.sh`
- `scripts/ansible-users-inputs.sh`
- `scripts/ansible-configure-users.sh`
- `scripts/ansible-users-preview.sh`
- `scripts/ansible-install-basic-console.sh`
- `scripts/vm-e2e-install.sh`
- `scripts/vm-e2e-plan.py`
- `scripts/vm-validate-first-boot.sh`
- `scripts/install-report.py`
- `ansible/roles/common/users/tasks/main.yml`
- `ansible/roles/common/final_checks/tasks/main.yml`
- `ansible/playbooks/users-preview.yml`
- `ansible/playbooks/first-boot-validate.yml`
- `docs/`
- `skills/`
