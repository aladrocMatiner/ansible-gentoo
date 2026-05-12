# Design: define-real-hardware-readiness-policy

## Required Preconditions

Before real hardware destructive operations:

- libvirt validation passed for the selected profile/filesystem/stage3 flavor when practical,
- operator has backups,
- UEFI boot confirmed,
- network readiness confirmed,
- power stability considered,
- `INSTALL_DISK` uses a stable path where possible,
- disk model, serial, size, partitions, filesystems, and mountpoints reviewed,
- destructive preview reviewed,
- explicit confirmation entered,
- recovery media available.

## Makefile Integration

Implemented target:

```sh
make real-hardware-check ANSIBLE_LIVE_HOST=<live-iso-ip> INSTALL_DISK=/dev/disk/by-id/<operator-selected-disk>
```

This target is read-only, runs configuration validation with `INSTALL_DISK` required, and writes a local readiness report under `logs/real-hardware-readiness/latest.json`.

It requires non-secret acknowledgements through `REAL_HARDWARE_*` variables for backups, UEFI, network, power, recovery media, destructive preview review, and libvirt validation status. It does not grant permission by itself and does not satisfy destructive or bootloader confirmations.

## Policy

Docs must treat real hardware as higher risk than libvirt. If libvirt validation is unavailable, the operator must explicitly acknowledge that the validation step was skipped and why.
