# Tasks: implement-shared-destructive-safety-gates

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [ ] Validate with `openspec validate implement-shared-destructive-safety-gates --strict`.

## Implementation
- [ ] Add `common/disk_safety`.
- [ ] Add confirmation script or Makefile guard.
- [ ] Integrate read-only destructive preview before confirmation.
- [ ] Integrate install-state checkpoint comparison for resumed destructive workflows.
- [ ] Consume install configuration schema and config validation output where available.
- [ ] Use shared error taxonomy for safety failures.
- [ ] Add documentation for destructive confirmation.
- [ ] Update safety review agent/skill.
- [ ] Add validation tests using the VM.
