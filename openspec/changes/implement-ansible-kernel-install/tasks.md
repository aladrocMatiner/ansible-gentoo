# Tasks: implement-ansible-kernel-install

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [ ] Validate with `openspec validate implement-ansible-kernel-install --strict`.

## Implementation
- [ ] Apply Ansible quality standards: FQCN, named tasks, module-first behavior, guarded command-like tasks, idempotency, check/diff behavior, and secret handling.
- [ ] Run `make ansible-check` and record syntax/lint result.
- [ ] Add `common/kernel`.
- [ ] Install `gentoo-kernel-bin`.
- [ ] Configure required installkernel/initramfs support for the GRUB boot flow.
- [ ] Record kernel/initramfs evidence needed by boot command line validation.
- [ ] Validate `/boot` artifacts.
- [ ] Update docs and skills.
