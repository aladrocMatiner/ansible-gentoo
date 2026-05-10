# Tasks: implement-ansible-portage-baseline

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [ ] Validate with `openspec validate implement-ansible-portage-baseline --strict`.

## Implementation
- [ ] Apply Ansible quality standards: FQCN, named tasks, module-first behavior, guarded command-like tasks, idempotency, check/diff behavior, and secret handling.
- [ ] Run `make ansible-check` and record syntax/lint result.
- [ ] Add shared `common/portage`.
- [ ] Add variant profile variables.
- [ ] Manage conservative `make.conf`, including `COMMON_FLAGS`, `MAKEOPTS`, `USE`, and license policy.
- [ ] Sync official Gentoo repository.
- [ ] Follow download cache/mirror policy for mirror and metadata behavior.
- [ ] Follow Portage world update policy; do not run broad `@world` update by default.
- [ ] Report pending config file updates conservatively.
- [ ] Keep GURU disabled in the installed target system unless a later approved change requires it.
- [ ] Record Portage/profile evidence for final baseline checks and install report.
- [ ] Update docs and skills.
