# Tasks: implement-ansible-fstab-generation

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [x] Validate with `openspec validate implement-ansible-fstab-generation --strict`.

## Implementation
- [x] Apply Ansible quality standards: FQCN, named tasks, module-first behavior, guarded command-like tasks, idempotency, check/diff behavior, and secret handling.
- [x] Run `make ansible-check` and record syntax/lint result.
- [x] Add `common/fstab`.
- [x] Generate ext4 fstab.
- [x] Generate Btrfs fstab.
- [x] Generate EFI entry for `/boot/efi`.
- [x] Ensure Btrfs root entries include `subvol=@`.
- [x] Ensure Btrfs entries follow the approved subvolume policy.
- [x] Validate UUIDs.
- [x] Document that automation may generate fstab once UUIDs exist, while final checks enforce Handbook boot-readiness.
- [x] Update docs and skills.
