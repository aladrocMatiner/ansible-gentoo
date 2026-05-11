# Design: implement-basic-console-install-orchestration

## Shared Flow
The shared flow calls approved roles in Handbook order: preflight, disk safety, partitioning, filesystem, mount target, stage3, chroot, Portage, fstab, kernel, packages/services, users, bootloader, final checks.

The shared flow must also satisfy the project Ansible quality standards: FQCN modules, named tasks, module-first implementation, guarded command-like tasks, idempotency review, check/diff behavior, secret redaction, scoped host-key behavior, and `make ansible-check`.

The shared playbook owns orchestration only. It passes a single `install_run_id` through implemented roles so each phase writes non-secret evidence under the same run directory. Durable resume checkpoint files are owned by `implement-install-state-and-resume-checkpoints`, and audit bundle assembly is owned by `implement-install-audit-bundle`; this change only references those integration points.

## Variant Entrypoints
OpenRC and systemd playbooks set variant variables and call the shared flow.

## Makefile
Expose operator-facing install targets with explicit variables and confirmation requirements.
