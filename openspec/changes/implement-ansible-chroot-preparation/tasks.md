# Tasks: implement-ansible-chroot-preparation

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [ ] Validate with `openspec validate implement-ansible-chroot-preparation --strict`.

## Implementation
- [ ] Apply Ansible quality standards: FQCN, named tasks, module-first behavior, guarded command-like tasks, idempotency, check/diff behavior, and secret handling.
- [ ] Run `make ansible-check` and record syntax/lint result.
- [ ] Add `make prepare-chroot`.
- [ ] Add shared `common/chroot`.
- [ ] Mount or bind required pseudo-filesystems under `/mnt/gentoo`, including `/proc`, `/sys`, `/dev`, and `/run` handling.
- [ ] Prepare and validate DNS readiness.
- [ ] Report before/after mount state.
- [ ] Update docs and skills.
- [ ] Validate idempotency.
