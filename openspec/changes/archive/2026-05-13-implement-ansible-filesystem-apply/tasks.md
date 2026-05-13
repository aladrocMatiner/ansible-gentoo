# Tasks: implement-ansible-filesystem-apply

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [x] Validate with `openspec validate implement-ansible-filesystem-apply --strict`.

## Implementation
- [x] Apply Ansible quality standards: FQCN, named tasks, module-first behavior, guarded command-like tasks, idempotency, check/diff behavior, and secret handling.
- [x] Run `make ansible-check` and record syntax/lint result.
- [x] Add `make format`.
- [x] Add wrapper, playbook, and `common/filesystem`.
- [x] Reuse shared safety gates.
- [x] Print or call destructive preview before accepting confirmation.
- [x] Verify required formatting tools before destructive commands.
- [x] Implement ext4 path.
- [x] Implement Btrfs path and subvolumes according to the approved Btrfs policy.
- [x] Record install-state checkpoint and audit evidence.
- [x] Update docs and skills.
- [x] Validate in libvirt VM.
