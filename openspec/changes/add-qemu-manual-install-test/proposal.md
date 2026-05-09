# add-qemu-manual-install-test

## Summary
Add a local QEMU-based test environment for `gentoo-ai-installer` so operators can rehearse the manual Gentoo installation flow in a virtual machine before touching real hardware.

The test environment will boot the official Gentoo live ISO from `./gentoo.iso` as either a local ISO file or an ignored artifact directory containing exactly one `.iso` file, and attach a safe qcow2 virtual disk image under `./var/qemu/`.

## Motivation
The project currently targets real manual installation workflows from the official Gentoo live ISO. Before applying those workflows to physical disks, operators need a repeatable local VM environment that exercises the same live ISO, UEFI boot assumptions, and disk-install flow while using only virtual disk images.

## Problem Statement
Manual Gentoo installation steps are inherently risky when tested directly on host hardware. A mistaken disk selection, mount operation, or formatting command can destroy host data. The project needs a Makefile-controlled QEMU workflow that provides a safe virtual disk target and never exposes host block devices to the VM disk path.

## Scope
- Define a local QEMU test workflow for phase 1 manual installation testing.
- Boot the official Gentoo live ISO from `./gentoo.iso` as a file, or from the single `.iso` file inside `./gentoo.iso/`.
- Use a qcow2 disk image at `./var/qemu/gentoo-test.qcow2`.
- Add future Makefile targets:
  - `make qemu-check`
  - `make qemu-disk`
  - `make qemu-boot`
  - `make qemu-clean`
- Add future script contract for:
  - `scripts/qemu-boot-gentoo-iso.sh`
  - optional `scripts/qemu-create-disk.sh`
- Keep the workflow local and non-invasive to host disks.

## Non-goals
- Do not automate the Gentoo installation itself.
- Do not build or modify a custom ISO.
- Do not download the ISO automatically in this change.
- Do not attach host block devices to QEMU.
- Do not support LUKS, Btrfs, BIOS boot, or advanced storage layouts in this change.
- Do not implement the Makefile targets or scripts in this proposal step.
- Do not replace the real hardware manual installation flow.

## Safety Requirements
- QEMU scripts must only operate on disk images under `./var/qemu/`.
- QEMU scripts must never accept host block devices such as `/dev/sda`, `/dev/nvme0n1`, `/dev/vda`, `/dev/xvda`, or similar as VM disks.
- Scripts must fail if `./gentoo.iso` does not exist or cannot be resolved to exactly one ISO file.
- Scripts must fail if `qemu-system-x86_64` or `qemu-img` are missing.
- Scripts must create `./var/qemu/` if missing.
- Scripts must not run with `sudo` by default.
- VM disk paths must be relative to the project or under `./var/qemu/`.
- Disk images must be qcow2 by default.
- `make qemu-clean` must ask for confirmation before deleting VM disks.
- No target may use a real host block device.
- Operator-facing QEMU actions must be Makefile targets.

## Acceptance Criteria
- `make qemu-check` verifies required tools and resolves `./gentoo.iso`.
- `make qemu-disk` creates `./var/qemu/gentoo-test.qcow2` if missing.
- `make qemu-boot` boots the resolved official ISO in QEMU with the qcow2 disk attached.
- `make qemu-clean` removes generated QEMU artifacts only after explicit confirmation.
- The implementation never touches host block devices.
- All operator-facing QEMU operations are exposed through Makefile targets.
- Per-change strict validation passes with `openspec validate add-qemu-manual-install-test --strict`.
- Full strict validation passes with `openspec validate --all --strict`.

## Affected Files
- `Makefile`
- `scripts/qemu-boot-gentoo-iso.sh`
- `scripts/qemu-create-disk.sh`
- `var/qemu/`
- `docs/`
- `openspec/changes/add-qemu-manual-install-test/proposal.md`
- `openspec/changes/add-qemu-manual-install-test/design.md`
- `openspec/changes/add-qemu-manual-install-test/tasks.md`
- `openspec/changes/add-qemu-manual-install-test/specs/qemu-test/spec.md`
