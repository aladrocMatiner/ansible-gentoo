# Tasks: implement-basic-console-install-orchestration

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [ ] Validate with `openspec validate implement-basic-console-install-orchestration --strict`.

## Implementation
- [ ] Apply Ansible quality standards: FQCN, named tasks, module-first behavior, guarded command-like tasks, idempotency, check/diff behavior, and secret handling.
- [ ] Run `make ansible-check` and record syntax/lint result.
- [ ] Add shared install playbook.
- [ ] Add thin OpenRC/systemd playbooks.
- [ ] Add Makefile targets.
- [ ] Run config validation before full install execution.
- [ ] Reference target system baseline in orchestration checks.
- [ ] Integrate install-state checkpoints.
- [ ] Integrate audit bundle generation.
- [ ] Check Handbook traceability for the shared role sequence.
- [ ] Update docs and skills.
- [ ] Validate both profiles in VM.
