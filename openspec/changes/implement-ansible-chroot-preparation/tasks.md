# Tasks: implement-ansible-chroot-preparation

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [x] Validate with `openspec validate implement-ansible-chroot-preparation --strict`.

## Implementation
- [x] Apply Ansible quality standards: FQCN, named tasks, module-first behavior, guarded command-like tasks, idempotency, check/diff behavior, and secret handling.
- [x] Run `make ansible-check` and record syntax/lint result.
- [x] Add `make prepare-chroot`.
- [x] Add shared `common/chroot`.
- [x] Mount or bind required pseudo-filesystems under `/mnt/gentoo`, including `/proc`, `/sys`, `/dev`, and `/run` handling.
- [x] Prepare and validate DNS readiness.
- [x] Report before/after mount state.
- [x] Update docs and skills.
- [x] Validate idempotency.
