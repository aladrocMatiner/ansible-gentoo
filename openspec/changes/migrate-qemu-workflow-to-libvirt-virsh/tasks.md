# Tasks: migrate-qemu-workflow-to-libvirt-virsh

## 1. OpenSpec Artifacts
- [x] Create `proposal.md`.
- [x] Create `design.md`.
- [x] Create `tasks.md`.
- [x] Create `specs/virtualization-test/spec.md`.
- [x] Validate with `openspec validate migrate-qemu-workflow-to-libvirt-virsh --strict`.
- [x] Validate with `openspec validate --all --strict`.

## 2. Existing Workflow Alignment Review
- [x] Review `add-qemu-manual-install-test` proposal, design, tasks, and spec delta.
- [x] Review current `Makefile` QEMU targets.
- [x] Review current QEMU scripts.
- [x] Review current QEMU documentation.
- [x] Identify safety behavior that must be preserved.
- [x] Identify direct-QEMU behavior that must be replaced by libvirt/virsh.

## 3. Makefile Contract
- [x] Add `make vm-check`.
- [x] Add `make vm-disk`.
- [x] Add `make vm-define`.
- [x] Add `make vm-start`.
- [x] Add `make vm-console`.
- [x] Add `make vm-viewer`.
- [x] Add `make vm-ip`.
- [x] Add `make vm-ssh`.
- [x] Add `make vm-rsync`.
- [x] Add `make vm-shutdown`.
- [x] Add `make vm-destroy`.
- [x] Add `make vm-clean`.
- [x] Remove, rename, or convert existing `make qemu-*` targets to documented compatibility aliases.
- [x] Ensure `make help` documents all VM targets and variables.

## 4. Script Contract
- [x] Add reviewed libvirt helper scripts under `scripts/`.
- [x] Ensure scripts are implementation details called through Makefile targets.
- [x] Ensure scripts pass `LIBVIRT_URI` explicitly.
- [x] Ensure scripts do not require or invoke `sudo` by default.
- [x] Ensure scripts print clear failures for missing tools, missing ISO, missing network, missing UEFI support, and unavailable SSH.

## 5. Libvirt Domain Behavior
- [x] Define a deterministic libvirt domain name.
- [x] Generate or maintain reviewed domain XML under the project artifact directory.
- [x] Add a project ownership marker to generated domain XML.
- [x] Attach the official ISO as CD-ROM.
- [x] Attach the project-local qcow2 disk as virtio.
- [x] Configure UEFI-only boot.
- [x] Configure a serial console.
- [x] Configure managed libvirt networking with the default network.
- [x] Keep user-mode networking available only when explicitly configured.
- [x] Ensure domain definition does not reference host block devices.
- [x] Ensure generated XML does not embed secrets.
- [x] Ensure generated domains are not configured for autostart by default.

## 6. Network, Console, and SSH
- [x] Implement `make vm-console` with `virsh console`.
- [x] Implement `make vm-viewer` for graphical access when serial console is not usable.
- [x] Implement `make vm-ip` using `virsh domifaddr` and/or DHCP leases.
- [x] Implement `make vm-bootstrap-ssh` to install an operator public key and start `sshd` through serial console.
- [x] Implement `make vm-ssh` with clear failure when SSH is not enabled in the live ISO.
- [x] Implement `make vm-rsync` for non-secret project files after SSH is available.
- [x] Implement `make vm-ansible-ping` to validate Ansible connectivity without running installer playbooks.
- [x] Document how the operator enables SSH in the official Gentoo live ISO through `make vm-bootstrap-ssh`.
- [x] Do not document SSH as available before the live ISO is configured for it.

## 7. Safety Implementation
- [x] Preserve rejection of `/dev/*` VM disk paths.
- [x] Preserve rejection of parent traversal.
- [x] Preserve rejection of project-root artifact directories such as `.`, `./`, and `./.`.
- [x] Preserve rejection of wildcard paths.
- [x] Preserve rejection of symlinked artifact directories and symlinked path components.
- [x] Preserve rejection of existing non-qcow2 files at the VM disk path.
- [x] Preserve existing qcow2 disks instead of overwriting them.
- [x] Validate `VM_NAME` with a conservative domain-name pattern.
- [x] Validate `VM_NET_MODE`, `VM_NETWORK`, `VM_SSH_HOST`, `VM_SSH_HOST_PORT`, and `VM_SSH_GUEST_PORT`.
- [x] Refuse to replace, destroy, or clean an existing libvirt domain with the same name unless it is project-owned.
- [x] Ensure `vm-clean` deletes only generated artifacts for the configured domain.
- [x] Ensure `vm-clean` requires typing `DELETE`.
- [x] Ensure `vm-clean` does not delete unrelated domains, volumes, pools, networks, ISO files, or secrets.

## 8. Documentation
- [x] Update `README.md` with concise libvirt/virsh target overview.
- [x] Create `docs/libvirt-manual-install-test.md`.
- [x] Update or replace `docs/qemu-manual-install-test.md` so it no longer presents direct QEMU as the active workflow.
- [x] Update `AGENTS.md` to describe the libvirt/virsh VM workflow documentation rule.
- [x] Update `skills/makefile-control-plane.md` with VM targets and variables.
- [x] Update relevant skills with libvirt ISO, qcow2, console, SSH, rsync, cleanup, and guest `/dev/vda` expectations.
- [x] Update relevant agents with libvirt safety and documentation responsibilities.
- [x] Document planned versus implemented behavior clearly.

## 9. Validation and Review
- [x] Verify `make vm-check` is read-only.
- [x] Verify `make vm-disk` creates a qcow2 disk if missing and preserves existing qcow2 disks.
- [x] Verify `make vm-define` defines only the configured domain.
- [x] Verify `make vm-start` starts the VM from the official ISO.
- [x] Verify `make vm-console` can attach or fails with actionable guidance.
- [x] Verify `make vm-viewer` opens graphical access or fails with actionable guidance.
- [x] Verify `make vm-ip` discovers the guest IP or fails clearly.
- [x] Verify `make vm-ssh` uses the discovered SSH endpoint by default and fails clearly until SSH is available.
- [x] Verify `make vm-bootstrap-ssh` starts SSH in the live ISO.
- [x] Verify `make vm-ansible-ping` returns `ping: pong`.
- [x] Verify `make vm-clean` requires confirmation and removes only generated artifacts.
- [x] Run safety review for all libvirt scripts and Makefile targets.
- [x] Run `openspec validate migrate-qemu-workflow-to-libvirt-virsh --strict`.
- [x] Run `openspec validate --all --strict`.

## 10. Completion Criteria
- [x] Direct QEMU is no longer the documented operator-facing VM workflow.
- [x] libvirt/virsh is the documented VM control plane under Makefile targets.
- [x] The VM can be started, inspected, accessed by console, and prepared for SSH/rsync workflows.
- [x] No Gentoo installation automation is introduced by this change.
- [x] All documentation and OpenSpec tasks are synchronized with implementation.
