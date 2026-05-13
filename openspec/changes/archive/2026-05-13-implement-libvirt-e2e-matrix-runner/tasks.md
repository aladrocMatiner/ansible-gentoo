# Tasks: implement-libvirt-e2e-matrix-runner

## 1. OpenSpec

- [x] 1.1 Create proposal, design, tasks, and spec delta.
- [x] 1.2 Validate with `openspec validate implement-libvirt-e2e-matrix-runner --strict`.
- [x] 1.3 Validate full project with `openspec validate --all --strict`.

## 2. Runner

- [x] 2.1 Add `scripts/vm-e2e-matrix.py`.
- [x] 2.2 Validate required operator inputs and confirmations.
- [x] 2.3 Reject unsafe names, unsafe log paths, manual `VM_DISK` overrides, and guest disks other than `/dev/vda`.
- [x] 2.4 Run all supported cases through `make vm-e2e-install`.
- [x] 2.5 Support bounded parallelism with `VM_E2E_MATRIX_PARALLEL`.
- [x] 2.6 Write per-case logs and matrix summary JSON.
- [x] 2.7 Return non-zero if any case fails.

## 3. Makefile

- [x] 3.1 Add `VM_E2E_MATRIX_LOG_DIR`.
- [x] 3.2 Add `VM_E2E_MATRIX_PARALLEL`.
- [x] 3.3 Add `make vm-e2e-matrix`.
- [x] 3.4 Add help text and export variables.

## 4. Documentation

- [x] 4.1 Update `README.md`.
- [x] 4.2 Update `docs/libvirt-end-to-end-install-validation.md`.
- [x] 4.3 Update `docs/libvirt-install-test-matrix.md`.

## 5. Verification

- [x] 5.1 Run `python3 -m py_compile scripts/vm-e2e-matrix.py`.
- [x] 5.2 Run `make vm-e2e-matrix` only when disposable VM execution is intended.
- [x] 5.3 Run `make ansible-check`.
- [x] 5.4 Run `make secret-check`.
- [x] 5.5 Run OpenSpec validations.
