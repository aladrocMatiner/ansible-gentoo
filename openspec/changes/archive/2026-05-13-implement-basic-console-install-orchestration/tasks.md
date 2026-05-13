# Tasks: implement-basic-console-install-orchestration

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [x] Validate with `openspec validate implement-basic-console-install-orchestration --strict`.

## Implementation
- [x] Apply Ansible quality standards: FQCN, named tasks, module-first behavior, guarded command-like tasks, idempotency, check/diff behavior, and secret handling.
- [x] Run `make ansible-check` and record syntax/lint result.
- [x] Add shared install playbook.
- [x] Add thin OpenRC/systemd playbooks.
- [x] Add Makefile targets.
- [x] Run config validation before full install execution.
- [x] Reference target system baseline in orchestration checks.
- [x] Wire the shared install run id through implemented roles for per-phase evidence; durable resume checkpoint files remain owned by `implement-install-state-and-resume-checkpoints`.
- [x] Reference the future audit bundle path; bundle assembly remains owned by `implement-install-audit-bundle`.
- [x] Check Handbook traceability for the shared role sequence.
- [x] Update docs and skills.
- [x] Validate both profiles in VM.

## Validation Notes
- `make ansible-check` passed; `ansible-lint` was not installed, so syntax checks ran and lint was skipped.
- `make install-openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda ADMIN_USER=gentoo ENABLE_SSH=no I_UNDERSTAND_THIS_WIPES_DISK=yes I_UNDERSTAND_BOOTLOADER_CHANGES=yes` passed in the disposable libvirt VM with final checks `PASS`.
- `make install-systemd FILESYSTEM=btrfs INSTALL_DISK=/dev/vda ADMIN_USER=gentoo ENABLE_SSH=no I_UNDERSTAND_THIS_WIPES_DISK=yes I_UNDERSTAND_BOOTLOADER_CHANGES=yes` passed in the disposable libvirt VM with final checks `PASS`.
