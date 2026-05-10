# Tasks: implement-libvirt-install-test-matrix

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [x] Validate with `openspec validate implement-libvirt-install-test-matrix --strict`.

## Implementation
- [ ] Define matrix entries for OpenRC/systemd and ext4/Btrfs.
- [ ] Add Makefile target(s) for matrix planning.
- [ ] Add safe disposable disk/domain naming.
- [ ] Run read-only plan validation for each matrix entry.
- [ ] Later integrate destructive full-install runs after apply roles exist.
- [ ] Later integrate first-boot validation after bootloader workflow exists.
- [ ] Write per-entry logs and audit bundle references.
- [ ] Update VM docs and skills.
