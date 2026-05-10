# Tasks: implement-ansible-fstab-generation

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [ ] Validate with `openspec validate implement-ansible-fstab-generation --strict`.

## Implementation
- [ ] Apply Ansible quality standards: FQCN, named tasks, module-first behavior, guarded command-like tasks, idempotency, check/diff behavior, and secret handling.
- [ ] Run `make ansible-check` and record syntax/lint result.
- [ ] Add `common/fstab`.
- [ ] Generate ext4 fstab.
- [ ] Generate Btrfs fstab.
- [ ] Generate EFI entry for `/boot/efi`.
- [ ] Ensure Btrfs root entries include `subvol=@`.
- [ ] Ensure Btrfs entries follow the approved subvolume policy.
- [ ] Validate UUIDs.
- [ ] Document that automation may generate fstab once UUIDs exist, while final checks enforce Handbook boot-readiness.
- [ ] Update docs and skills.
