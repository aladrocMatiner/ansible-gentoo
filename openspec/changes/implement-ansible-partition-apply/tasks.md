# Tasks: implement-ansible-partition-apply

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [ ] Validate with `openspec validate implement-ansible-partition-apply --strict`.

## Implementation
- [ ] Apply Ansible quality standards: FQCN, named tasks, module-first behavior, guarded command-like tasks, idempotency, check/diff behavior, and secret handling.
- [ ] Run `make ansible-check` and record syntax/lint result.
- [ ] Add `make partition`.
- [ ] Add wrapper script.
- [ ] Add playbook and `common/partitioning` role.
- [ ] Reuse shared destructive safety gates.
- [ ] Print or call destructive preview before accepting confirmation.
- [ ] Apply GPT ESP/root layout only.
- [ ] Record install-state checkpoint and audit evidence.
- [ ] Update docs and skills.
- [ ] Validate inside libvirt VM only.
