# Tasks: implement-ansible-users-and-access

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [x] Validate with `openspec validate implement-ansible-users-and-access --strict`.

## Implementation
- [x] Apply Ansible quality standards: FQCN, named tasks, module-first behavior, guarded command-like tasks, idempotency, check/diff behavior, and secret handling.
- [x] Run `make ansible-check` and record syntax/lint result.
- [x] Add `common/users`.
- [x] Implement the approved secret input policy for variables, prompts, logs, and docs.
- [x] Configure admin user.
- [x] Configure sudo or doas.
- [x] Add SSH key handling if enabled.
- [x] Enforce installed SSH policy for root login and authorized keys.
- [x] Record non-secret user/access evidence in audit output.
- [x] Update docs and skills.
