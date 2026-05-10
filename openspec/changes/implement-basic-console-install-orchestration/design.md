# Design: implement-basic-console-install-orchestration

## Shared Flow
The shared flow calls approved roles in Handbook order: preflight, disk safety, partitioning, filesystem, mount target, stage3, chroot, Portage, fstab, kernel, packages/services, users, bootloader, final checks.

The shared flow must also satisfy the project Ansible quality standards: FQCN modules, named tasks, module-first implementation, guarded command-like tasks, idempotency review, check/diff behavior, secret redaction, scoped host-key behavior, and `make ansible-check`.

## Variant Entrypoints
OpenRC and systemd playbooks set variant variables and call the shared flow.

## Makefile
Expose operator-facing install targets with explicit variables and confirmation requirements.
