# Tasks: implement-libvirt-install-test-matrix

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [x] Validate with `openspec validate implement-libvirt-install-test-matrix --strict`.

## Implementation
- [x] Define matrix entries for amd64 OpenRC/systemd, ext4/Btrfs, and supported stage3 flavors.
- [x] Allow an optional manual test image label in planned matrix names.
- [x] Add Makefile target(s) for matrix planning.
- [x] Add safe disposable disk/domain naming.
- [x] Run read-only plan validation for each matrix entry.
- [x] Document later destructive full-install matrix integration after apply roles exist.
- [x] Document later first-boot validation integration after bootloader workflow exists.
- [x] Write per-entry logs and audit bundle references.
- [x] Update VM docs and skills.
