# Tasks: implement-ansible-system-packages-and-services

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [ ] Validate with `openspec validate implement-ansible-system-packages-and-services --strict`.

## Implementation
- [ ] Apply Ansible quality standards: FQCN, named tasks, module-first behavior, guarded command-like tasks, idempotency, check/diff behavior, and secret handling.
- [ ] Run `make ansible-check` and record syntax/lint result.
- [ ] Add package variables.
- [ ] Add shared package install role.
- [ ] Add init-specific service enablement.
- [ ] Install and enable NetworkManager.
- [ ] Install or verify `sys-fs/dosfstools` for the FAT32/vfat EFI system partition.
- [ ] Install `sys-fs/btrfs-progs` when `FILESYSTEM=btrfs`.
- [ ] Verify ext4 tooling such as `sys-fs/e2fsprogs` is available for ext4 workflows.
- [ ] Document NetworkManager as the project v1 policy instead of the Handbook's basic `dhcpcd` example.
- [ ] Add time-sync package/service variables according to installed time-sync policy.
- [ ] Add SSH package/service behavior according to installed SSH policy when `ENABLE_SSH=yes`.
- [ ] Record package/service evidence for final baseline checks and install report.
- [ ] Update docs and skills.
