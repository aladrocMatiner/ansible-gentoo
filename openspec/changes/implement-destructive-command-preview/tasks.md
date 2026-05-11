# Tasks: implement-destructive-command-preview

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [x] Validate with `openspec validate implement-destructive-command-preview --strict`.

## Implementation
- [x] Define preview output schema.
- [x] Add Makefile target(s) for destructive previews.
- [x] Reuse disk detection, plan roles, and shared safety reporting.
- [x] Integrate preview into destructive partition, format, user, and bootloader apply proposals.
- [x] Ensure preview does not set confirmation variables.
- [x] Update docs and safety skills.
- [x] Validate preview in libvirt without mutating the VM disk.
