# Tasks: implement-install-audit-bundle

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [x] Validate with `openspec validate implement-install-audit-bundle --strict`.

## Implementation
- [ ] Define audit bundle directory layout.
- [ ] Add Makefile target(s) for bundle generation.
- [ ] Collect non-secret disk, mount, stage3, Portage, kernel, service, bootloader, user, and final-check evidence.
- [ ] Add redaction/rejection rules for secrets.
- [ ] Link audit bundle generation to final checks.
- [ ] Update docs and skills.
- [ ] Validate in libvirt.
