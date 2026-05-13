# Tasks: implement-ansible-mount-plan

## 1. OpenSpec
- [x] Create `proposal.md`.
- [x] Create `design.md`.
- [x] Create `tasks.md`.
- [x] Create spec delta.
- [x] Validate with `openspec validate implement-ansible-mount-plan --strict`.
- [x] Validate with `openspec validate --all --strict`.

## 2. Makefile
- [x] Add `make mount-plan`.
- [x] Document `mount-plan` in `make help`.
- [x] Ensure `INSTALL_DISK` is required.
- [x] Ensure `INSTALL_DISK` has no default.
- [x] Ensure `PROFILE` defaults to `openrc`.
- [x] Ensure `FILESYSTEM` defaults to `ext4`.

## 3. Scripts
- [x] Add `scripts/ansible-mount-plan.sh`.
- [x] Validate `PROFILE=openrc|systemd`.
- [x] Validate `FILESYSTEM=ext4|btrfs`.
- [x] Fail before Ansible if `INSTALL_DISK` is missing.
- [x] Fail clearly if no explicit or VM-discovered live ISO SSH target is available.
- [x] Use explicit `ANSIBLE_LIVE_HOST` when provided and fall back to VM SSH target discovery only for local validation.

## 4. Ansible
- [x] Create `ansible/playbooks/mount-plan.yml`.
- [x] Create `ansible/roles/common/mount_plan/tasks/main.yml`.
- [x] Reuse `common/disk_detection`.
- [x] Reuse `common/install_plan`.
- [x] Reuse `common/partition_plan`.
- [x] Keep tasks read-only.
- [x] Keep OpenRC and systemd mount planning shared.

## 5. Safety
- [x] Verify no destructive commands are used.
- [x] Verify no partition table writes occur.
- [x] Verify no filesystem creation occurs.
- [x] Verify no mount or umount occurs.
- [x] Verify no directory creation occurs.
- [x] Verify selected disk safety checks are reused.
- [x] Verify Btrfs planning includes `subvol=@`.

## 6. Documentation
- [x] Create `docs/ansible-mount-plan.md`.
- [x] Update `docs/ansible-partition-plan.md`.
- [x] Update `skills/ansible-gentoo-installer.md`.
- [x] Update `skills/makefile-control-plane.md`.
- [x] Update `skills/gentoo-disk-planning.md`.
- [x] Update `skills/gentoo-stage3-and-chroot.md`.

## 7. Validation
- [x] Run `make ansible-check`.
- [x] Run `make mount-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda`.
- [x] Run `make mount-plan PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda`.
- [x] Run `make mount-plan PROFILE=systemd FILESYSTEM=btrfs INSTALL_DISK=/dev/vda`.
- [x] Run `openspec validate implement-ansible-mount-plan --strict`.
- [x] Run `openspec validate --all --strict`.
