# Tasks: implement-ansible-partition-apply

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [x] Validate with `openspec validate implement-ansible-partition-apply --strict`.

## Implementation
- [x] Apply Ansible quality standards: FQCN, named tasks, module-first behavior, guarded command-like tasks, idempotency, check/diff behavior, and secret handling.
- [x] Run `make ansible-check` and record syntax/lint result.
- [x] Add `make partition`.
- [x] Add wrapper script.
- [x] Add playbook and `common/partitioning` role.
- [x] Reuse shared destructive safety gates.
- [x] Print or call destructive preview before accepting confirmation.
- [x] Apply GPT ESP/root layout only.
- [x] Record install-state checkpoint and audit evidence.
- [x] Update docs and skills.
- [x] Validate inside libvirt VM only.
