# Tasks: implement-ansible-kernel-install

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [x] Validate with `openspec validate implement-ansible-kernel-install --strict`.

## Implementation
- [x] Apply Ansible quality standards: FQCN, named tasks, module-first behavior, guarded command-like tasks, idempotency, check/diff behavior, and secret handling.
- [x] Run `make ansible-check` and record syntax/lint result.
- [x] Add `common/kernel`.
- [x] Install `gentoo-kernel-bin`.
- [x] Configure required installkernel/initramfs support for the GRUB boot flow.
- [x] Record kernel/initramfs evidence needed by boot command line validation.
- [x] Validate `/boot` artifacts.
- [x] Update docs and skills.
