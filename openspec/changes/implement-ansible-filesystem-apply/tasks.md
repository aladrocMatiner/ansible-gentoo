# Tasks: implement-ansible-filesystem-apply

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [ ] Validate with `openspec validate implement-ansible-filesystem-apply --strict`.

## Implementation
- [ ] Apply Ansible quality standards: FQCN, named tasks, module-first behavior, guarded command-like tasks, idempotency, check/diff behavior, and secret handling.
- [ ] Run `make ansible-check` and record syntax/lint result.
- [ ] Add `make format`.
- [ ] Add wrapper, playbook, and `common/filesystem`.
- [ ] Reuse shared safety gates.
- [ ] Print or call destructive preview before accepting confirmation.
- [ ] Verify required formatting tools before destructive commands.
- [ ] Implement ext4 path.
- [ ] Implement Btrfs path and subvolumes according to the approved Btrfs policy.
- [ ] Record install-state checkpoint and audit evidence.
- [ ] Update docs and skills.
- [ ] Validate in libvirt VM.
