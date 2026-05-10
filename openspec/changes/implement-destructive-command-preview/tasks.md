# Tasks: implement-destructive-command-preview

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [x] Validate with `openspec validate implement-destructive-command-preview --strict`.

## Implementation
- [ ] Define preview output schema.
- [ ] Add Makefile target(s) for destructive previews.
- [ ] Reuse disk detection, plan roles, and shared safety reporting.
- [ ] Integrate preview into destructive partition, format, user, and bootloader apply proposals.
- [ ] Ensure preview does not set confirmation variables.
- [ ] Update docs and safety skills.
- [ ] Validate preview in libvirt without mutating the VM disk.
