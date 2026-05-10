# Tasks: implement-ansible-bootloader-grub

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [ ] Validate with `openspec validate implement-ansible-bootloader-grub --strict`.

## Implementation
- [ ] Apply Ansible quality standards: FQCN, named tasks, module-first behavior, guarded command-like tasks, idempotency, check/diff behavior, and secret handling.
- [ ] Run `make ansible-check` and record syntax/lint result.
- [ ] Add `common/bootloader`.
- [ ] Verify UEFI and EFI mount.
- [ ] Verify the live ISO path `/mnt/gentoo/boot/efi` maps to `/boot/efi` inside the target.
- [ ] Install GRUB package.
- [ ] Print or call bootloader preview before confirmation.
- [ ] Run guarded GRUB install.
- [ ] Generate config.
- [ ] Validate generated GRUB config against boot kernel command line policy.
- [ ] Record bootloader evidence in logs/audit output.
- [ ] Update docs and skills.
