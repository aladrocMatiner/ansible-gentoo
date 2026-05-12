# Proposal: implement-libvirt-e2e-matrix-runner

## Summary

Add a Makefile-mediated libvirt end-to-end matrix runner that executes the supported disposable VM install cases:

- amd64 OpenRC/systemd
- ext4/Btrfs
- standard/hardened/musl stage3 flavors

The runner will call the existing single-case `make vm-e2e-install` workflow for each case, preserve per-case logs and state, and write a matrix summary report.

## Motivation

The project now validates individual full installs successfully, but repeating the full matrix manually is error-prone. A formal runner gives operators and contributors one documented target for validating the supported local libvirt matrix before changing installer logic or preparing for real hardware testing.

## Problem Statement

`make vm-test-matrix-plan` enumerates the supported cases, and `make vm-e2e-install` validates one selected case. There is no single operator-facing target that runs all full disposable VM installs with consistent environment, reset behavior, logs, and summary evidence.

## Scope

- Add `make vm-e2e-matrix`.
- Add a script that runs the supported matrix cases through `make vm-e2e-install`.
- Run cases in parallel by default, with bounded configurable parallelism.
- Require the same destructive-in-VM confirmations as single-case E2E installs.
- Require reset/cleanup confirmation so every case starts from a fresh qcow2 and case state pointer.
- Write a matrix summary under `logs/libvirt-e2e-matrix/`.
- Update documentation and OpenSpec task tracking.

## Non-Goals

- Do not change the Ansible installer logic.
- Do not change partition, filesystem, bootloader, user, or first-boot validation behavior.
- Do not touch host block devices.
- Do not support real hardware matrix execution.
- Do not remove single-case `make vm-e2e-install`.

## Safety Considerations

- The runner is destructive only inside project-local disposable qcow2 VM disks.
- `INSTALL_DISK` inside each guest must be `/dev/vda`.
- Host-side VM disk paths must remain derived project-local qcow2 paths.
- Manual `VM_DISK` overrides are rejected for matrix execution.
- `I_UNDERSTAND_THIS_WIPES_DISK=yes`, `I_UNDERSTAND_BOOTLOADER_CHANGES=yes`, and `I_UNDERSTAND_CLEANUP_DELETE=DELETE` are required.
- `VM_E2E_RESET_DISK=yes` is required so stale state cannot contaminate a new matrix run.

## Acceptance Criteria

- `make vm-e2e-matrix` exists and is listed in `make help`.
- The runner executes all supported cases by invoking `make vm-e2e-install` with case-specific `PROFILE`, `FILESYSTEM`, and `STAGE3_FLAVOR`.
- The runner defaults to bounded parallel execution and supports `VM_E2E_MATRIX_PARALLEL`.
- The runner refuses unsupported matrix cases, unsafe log paths, unsafe names, manual `VM_DISK` overrides, and guest disks other than `/dev/vda`.
- The runner writes per-case logs and a JSON summary report.
- The runner exits non-zero if any case fails.
- Documentation describes how to run the matrix, where logs are written, and what confirmations are required.
- `openspec validate implement-libvirt-e2e-matrix-runner --strict` passes.
- `openspec validate --all --strict` passes.

## Affected Files

- `Makefile`
- `scripts/vm-e2e-matrix.py`
- `docs/libvirt-end-to-end-install-validation.md`
- `docs/libvirt-install-test-matrix.md`
- `README.md`
- `openspec/changes/implement-libvirt-e2e-matrix-runner/tasks.md`
- `openspec/changes/implement-libvirt-e2e-matrix-runner/specs/libvirt-e2e-matrix-runner/spec.md`
