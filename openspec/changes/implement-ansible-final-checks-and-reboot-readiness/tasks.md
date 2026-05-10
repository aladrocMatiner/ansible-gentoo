# Tasks: implement-ansible-final-checks-and-reboot-readiness

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [x] Validate with `openspec validate implement-ansible-final-checks-and-reboot-readiness --strict`.

## Implementation
- [x] Apply Ansible quality standards: FQCN, named tasks, module-first behavior, guarded command-like tasks, idempotency, check/diff behavior, and secret handling.
- [x] Run `make ansible-check` and record syntax/lint result.
- [x] Add `common/final_checks`.
- [x] Add Makefile target.
- [x] Validate boot artifacts.
- [x] Validate services and users.
- [x] Validate Btrfs `subvol=@` and approved subvolume entries when `FILESYSTEM=btrfs`.
- [x] Validate target system baseline, including hostname/timezone/locale.
- [x] Validate time-sync status.
- [x] Validate installed SSH status when `ENABLE_SSH=yes`.
- [x] Validate boot kernel command line root UUID and Btrfs root flags.
- [x] Validate Portage sync/update/config-update status.
- [x] Generate or reference install audit bundle.
- [x] Provide inputs for install report summary.
- [x] Include secret-safety checks.
- [x] Update docs and skills.
