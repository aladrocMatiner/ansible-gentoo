# Change: implement-libvirt-end-to-end-install-validation

## Summary
Add libvirt end-to-end validation for the full installer using the official Gentoo live ISO and a project-local qcow2 disk.

## Motivation
Before real hardware testing, the full installer must be proven in a safe VM that cannot touch host block devices.

## Scope
- Add Makefile validation targets.
- Reset/recreate project-local VM disk with confirmation.
- Run install flow in VM.
- Reboot VM.
- Verify installed system boots and has network access.
- Integrate the libvirt install test matrix for OpenRC/systemd and ext4/Btrfs.
- Integrate first-boot validation and audit bundle output.

## Non-goals
- Do not support host block devices.
- Do not build a custom ISO.
- Do not replace manual review.

## Safety Requirements
- Only operate on qcow2 under `var/libvirt/`.
- Require confirmation before deleting VM disks.
- Never use host `/dev/*` paths as VM disks.

## Acceptance Criteria
- End-to-end OpenRC VM install validates.
- End-to-end systemd VM install validates when systemd support is implemented.
- Matrix entries identify whether planning, destructive install, and first-boot validation are implemented.
- First-boot validation confirms the installed disk can boot without relying on the live ISO.
- Validation logs are stored under `logs/`.
- `openspec validate implement-libvirt-end-to-end-install-validation --strict` passes.

## Affected Files
- `Makefile`
- `scripts/`
- `docs/libvirt-manual-install-test.md`
- `docs/`
