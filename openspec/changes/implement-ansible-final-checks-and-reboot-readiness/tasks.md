# Tasks: implement-ansible-final-checks-and-reboot-readiness

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [ ] Validate with `openspec validate implement-ansible-final-checks-and-reboot-readiness --strict`.

## Implementation
- [ ] Apply Ansible quality standards: FQCN, named tasks, module-first behavior, guarded command-like tasks, idempotency, check/diff behavior, and secret handling.
- [ ] Run `make ansible-check` and record syntax/lint result.
- [ ] Add `common/final_checks`.
- [ ] Add Makefile target.
- [ ] Validate boot artifacts.
- [ ] Validate services and users.
- [ ] Validate Btrfs `subvol=@` and approved subvolume entries when `FILESYSTEM=btrfs`.
- [ ] Validate target system baseline, including hostname/timezone/locale.
- [ ] Validate time-sync status.
- [ ] Validate installed SSH status when `ENABLE_SSH=yes`.
- [ ] Validate boot kernel command line root UUID and Btrfs root flags.
- [ ] Validate Portage sync/update/config-update status.
- [ ] Generate or reference install audit bundle.
- [ ] Provide inputs for install report summary.
- [ ] Include secret-safety checks.
- [ ] Update docs and skills.
