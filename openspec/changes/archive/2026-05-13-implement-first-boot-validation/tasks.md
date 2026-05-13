# Tasks: implement-first-boot-validation

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [x] Validate with `openspec validate implement-first-boot-validation --strict`.

## Implementation
- [x] Define completed-VM install prerequisites.
- [x] Add Makefile target for first-boot validation.
- [x] Boot installed disk without live ISO as primary boot path.
- [x] Validate network, hostname, root UUID, kernel, NetworkManager, admin user, and optional SSH.
- [x] Validate installed time sync status and boot command line behavior where practical.
- [x] Write first-boot evidence to logs/audit bundle.
- [x] Update libvirt docs and skills.
