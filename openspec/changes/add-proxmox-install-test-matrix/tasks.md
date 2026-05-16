# Tasks: add-proxmox-install-test-matrix

## OpenSpec
- [x] Create proposal, design, tasks, and spec delta.
- [x] Validate with `openspec validate add-proxmox-install-test-matrix --strict`.
- [x] Validate with `openspec validate --all --strict`.

## Architecture
- [x] Define Proxmox as a remote VM validation harness, not a separate installer path.
- [x] Define the 12-case Proxmox matrix to match libvirt cases.
- [x] Define VM naming and VMID mapping rules.
- [x] Define Proxmox variable model.
- [x] Define ISO, storage, bridge, UEFI, disk, serial console, and SSH expectations.
- [x] Define installed Proxmox test access: explicit `ADMIN_USER`, `ENABLE_SSH=yes`, controller public key in admin `authorized_keys`, and init-specific `sshd` enabled when requested.
- [x] Define optional Proxmox guest-agent integration through `ENABLE_QEMU_GUEST_AGENT=yes`.
- [x] Define Proxmox VM guest-agent channel enablement for project-owned validation VMs.
- [x] Define safety gates for create, install, shutdown, and cleanup.

## Future Implementation
- [x] Add Makefile targets for Proxmox checks, planning/listing, VM lifecycle, SSH bootstrap, Ansible ping, E2E install, matrix execution, shutdown, and cleanup.
- [x] Add a Proxmox installed-disk boot target that removes live ISO kernel arguments and boots project-owned VMs from `scsi0`.
- [x] Ensure the Proxmox installed-disk boot target detaches live ISO media so UEFI cannot fall back into the live environment.
- [x] Ensure the Proxmox live ISO start target restores live ISO media, boot order, and kernel arguments before starting or resetting a VM.
- [x] Use stop/start instead of reset for Proxmox boot-mode switches so media and boot-order changes are applied reliably.
- [x] Generate missing installed SSH host keys when `ENABLE_SSH=yes` so first boot can start `sshd`.
- [x] Require explicit Proxmox E2E installed access with `ADMIN_USER`, support `ENABLE_SSH=yes`, and validate the controller public key when provided.
- [x] Default Proxmox installed-access repair to `ADMIN_USER=aladroc`, installed `sshd`, deterministic IP, and controller public key when values are not overridden.
- [x] Add Proxmox installed-access repair and verification targets for one VM and the full matrix.
- [x] Install and enable `app-emulation/qemu-guest-agent` for Proxmox E2E installs when `ENABLE_QEMU_GUEST_AGENT=yes`.
- [x] Enable the Proxmox guest-agent channel on project-owned VMs during VM creation and preservation.
- [x] Add Proxmox scripts with clear errors and conservative ownership checks.
- [x] Reuse existing Ansible installer wrappers over SSH; do not add Proxmox-specific installer roles.
- [x] Add installed-disk boot support for installed Proxmox VMs.
- [x] Add Proxmox matrix evidence under `logs/proxmox-*`.
- [x] Add validation that Proxmox cleanup cannot affect unrelated VMIDs, templates, or ISOs.

## Documentation
- [x] Update `README.md` with concise Proxmox workflow entry points.
- [x] Document the implemented Proxmox installed-disk boot target, variables, safety behavior, and failure mode.
- [x] Document installed SSH host key generation and the port-22-refused recovery symptom.
- [x] Document Proxmox installed-access repair, verification, defaults, safety notes, and failure modes.
- [x] Document Proxmox QEMU guest agent package/service behavior.
- [x] Document Proxmox VM guest-agent channel enablement.
- [x] Add `docs/proxmox-install-test-matrix.md`.
- [x] Add `docs/proxmox-end-to-end-install-validation.md`.
- [x] Add an indexed Proxmox matrix document covering all 12 cases.
- [x] Update `docs/supported-host-requirements.md` or add Proxmox host requirements documentation.
- [x] Update `AGENTS.md` with Proxmox harness documentation rules.
- [x] Update relevant agent and skill files for Proxmox-specific safety and Makefile behavior.

## Review Checklist
- [x] Confirm all operator-facing Proxmox actions are Makefile targets.
- [x] Confirm no workflow creates a custom ISO.
- [x] Confirm reusable Ansible roles do not depend on Proxmox VMIDs or storage.
- [x] Confirm `INSTALL_DISK` has no default.
- [x] Confirm cleanup requires `I_UNDERSTAND_CLEANUP_DELETE=DELETE`.
- [x] Confirm destructive install requires `I_UNDERSTAND_THIS_WIPES_DISK=yes`.
- [x] Confirm bootloader work requires `I_UNDERSTAND_BOOTLOADER_CHANGES=yes`.
- [x] Confirm VMID ownership markers are required before mutation or cleanup.
- [x] Confirm Proxmox docs identify implemented versus planned behavior.
