# Tasks: implement-install-audit-bundle

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [x] Validate with `openspec validate implement-install-audit-bundle --strict`.

## Implementation
- [x] Define audit bundle directory layout.
- [x] Add Makefile target(s) for bundle generation.
- [x] Collect non-secret disk, mount, stage3, Portage, kernel, service, bootloader, user, and final-check evidence.
- [x] Add redaction/rejection rules for secrets.
- [x] Link audit bundle generation to final checks.
- [x] Update docs and skills.
- [x] Validate in libvirt.
