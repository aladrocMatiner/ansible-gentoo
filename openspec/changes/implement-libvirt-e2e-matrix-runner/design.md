# Design: implement-libvirt-e2e-matrix-runner

## Overview

The matrix runner is an orchestration layer around the already validated single-case workflow. It does not duplicate installer behavior. Each matrix case runs:

```sh
make vm-e2e-install PROFILE=<profile> FILESYSTEM=<filesystem> INSTALL_DISK=/dev/vda ...
```

This keeps the reusable Ansible installer, libvirt VM safety checks, clean shutdown, first-boot validation, and audit generation in one implementation path.

## Supported Matrix

The runner covers exactly these v1 cases:

| Case | PROFILE | FILESYSTEM | Domain |
| --- | --- | --- | --- |
| amd64-openrc-ext4 | openrc | ext4 | gentoo-test-amd64-openrc-ext4 |
| amd64-openrc-btrfs | openrc | btrfs | gentoo-test-amd64-openrc-btrfs |
| amd64-systemd-ext4 | systemd | ext4 | gentoo-test-amd64-systemd-ext4 |
| amd64-systemd-btrfs | systemd | btrfs | gentoo-test-amd64-systemd-btrfs |

`VM_TEST_IMAGE_NAME=<label>` remains supported and is inserted into generated case names by the existing libvirt helper layer.

## Makefile Integration

Add:

```sh
make vm-e2e-matrix
```

Required variables:

- `ADMIN_USER`
- `ADMIN_AUTHORIZED_KEYS_FILE`
- `ENABLE_SSH=yes`
- `VM_E2E_RESET_DISK=yes`
- `I_UNDERSTAND_CLEANUP_DELETE=DELETE`
- `I_UNDERSTAND_THIS_WIPES_DISK=yes`
- `I_UNDERSTAND_BOOTLOADER_CHANGES=yes`

Matrix-specific variables:

- `VM_E2E_MATRIX_LOG_DIR ?= logs/libvirt-e2e-matrix`
- `VM_E2E_MATRIX_PARALLEL ?= 4`

The runner uses existing `VM_TEST_MATRIX_INSTALL_DISK ?= /dev/vda` for the guest install disk and refuses any other value.

## Runner Behavior

The script:

1. Validates required operator inputs and confirmations.
2. Rejects manual `VM_DISK` overrides so each case derives its own qcow2.
3. Creates a timestamped matrix run directory under `VM_E2E_MATRIX_LOG_DIR`.
4. Starts up to `VM_E2E_MATRIX_PARALLEL` child processes.
5. Runs each child through `make --no-print-directory vm-e2e-install`.
6. Writes child stdout/stderr to per-case logs.
7. Reads each case state pointer after completion when available.
8. Reads first-boot evidence when available.
9. Writes `matrix-e2e.json`.
10. Fails if any child command fails or any first-boot evidence is not `PASS`.

## Safety Model

The runner does not perform disk operations directly. All destructive work remains inside the existing single-case workflow, which already enforces:

- project-owned libvirt domains,
- project-local qcow2 disks,
- no host block devices,
- `INSTALL_DISK=/dev/vda` inside the VM,
- destructive install confirmation,
- bootloader confirmation,
- cleanup confirmation for reset,
- clean shutdown before installed-disk first boot.

The matrix runner adds one extra guard: reset is mandatory. This prevents a case from inheriting stale qcow2 contents or a stale `var/state/libvirt/<case-domain>/current-install.json` pointer.

## Logging

Matrix-level logs:

```text
logs/libvirt-e2e-matrix/<timestamp>/
  matrix-e2e.json
  amd64-openrc-ext4/vm-e2e-install.log
  amd64-openrc-btrfs/vm-e2e-install.log
  amd64-systemd-ext4/vm-e2e-install.log
  amd64-systemd-btrfs/vm-e2e-install.log
```

Single-case logs and audit bundles remain under:

```text
logs/libvirt-e2e/<timestamp>-<profile>-<filesystem>/
logs/install-runs/<run-id>/
var/state/libvirt/<case-domain>/current-install.json
```

## Documentation

Update:

- `README.md` with a concise pointer.
- `docs/libvirt-end-to-end-install-validation.md` with the full command and safety requirements.
- `docs/libvirt-install-test-matrix.md` with matrix runner behavior.

## Review Checklist

- The runner invokes `make vm-e2e-install`; it does not duplicate install logic.
- It rejects unsafe matrix input before launching children.
- It does not accept host block devices.
- It refuses manual `VM_DISK` overrides.
- It records per-case results.
- It fails closed on partial failures.
- Documentation includes confirmations, logs, and cleanup behavior.
