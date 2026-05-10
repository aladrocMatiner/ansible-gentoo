# Tasks: implement-first-boot-validation

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [x] Validate with `openspec validate implement-first-boot-validation --strict`.

## Implementation
- [ ] Define completed-VM install prerequisites.
- [ ] Add Makefile target for first-boot validation.
- [ ] Boot installed disk without live ISO as primary boot path.
- [ ] Validate network, hostname, root UUID, kernel, NetworkManager, admin user, and optional SSH.
- [ ] Validate installed time sync status and boot command line behavior where practical.
- [ ] Write first-boot evidence to logs/audit bundle.
- [ ] Update libvirt docs and skills.
