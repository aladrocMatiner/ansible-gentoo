# Tasks: implement-live-iso-ansible-preflight

## 1. OpenSpec
- [x] Create `proposal.md`.
- [x] Create `design.md`.
- [x] Create `tasks.md`.
- [x] Create spec delta.
- [ ] Validate with `openspec validate implement-live-iso-ansible-preflight --strict`.
- [ ] Validate with `openspec validate --all --strict`.

## 2. Makefile
- [ ] Add `make ansible-live-ping`.
- [ ] Add `make ansible-live-preflight`.
- [ ] Document the new targets in `make help`.
- [ ] Ensure targets discover `VM_IP` through `make vm-ip` or accept explicit `VM_IP`.

## 3. Ansible
- [ ] Create `ansible/inventory/live.yml`.
- [ ] Create `ansible/playbooks/live-preflight.yml`.
- [ ] Create `ansible/roles/common/live_preflight/tasks/main.yml`.
- [ ] Keep tasks read-only.
- [ ] Report architecture, kernel, Gentoo release, UEFI, network, DNS, routes, block devices, and `/dev/vda`.

## 4. Safety
- [ ] Verify no destructive commands are used.
- [ ] Verify no install disk is selected or defaulted.
- [ ] Verify no secrets are committed.
- [ ] Verify no installer playbooks run.

## 5. Documentation
- [ ] Create `docs/ansible-live-preflight.md`.
- [ ] Update `docs/libvirt-manual-install-test.md`.
- [ ] Update `skills/ansible-gentoo-installer.md`.
- [ ] Update `skills/makefile-control-plane.md`.

## 6. Validation
- [ ] Run `make ansible-live-ping`.
- [ ] Run `make ansible-live-preflight`.
- [ ] Run `openspec validate implement-live-iso-ansible-preflight --strict`.
- [ ] Run `openspec validate --all --strict`.
