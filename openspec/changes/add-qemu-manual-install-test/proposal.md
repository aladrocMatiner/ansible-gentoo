# add-qemu-manual-install-test

## Summary
Add a local QEMU-based test environment for `gentoo-ai-installer` so operators can rehearse the manual Gentoo installation flow in a virtual machine before touching real hardware.

This change was superseded by `migrate-qemu-workflow-to-libvirt-virsh` after the project needed controllable console, SSH, rsync, and Ansible handoff behavior. The active implementation is now libvirt/virsh through `vm-*` targets. The legacy `qemu-*` targets remain only as compatibility aliases to the active libvirt workflow.

The active VM test environment still boots the official Gentoo live ISO from `./gentoo.iso` as either a local ISO file or an ignored artifact directory containing exactly one `.iso` file, and attaches a safe qcow2 virtual disk image under the configured project-local VM artifact directory.

## Motivation
The project currently targets real manual installation workflows from the official Gentoo live ISO. Before applying those workflows to physical disks, operators need a repeatable local VM environment that exercises the same live ISO, UEFI boot assumptions, and disk-install flow while using only virtual disk images.

## Problem Statement
Manual Gentoo installation steps are inherently risky when tested directly on host hardware. A mistaken disk selection, mount operation, or formatting command can destroy host data. The project needs a Makefile-controlled QEMU workflow that provides a safe virtual disk target and never exposes host block devices to the VM disk path.

## Scope
- Define the original local QEMU test workflow for phase 1 manual installation testing, now superseded by the libvirt/virsh workflow.
- Boot the official Gentoo live ISO from `./gentoo.iso` as a file, or from the single `.iso` file inside `./gentoo.iso/`.
- Keep generated VM disk artifacts project-local; the active libvirt workflow uses `./var/libvirt/` by default.
- Preserve compatibility Makefile targets:
  - `make qemu-check`
  - `make qemu-disk`
  - `make qemu-boot`
  - `make qemu-clean`
- Route those compatibility targets to the active libvirt `vm-*` targets instead of direct `qemu-system-x86_64` invocation.
- Keep the workflow local and non-invasive to host disks.

## Non-goals
- Do not automate the Gentoo installation itself.
- Do not build or modify a custom ISO.
- Do not download the ISO automatically in this change.
- Do not attach host block devices to QEMU.
- Do not define or automate installer storage layouts in this virtualization-only change.
- Do not support LUKS, BIOS boot, or advanced storage automation in this change.
- Do not implement the Makefile targets or scripts in this proposal step.
- Do not replace the real hardware manual installation flow.

## Safety Requirements
- VM scripts must only operate on configured project-local VM artifacts.
- VM scripts must never accept host block devices such as `/dev/sda`, `/dev/nvme0n1`, `/dev/vda`, `/dev/xvda`, or similar as VM disks.
- Scripts must fail if `./gentoo.iso` does not exist or cannot be resolved to exactly one ISO file.
- Scripts must fail if required VM host tools such as `virsh`, `qemu-system-x86_64`, or `qemu-img` are missing.
- Scripts must create the configured project-local VM artifact directory only from non-read-only targets.
- Scripts must not run with `sudo` by default.
- VM disk paths must be relative to the project and under the configured VM artifact directory.
- Disk images must be qcow2 by default.
- `make qemu-clean` must ask for confirmation before deleting VM disks.
- No target may use a real host block device.
- Operator-facing QEMU actions must be Makefile targets.

## Acceptance Criteria
- `make qemu-check` is a compatibility alias for `make vm-check`.
- `make qemu-disk` is a compatibility alias for `make vm-disk`.
- `make qemu-boot` is a compatibility alias for `make vm-start`.
- `make qemu-clean` is a compatibility alias for `make vm-clean`.
- The active `vm-*` workflow resolves `./gentoo.iso`, creates a project-local qcow2 disk if missing, boots the official ISO through libvirt, and removes generated artifacts only after explicit confirmation.
- The implementation never touches host block devices.
- All operator-facing QEMU operations are exposed through Makefile targets.
- Per-change strict validation passes with `openspec validate add-qemu-manual-install-test --strict`.
- Full strict validation passes with `openspec validate --all --strict`.

## Affected Files
- `Makefile`
- Active libvirt scripts under `scripts/vm-*.sh`
- `var/libvirt/`
- `docs/`
- `openspec/changes/add-qemu-manual-install-test/proposal.md`
- `openspec/changes/add-qemu-manual-install-test/design.md`
- `openspec/changes/add-qemu-manual-install-test/tasks.md`
- `openspec/changes/add-qemu-manual-install-test/specs/qemu-test/spec.md`
