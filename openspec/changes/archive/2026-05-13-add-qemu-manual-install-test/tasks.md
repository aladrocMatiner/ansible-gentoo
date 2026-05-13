# Tasks: add-qemu-manual-install-test

## 1. Proposal and Design
- [x] Create `proposal.md` describing the QEMU manual install test environment.
- [x] Create `design.md` with VM defaults, required tools, Makefile targets, scripts, and safety requirements.
- [x] Create `tasks.md` with implementation and validation steps.
- [x] Create `specs/qemu-test/spec.md` because `openspec/specs/` exists.

## 2. Makefile Contract
- [x] Add `make qemu-check`; after libvirt migration, keep it as a compatibility alias for `make vm-check`.
- [x] Add `make qemu-disk`; after libvirt migration, keep it as a compatibility alias for `make vm-disk`.
- [x] Add `make qemu-boot`; after libvirt migration, keep it as a compatibility alias for `make vm-start`.
- [x] Add `make qemu-clean`; after libvirt migration, keep it as a compatibility alias for `make vm-clean`.
- [x] Ensure all operator-facing VM actions are exposed through Makefile targets.

## 3. Script Contracts
- [x] Replace direct-QEMU script contract with active libvirt `scripts/vm-*.sh` wrappers through the migration change.
- [x] Ensure scripts are called through Makefile targets.
- [x] Ensure scripts do not require or use `sudo` by default.

## 4. Safety Implementation
- [x] Fail if `./gentoo.iso` does not exist or cannot be resolved to exactly one ISO file.
- [x] Fail if `qemu-system-x86_64` is missing.
- [x] Fail if `qemu-img` is missing.
- [x] Keep `make qemu-check` read-only; it must not create VM artifact directories, disk images, domains, extracted kernels/initrds, or OVMF vars files.
- [x] Create the active VM artifact directory only from non-read-only targets.
- [x] Ensure VM disk paths are relative to the project and under the configured VM artifact directory.
- [x] Reject `/dev/*` paths and common block devices such as `/dev/sda`, `/dev/nvme0n1`, `/dev/vda`, and `/dev/xvda`.
- [x] Reject parent traversal in configured VM disk paths.
- [x] Reject project-root or dot-equivalent VM artifact directories such as `.`, `./`, and `./.`.
- [x] Reject QEMU drive option separators such as commas in paths used by `-drive`.
- [x] Reject wildcard disk matching.
- [x] Reject symlinked QEMU artifact directories and symlinked path components before cleanup.
- [x] Reject symlinked or non-regular per-VM OVMF vars files before UEFI boot.
- [x] Reject symlinked or non-regular per-VM OVMF vars files before cleanup.
- [x] Reject existing configured VM disk files that are not qcow2 images.
- [x] Use qcow2 by default.
- [x] Require explicit confirmation before `make qemu-clean` deletes VM disks.
- [x] Restrict `make qemu-clean` to generated artifacts for the configured project-owned VM domain.

## 5. QEMU Behavior
- [x] Boot the resolved official ISO with the configured project-local qcow2 disk attached through the active libvirt workflow.
- [x] Use x86_64 architecture.
- [x] Use 4096 MB RAM by default.
- [x] Use 2 CPUs by default.
- [x] Use a 40G qcow2 disk by default.
- [x] Use UEFI by default when OVMF firmware is available.
- [x] Reject BIOS boot mode in v1.
- [x] Use libvirt managed networking by default, with user-mode networking only when explicitly configured.
- [x] Provide graphical access through `make vm-viewer` when needed.

## 6. Documentation
- [x] Document how to place the official Gentoo live ISO at `./gentoo.iso` as a file or as the only `.iso` inside `./gentoo.iso/`.
- [x] Document that `make qemu-check`, `make qemu-disk`, `make qemu-boot`, and `make qemu-clean` are compatibility aliases for the active libvirt `vm-*` targets.
- [x] Document that the VM is for manual installation testing only.
- [x] Document that the workflow must never use host block devices.

## 7. Validation
- [x] Run `openspec validate add-qemu-manual-install-test --strict`.
- [x] Run `openspec validate --all --strict`.
- [x] Verify `make qemu-check` routes to `make vm-check` and reports missing tools, missing ISO, or ambiguous ISO directory clearly.
- [x] Verify `make qemu-disk` routes to `make vm-disk` and creates the configured project-local qcow2 disk if missing.
- [x] Verify `make qemu-boot` routes to `make vm-start` and starts the active libvirt VM with the ISO and qcow2 disk.
- [x] Verify `make qemu-clean` routes to `make vm-clean` and requires explicit confirmation before deleting generated artifacts.
- [x] Verify no target or script accepts a real host block device.
