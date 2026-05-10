# migrate-qemu-workflow-to-libvirt-virsh

## Summary
Replace the direct `qemu-system-x86_64` manual test workflow with a libvirt/virsh-managed VM workflow.

The new workflow must still boot the official Gentoo live ISO from `./gentoo.iso`, attach a safe qcow2 disk under the project artifact directory, and keep every operator-facing action behind Makefile targets. The reason for the migration is to make the VM controllable after boot: discover its network address, open a console, connect by SSH, copy files, and later run Ansible workflows in a repeatable way.

## Motivation
The current QEMU-direct workflow proves that the official ISO can boot with a safe qcow2 disk, but it is not a good control surface for the next phase. It opens an interactive graphical VM and does not provide a reliable project-level way to:

- discover the guest IP address,
- open a managed console,
- connect over SSH,
- copy the repository or generated artifacts into the guest,
- start, stop, destroy, and inspect the VM consistently,
- integrate future Ansible test runs.

libvirt/virsh provides a stable local VM lifecycle and network inspection layer while still using QEMU/KVM underneath.

## Problem Statement
The project needs to continue from manual VM boot testing into controlled installation rehearsal and future Ansible execution. Direct QEMU invocation makes that difficult because VM lifecycle, network state, guest identity, and SSH access are not represented as managed resources.

The new workflow must not weaken the safety model created for the QEMU workflow. It must preserve the same guarantees around official ISO input, qcow2 disk images, no host block devices, no custom ISO in v1, UEFI-only boot, and explicit cleanup confirmation.

## Scope
- Replace direct QEMU operator workflows with libvirt/virsh-controlled workflows.
- Use `qemu:///system` by default because the tested host provides a managed `default` network with DHCP lease discovery and reliable SSH access.
- Keep the official Gentoo ISO input at `./gentoo.iso` as either a file or a directory containing exactly one `.iso`.
- Keep generated VM disk images under a project-local artifact directory.
- Define Makefile targets for VM lifecycle, console/viewer access, network inspection, SSH bootstrap, SSH, rsync, Ansible connectivity validation, cleanup, and validation.
- Generate libvirt domain XML or use a reviewed helper script to define the domain.
- Use UEFI only in v1.
- Provide a path for SSH-based interaction with the live ISO by installing an operator public key through the serial console and starting `sshd`.
- Align documentation, agents, skills, and OpenSpec tasks with the new libvirt/virsh workflow.

## Non-goals
- Do not automate the Gentoo installation itself in this change.
- Do not implement Ansible installer roles or playbooks in this change.
- Do not build or modify a custom ISO.
- Do not download the ISO automatically.
- Do not use host block devices as VM disks.
- Do not require raw `sudo` commands in operator documentation; system libvirt permissions must be provided by host configuration.
- Do not support BIOS boot in v1.
- Do not add LUKS, Btrfs, graphical desktop, or advanced storage layouts.
- Do not keep direct QEMU and virsh as equal operator-facing workflows; direct QEMU should become an implementation detail or be removed.

## Safety Requirements
- All operator-facing VM actions must be Makefile targets.
- The default libvirt connection must be `qemu:///system`.
- VM disk images must be qcow2 files under the configured project artifact directory.
- No script or target may accept `/dev/*` or any host block device as the VM disk.
- Existing path checks from the QEMU workflow must be preserved or strengthened: reject absolute disk paths, parent traversal, dot-equivalent project-root artifact directories, wildcard paths, symlinked artifact directories, symlinked path components, QEMU/libvirt option injection, and non-qcow2 disk files.
- Cleanup must delete only known generated libvirt artifacts after explicit confirmation.
- Cleanup must require the operator to type `DELETE`.
- Domain removal must not delete unrelated libvirt domains, volumes, networks, or pools.
- UEFI firmware and per-VM NVRAM handling must use generated project-local artifacts or a libvirt-managed path that cannot overwrite host firmware templates.
- The workflow must fail closed when domain name, disk path, ISO path, network name, or libvirt connection is ambiguous.
- Managed-network mode must discover the guest IP through libvirt DHCP leases. Session user-mode networking may exist only as a non-default experimental path.
- The VM must expose a usable serial console by booting the official kernel and initrd extracted from the ISO with serial console kernel arguments.
- The SSH bootstrap may write an operator public key into the temporary live ISO only; it must not write private keys, passwords, or tokens.
- Ansible validation is limited to connectivity checks and must not run installer playbooks in this change.
- Secrets, SSH keys, passwords, and tokens must not be committed.

## Acceptance Criteria
- A new OpenSpec change defines the libvirt/virsh migration and validates with `openspec validate migrate-qemu-workflow-to-libvirt-virsh --strict`.
- Full validation passes with `openspec validate --all --strict`.
- The proposal defines how existing direct-QEMU targets and documentation will be replaced or deprecated.
- The design defines Makefile targets for checking tools, creating disks, defining the VM, starting it, opening console/viewer access, inspecting network access, SSH, rsync, stopping/destroying, and cleanup.
- The design preserves the official ISO, UEFI-only, qcow2, no-host-block-device, and no-custom-ISO rules.
- The design defines how libvirt domain names, disk paths, NVRAM paths, and network names are validated.
- The design explains how SSH access is obtained through serial-console bootstrap and managed-network discovery without pretending that the live ISO is already configured for SSH.
- The tasks include documentation updates for `README.md`, `AGENTS.md`, `docs/`, `skills/`, and relevant agents.
- The tasks include review and validation steps for safety-sensitive libvirt behavior.

## Affected Files
- `Makefile`
- `scripts/`
- `docs/qemu-manual-install-test.md`
- `docs/libvirt-manual-install-test.md`
- `README.md`
- `AGENTS.md`
- `agents/`
- `skills/`
- `.gitignore`
- `openspec/changes/migrate-qemu-workflow-to-libvirt-virsh/`
- Existing OpenSpec QEMU change artifacts, if they remain active during migration

## Existing Workflow Alignment Review
The current `add-qemu-manual-install-test` workflow is mostly aligned on safety and inputs, but not aligned on controllability:

- Aligned: official ISO at `./gentoo.iso`.
- Aligned: qcow2 disk under project artifacts.
- Aligned: UEFI-only boot.
- Aligned: no host block devices.
- Aligned: Makefile as the operator control plane.
- Aligned: cleanup requires explicit confirmation.
- Not aligned: direct `qemu-system-x86_64` is the operator-facing VM runtime.
- Not aligned: no managed domain lifecycle.
- Not aligned: no reliable `virsh console`.
- Not aligned: no reliable SSH access path through libvirt port forwarding or managed-network discovery.
- Not aligned: no Makefile-mediated SSH or rsync workflow.
- Not aligned: docs still describe QEMU-direct as the active test workflow.

This change should replace those non-aligned pieces while carrying forward the aligned safety rules.
