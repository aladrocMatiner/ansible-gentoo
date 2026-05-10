# Design: define-real-hardware-readiness-policy

## Required Preconditions

Before real hardware destructive operations:

- libvirt validation passed for the selected profile/filesystem when practical,
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

Planned target:

```sh
make real-hardware-check
```

This target must be read-only and must not grant permission by itself. It produces readiness status and required manual confirmations.

## Policy

Docs must treat real hardware as higher risk than libvirt. If libvirt validation is unavailable, the operator must explicitly acknowledge that the validation step was skipped and why.
