# Tasks: implement-install-state-and-resume-checkpoints

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [x] Validate with `openspec validate implement-install-state-and-resume-checkpoints --strict`.

## Implementation
- [x] Define state schema and run id model.
- [x] Add project-local state/log paths and gitignore rules if needed.
- [x] Add Makefile target(s) for state inspection and resume planning.
- [x] Add shared Ansible/state helper logic for checkpoint writes.
- [x] Validate resume facts against current disk, UUID, mount, profile, and filesystem state.
- [x] Ensure destructive confirmations are still required after resume.
- [x] Redact or reject secrets in state output.
- [x] Update docs and relevant skills.
- [x] Validate in libvirt before real hardware use.
