# Tasks: implement-ansible-partition-plan

## 1. OpenSpec
- [x] Create `proposal.md`.
- [x] Create `design.md`.
- [x] Create `tasks.md`.
- [x] Create spec delta.
- [ ] Validate with `openspec validate implement-ansible-partition-plan --strict`.
- [ ] Validate with `openspec validate --all --strict`.

## 2. Makefile
- [ ] Add `make partition-plan`.
- [ ] Document `partition-plan` in `make help`.
- [ ] Ensure `INSTALL_DISK` is required.
- [ ] Ensure `INSTALL_DISK` has no default.
- [ ] Ensure `PROFILE` defaults to `openrc`.
- [ ] Ensure `FILESYSTEM` defaults to `ext4`.

## 3. Scripts
- [ ] Add `scripts/ansible-partition-plan.sh`.
- [ ] Validate `PROFILE=openrc|systemd`.
- [ ] Validate `FILESYSTEM=ext4|btrfs`.
- [ ] Fail before Ansible if `INSTALL_DISK` is missing.
- [ ] Reuse existing VM SSH target discovery.

## 4. Ansible
- [ ] Create `ansible/playbooks/partition-plan.yml`.
- [ ] Create `ansible/roles/common/partition_plan/tasks/main.yml`.
- [ ] Reuse `common/disk_detection`.
- [ ] Reuse `common/install_plan`.
- [ ] Keep tasks read-only.
- [ ] Keep OpenRC and systemd partition planning shared.

## 5. Safety
- [ ] Verify no destructive commands are used.
- [ ] Verify no partition table writes occur.
- [ ] Verify no filesystem creation occurs.
- [ ] Verify no mount or umount occurs.
- [ ] Verify selected disk must match exactly one detected disk.
- [ ] Verify selected disk must be type `disk`.
- [ ] Verify selected disk children with mountpoints cause failure.
- [ ] Verify Btrfs planning includes `subvol=@`.

## 6. Documentation
- [ ] Create `docs/ansible-partition-plan.md`.
- [ ] Update `docs/ansible-install-plan.md`.
- [ ] Update `skills/ansible-gentoo-installer.md`.
- [ ] Update `skills/makefile-control-plane.md`.
- [ ] Update `skills/gentoo-disk-planning.md`.
- [ ] Update `agents/safety-review-agent.md` if safety review expectations change.

## 7. Validation
- [ ] Run `make ansible-check`.
- [ ] Run `make partition-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda`.
- [ ] Run `make partition-plan PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda`.
- [ ] Run `make partition-plan PROFILE=systemd FILESYSTEM=btrfs INSTALL_DISK=/dev/vda`.
- [ ] Run `openspec validate implement-ansible-partition-plan --strict`.
- [ ] Run `openspec validate --all --strict`.
