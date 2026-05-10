# Tasks: implement-ansible-bootloader-grub

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [x] Validate with `openspec validate implement-ansible-bootloader-grub --strict`.

## Implementation
- [x] Apply Ansible quality standards: FQCN, named tasks, module-first behavior, guarded command-like tasks, idempotency, check/diff behavior, and secret handling.
- [x] Run `make ansible-check` and record syntax/lint result.
- [x] Add `common/bootloader`.
- [x] Verify UEFI and EFI mount.
- [x] Verify the live ISO path `/mnt/gentoo/boot/efi` maps to `/boot/efi` inside the target.
- [x] Install GRUB package.
- [x] Print or call bootloader preview before confirmation.
- [x] Run guarded GRUB install.
- [x] Generate config.
- [x] Validate generated GRUB config against boot kernel command line policy.
- [x] Record bootloader evidence in logs/audit output.
- [x] Update docs and skills.
