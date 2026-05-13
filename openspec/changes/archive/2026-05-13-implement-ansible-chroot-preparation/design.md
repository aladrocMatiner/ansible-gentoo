# Design: implement-ansible-chroot-preparation

## Handbook Alignment
Follow the Gentoo AMD64 Handbook chroot preparation phase. The Ansible role may translate the commands into idempotent tasks, but it must preserve the intent: prepare pseudo-filesystems, make DNS usable, then allow controlled target-system commands.

## Mounts
Prepare `/dev`, `/dev/pts`, `/proc`, `/sys`, and `/run` as required by the Gentoo Handbook.

The role must:

- refuse a target root of `/`,
- verify `/mnt/gentoo` is already the target root,
- mount or bind only under `/mnt/gentoo`,
- report before/after mount state,
- be idempotent for already-correct mounts.

## DNS
Provide resolver configuration inside the target by a documented method that does not overwrite unexpected files without review.

DNS setup must be validated before package operations. If DNS cannot be prepared, the role must fail before running Portage, kernel, service, user, or bootloader tasks.

## Chroot Execution
Future roles may use explicit chroot command wrappers. This change only prepares the environment and validates readiness.
