# Tasks: implement-ansible-users-and-access

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [ ] Validate with `openspec validate implement-ansible-users-and-access --strict`.

## Implementation
- [ ] Apply Ansible quality standards: FQCN, named tasks, module-first behavior, guarded command-like tasks, idempotency, check/diff behavior, and secret handling.
- [ ] Run `make ansible-check` and record syntax/lint result.
- [ ] Add `common/users`.
- [ ] Implement the approved secret input policy for variables, prompts, logs, and docs.
- [ ] Configure admin user.
- [ ] Configure sudo or doas.
- [ ] Add SSH key handling if enabled.
- [ ] Enforce installed SSH policy for root login and authorized keys.
- [ ] Record non-secret user/access evidence in audit output.
- [ ] Update docs and skills.
