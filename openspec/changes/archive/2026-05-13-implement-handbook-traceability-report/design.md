# Design: implement-handbook-traceability-report

## Trace Model

Each installer phase should identify:

- Handbook section or phase,
- project role/playbook/Makefile target,
- implemented/planned status,
- project-specific deviations,
- safety gates,
- validation evidence.

## Required Project Deviations

The report must explicitly document:

- NetworkManager as the v1 network manager,
- GRUB for UEFI,
- `/boot/efi` target mountpoint,
- `gentoo-kernel-bin` with installkernel/initramfs support,
- ext4 and Btrfs variants,
- no LUKS in current scope,
- libvirt testing before real hardware.

## Makefile Integration

Planned target:

- `make handbook-trace`

The target must not require destructive state and must be read-only.

## Review Use

OpenSpec reviews for installer behavior should check whether a role maps to a Handbook phase or documents a reviewed deviation.
