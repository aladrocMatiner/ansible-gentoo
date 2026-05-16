## Summary

Add a Proxmox VE validation plan for the same Gentoo installer cases currently tested through the local libvirt harness.

The Proxmox workflow will create disposable VMs from the official Gentoo live ISO, attach Proxmox-managed virtual disks, bootstrap temporary SSH into the live ISO, and run the existing reusable Ansible installer over SSH. It will not create a second installer path.

## Motivation

The current VM validation harness proves the installer locally with libvirt. That is useful for development, but the project goal is a reusable SSH-driven Ansible installer that can run against network-reachable Gentoo live ISO targets. Proxmox is a common network virtualization platform and is closer to the remote-controller model than local libvirt.

Adding Proxmox examples gives the project:

- a second validation environment for the same Ansible roles,
- a way to test remote SSH behavior without physical hardware,
- explicit VMIDs, storage, bridge, and ISO handling,
- clearer separation between reusable installer logic and local libvirt-only helpers,
- a path to reproduce the current 12-case matrix on a Proxmox host.

## Problem Statement

The repository currently documents and automates the matrix through local libvirt only:

- `amd64/openrc/ext4/standard`
- `amd64/openrc/btrfs/standard`
- `amd64/systemd/ext4/standard`
- `amd64/systemd/btrfs/standard`
- the same four cases for `hardened`
- the same four cases for `musl`

Those cases should also be expressible as Proxmox VMs, but Proxmox has different operational concerns:

- VM identity is VMID-based as well as name-based.
- ISO paths are Proxmox storage volume IDs, not project-local file paths.
- virtual disks live in Proxmox storage, not `var/libvirt/`.
- networking uses a Proxmox bridge such as `vmbr0`.
- VM creation/deletion may affect shared Proxmox infrastructure if poorly scoped.
- cleanup must not destroy unrelated VMIDs, volumes, ISOs, templates, or storage.

## Scope

This change defines the Proxmox validation architecture and required project updates.

In scope:

- Define Proxmox equivalents for the current 12-case install matrix.
- Define Makefile-mediated Proxmox targets.
- Define required Proxmox variables and validation rules.
- Define VMID allocation rules.
- Define storage, bridge, ISO, UEFI, serial console, and SSH expectations.
- Define the installed Proxmox test access policy: explicit `ADMIN_USER`, installed `sshd` enabled when `ENABLE_SSH=yes`, and controller public SSH key installed into the admin account's `authorized_keys` for passwordless SSH.
- Define Proxmox guest integration policy: enable the Proxmox guest-agent channel on project-owned VMs and install/enable `qemu-guest-agent` in disposable Proxmox E2E installs when `ENABLE_QEMU_GUEST_AGENT=yes`.
- Define safety gates for creating, resetting, stopping, and deleting Proxmox test VMs.
- Define documentation updates and quickstart expectations.
- Keep Ansible execution over SSH through existing shared installer wrappers.

## Non-Goals

- Do not replace libvirt validation.
- Do not create a custom Gentoo ISO.
- Do not automate installation through Proxmox guest-agent-only mechanisms.
- Do not use Proxmox cloud-init as the Gentoo installer path.
- Do not introduce Terraform, Packer, or a Proxmox API client in this change.
- Do not implement Ansible roles or playbooks unrelated to Proxmox test setup.
- Do not touch physical host disks.
- Do not delete or mutate unrelated Proxmox VMs, templates, volumes, pools, or ISOs.

## Safety Considerations

Proxmox validation is more sensitive than project-local libvirt because it can operate against a shared virtualization host.

The workflow must:

- require a Proxmox host/operator context explicitly,
- use Makefile targets only for operator-facing actions,
- require explicit `PROXMOX_NODE`, `PROXMOX_STORAGE`, `PROXMOX_BRIDGE`, `PROXMOX_ISO`, and VMID configuration,
- never infer VMIDs by scanning all Proxmox VMs,
- require a project ownership marker in VM descriptions or tags before shutdown, reset, cleanup, or deletion,
- refuse to operate on VMs that do not match the expected `gentoo-test` naming pattern and ownership marker,
- keep UEFI as the default boot mode,
- attach only Proxmox virtual disks created for the selected test VM,
- treat guest `/dev/vda` or `/dev/sda` as valid only inside the disposable VM when explicitly passed as `INSTALL_DISK`,
- require destructive-in-VM confirmations before running the installer,
- require explicit cleanup confirmation before destroying Proxmox VMs or removing their disks,
- never run `qm destroy`, `qm stop`, or `qm set` against arbitrary VMIDs.

## Acceptance Criteria

- A Proxmox OpenSpec capability defines the validation contract.
- The Proxmox matrix includes the same 12 amd64 cases as the libvirt matrix.
- The design defines VM naming, VMID mapping, storage, ISO, bridge, UEFI, serial console, SSH, and disk expectations.
- The design requires explicit `ADMIN_USER`, supports `ENABLE_SSH=yes`, and defines a controller public key source for installed-system passwordless SSH.
- The design enables QEMU guest agent integration for Proxmox validation without making it mandatory for physical installs.
- The design defines Makefile targets for read-only checks, planning, VM creation, start, SSH bootstrap, Ansible ping, single-case E2E install, matrix E2E install, shutdown, and cleanup.
- The design requires all operator-facing Proxmox actions to go through Makefile targets.
- The design states that Proxmox uses the same SSH-driven Ansible installer, not a separate installer path.
- The design does not require a custom ISO.
- The design does not rely on libvirt-only discovery.
- Cleanup requirements protect unrelated Proxmox VMs, templates, volumes, and ISOs.
- Documentation tasks cover README, Proxmox docs, indexed case usage, AGENTS.md, and relevant skills.
- `openspec validate add-proxmox-install-test-matrix --strict` passes.
- `openspec validate --all --strict` passes.

## Affected Files

Expected implementation files in a later change:

- `Makefile`
- `scripts/proxmox-*.sh` or `scripts/proxmox-*.py`
- `docs/proxmox-install-test-matrix.md`
- `docs/proxmox-end-to-end-install-validation.md`
- `docs/proxmox-install-test-matrix.md`
- `docs/proxmox-end-to-end-install-validation.md`
- `README.md`
- `AGENTS.md`
- `skills/makefile-control-plane.md`
- `skills/ansible-gentoo-installer.md`
- `agents/ansible-installer-agent.md`
- `agents/safety-review-agent.md`
- `openspec/specs/proxmox-test/spec.md`
