# Tasks: implement-shared-destructive-safety-gates

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [x] Validate with `openspec validate implement-shared-destructive-safety-gates --strict`.

## Implementation
- [x] Add `common/disk_safety`.
- [x] Add confirmation script or Makefile guard.
- [x] Integrate read-only destructive preview before confirmation.
- [ ] Integrate install-state checkpoint comparison for resumed destructive workflows.
- [x] Consume install configuration schema and config validation output where available.
- [x] Use shared error taxonomy for safety failures.
- [x] Add documentation for destructive confirmation.
- [x] Update safety review agent/skill.
- [x] Add validation tests using the VM.
