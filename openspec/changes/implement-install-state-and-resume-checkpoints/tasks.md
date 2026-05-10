# Tasks: implement-install-state-and-resume-checkpoints

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [x] Validate with `openspec validate implement-install-state-and-resume-checkpoints --strict`.

## Implementation
- [ ] Define state schema and run id model.
- [ ] Add project-local state/log paths and gitignore rules if needed.
- [ ] Add Makefile target(s) for state inspection and resume planning.
- [ ] Add shared Ansible/state helper logic for checkpoint writes.
- [ ] Validate resume facts against current disk, UUID, mount, profile, and filesystem state.
- [ ] Ensure destructive confirmations are still required after resume.
- [ ] Redact or reject secrets in state output.
- [ ] Update docs and relevant skills.
- [ ] Validate in libvirt before real hardware use.
