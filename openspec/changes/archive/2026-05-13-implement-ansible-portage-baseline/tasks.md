# Tasks: implement-ansible-portage-baseline

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [x] Validate with `openspec validate implement-ansible-portage-baseline --strict`.

## Implementation
- [x] Apply Ansible quality standards: FQCN, named tasks, module-first behavior, guarded command-like tasks, idempotency, check/diff behavior, and secret handling.
- [x] Run `make ansible-check` and record syntax/lint result.
- [x] Add shared `common/portage`.
- [x] Add variant profile variables.
- [x] Manage conservative `make.conf`, including `COMMON_FLAGS`, `MAKEOPTS`, `USE`, and license policy.
- [x] Sync official Gentoo repository.
- [x] Follow download cache/mirror policy for mirror and metadata behavior.
- [x] Follow Portage world update policy; do not run broad `@world` update by default.
- [x] Report pending config file updates conservatively.
- [x] Keep GURU disabled in the installed target system unless a later approved change requires it.
- [x] Record Portage/profile evidence for final baseline checks and install report.
- [x] Update docs and skills.
