# Tasks: implement-ansible-disk-detection-and-install-plan

## 1. OpenSpec
- [x] Create `proposal.md`.
- [x] Create `design.md`.
- [x] Create `tasks.md`.
- [x] Create spec delta.
- [x] Validate with `openspec validate implement-ansible-disk-detection-and-install-plan --strict`.
- [x] Validate with `openspec validate --all --strict`.

## 2. Makefile
- [x] Add `make ansible-check`.
- [x] Add `make detect-disks`.
- [x] Add `make install-plan`.
- [x] Document the new targets in `make help`.
- [x] Ensure `PROFILE` defaults to `openrc`.
- [x] Ensure `INSTALL_DISK` has no default.

## 3. Scripts
- [x] Add wrapper script for `make ansible-check`.
- [x] Add wrapper script for `make detect-disks`.
- [x] Add wrapper script for `make install-plan`.
- [x] Reuse existing VM SSH target discovery.

## 4. Ansible
- [x] Create `ansible/playbooks/detect-disks.yml`.
- [x] Create `ansible/playbooks/install-plan.yml`.
- [x] Create `ansible/roles/common/disk_detection/tasks/main.yml`.
- [x] Create `ansible/roles/common/install_plan/tasks/main.yml`.
- [x] Keep tasks read-only.
- [x] Keep OpenRC and systemd plan logic shared.

## 5. Safety
- [x] Verify no destructive commands are used.
- [x] Verify no install disk is selected or defaulted.
- [x] Verify provided `INSTALL_DISK` is used only for read-only matching.
- [x] Verify no confirmation variable is required or consumed.
- [x] Verify no installer playbooks run.

## 6. Documentation
- [x] Create `docs/ansible-install-plan.md`.
- [x] Update `docs/ansible-live-preflight.md`.
- [x] Update `skills/ansible-gentoo-installer.md`.
- [x] Update `skills/makefile-control-plane.md`.
- [x] Update `skills/gentoo-disk-planning.md`.

## 7. Validation
- [x] Run `make ansible-check`.
- [x] Run `make detect-disks`.
- [x] Run `make install-plan PROFILE=openrc`.
- [x] Run `make install-plan PROFILE=systemd`.
- [x] Run `make install-plan PROFILE=openrc INSTALL_DISK=/dev/vda`.
- [x] Run `openspec validate implement-ansible-disk-detection-and-install-plan --strict`.
- [x] Run `openspec validate --all --strict`.
