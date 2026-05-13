# Tasks: implement-ansible-system-packages-and-services

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [x] Validate with `openspec validate implement-ansible-system-packages-and-services --strict`.

## Implementation
- [x] Apply Ansible quality standards: FQCN, named tasks, module-first behavior, guarded command-like tasks, idempotency, check/diff behavior, and secret handling.
- [x] Run `make ansible-check` and record syntax/lint result.
- [x] Add package variables.
- [x] Add shared package install role.
- [x] Add init-specific service enablement.
- [x] Install and enable NetworkManager.
- [x] Install or verify `sys-fs/dosfstools` for the FAT32/vfat EFI system partition.
- [x] Install `sys-fs/btrfs-progs` when `FILESYSTEM=btrfs`.
- [x] Verify ext4 tooling such as `sys-fs/e2fsprogs` is available for ext4 workflows.
- [x] Document NetworkManager as the project v1 policy instead of the Handbook's basic `dhcpcd` example.
- [x] Add time-sync package/service variables according to installed time-sync policy.
- [x] Add SSH package/service behavior according to installed SSH policy when `ENABLE_SSH=yes`.
- [x] Record package/service evidence for final baseline checks and install report.
- [x] Update docs and skills.
