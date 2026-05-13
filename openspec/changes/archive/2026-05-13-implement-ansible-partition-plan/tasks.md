# Tasks: implement-ansible-partition-plan

## 1. OpenSpec
- [x] Create `proposal.md`.
- [x] Create `design.md`.
- [x] Create `tasks.md`.
- [x] Create spec delta.
- [x] Validate with `openspec validate implement-ansible-partition-plan --strict`.
- [x] Validate with `openspec validate --all --strict`.

## 2. Makefile
- [x] Add `make partition-plan`.
- [x] Document `partition-plan` in `make help`.
- [x] Ensure `INSTALL_DISK` is required.
- [x] Ensure `INSTALL_DISK` has no default.
- [x] Ensure `PROFILE` defaults to `openrc`.
- [x] Ensure `FILESYSTEM` defaults to `ext4`.

## 3. Scripts
- [x] Add `scripts/ansible-partition-plan.sh`.
- [x] Validate `PROFILE=openrc|systemd`.
- [x] Validate `FILESYSTEM=ext4|btrfs`.
- [x] Fail before Ansible if `INSTALL_DISK` is missing.
- [x] Use explicit `ANSIBLE_LIVE_HOST` when provided and fall back to VM SSH target discovery only for local validation.

## 4. Ansible
- [x] Create `ansible/playbooks/partition-plan.yml`.
- [x] Create `ansible/roles/common/partition_plan/tasks/main.yml`.
- [x] Reuse `common/disk_detection`.
- [x] Reuse `common/install_plan`.
- [x] Keep tasks read-only.
- [x] Keep OpenRC and systemd partition planning shared.

## 5. Safety
- [x] Verify no destructive commands are used.
- [x] Verify no partition table writes occur.
- [x] Verify no filesystem creation occurs.
- [x] Verify no mount or umount occurs.
- [x] Verify selected disk must match exactly one detected disk.
- [x] Verify selected disk must be type `disk`.
- [x] Verify selected disk descendants with mountpoints cause failure.
- [x] Verify Btrfs planning includes `subvol=@`.

## 6. Documentation
- [x] Create `docs/ansible-partition-plan.md`.
- [x] Update `docs/ansible-install-plan.md`.
- [x] Update `skills/ansible-gentoo-installer.md`.
- [x] Update `skills/makefile-control-plane.md`.
- [x] Update `skills/gentoo-disk-planning.md`.
- [x] Update `agents/safety-review-agent.md` if safety review expectations change.

## 7. Validation
- [x] Run `make ansible-check`.
- [x] Run `make partition-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda`.
- [x] Run `make partition-plan PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda`.
- [x] Run `make partition-plan PROFILE=systemd FILESYSTEM=btrfs INSTALL_DISK=/dev/vda`.
- [x] Run `openspec validate implement-ansible-partition-plan --strict`.
- [x] Run `openspec validate --all --strict`.
