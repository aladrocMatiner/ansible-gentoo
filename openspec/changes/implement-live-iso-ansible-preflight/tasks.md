# Tasks: implement-live-iso-ansible-preflight

## 1. OpenSpec
- [x] Create `proposal.md`.
- [x] Create `design.md`.
- [x] Create `tasks.md`.
- [x] Create spec delta.
- [x] Validate with `openspec validate implement-live-iso-ansible-preflight --strict`.
- [x] Validate with `openspec validate --all --strict`.

## 2. Makefile
- [x] Add `make ansible-live-ping`.
- [x] Add `make ansible-live-preflight`.
- [x] Document the new targets in `make help`.
- [x] Ensure targets accept `ANSIBLE_LIVE_HOST` for network targets and use VM discovery only for local validation.

## 3. Ansible
- [x] Create `ansible/inventory/live.yml`.
- [x] Create `ansible/playbooks/live-preflight.yml`.
- [x] Create `ansible/roles/common/live_preflight/tasks/main.yml`.
- [x] Keep tasks read-only.
- [x] Report architecture, kernel, Gentoo release, UEFI, network, DNS, routes, and block devices; treat `/dev/vda` as VM-only evidence.
- [x] Fail preflight when UEFI firmware evidence is missing.

## 4. Safety
- [x] Verify no destructive commands are used.
- [x] Verify no install disk is selected or defaulted.
- [x] Verify no secrets are committed.
- [x] Verify no installer playbooks run.

## 5. Documentation
- [x] Create `docs/ansible-live-preflight.md`.
- [x] Update `docs/libvirt-manual-install-test.md`.
- [x] Update `skills/ansible-gentoo-installer.md`.
- [x] Update `skills/makefile-control-plane.md`.
- [x] Document that future Ansible installer roles use the official Gentoo AMD64 Handbook as the baseline procedure.

## 6. Validation
- [x] Run `make ansible-live-ping`.
- [x] Run `make ansible-live-preflight`.
- [x] Run `openspec validate implement-live-iso-ansible-preflight --strict`.
- [x] Run `openspec validate --all --strict`.
