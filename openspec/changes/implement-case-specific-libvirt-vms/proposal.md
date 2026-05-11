## Why

The project now supports four amd64 basic console install cases: OpenRC/ext4, OpenRC/Btrfs, systemd/ext4, and systemd/Btrfs. The local libvirt harness needs stable, case-specific VM identities so each case can be prepared, booted, inspected, cleaned, and logged without reusing a generic VM name or disk.

## What Changes

- Add case-specific libvirt VM naming for every supported platform/init/filesystem combination.
- Use VM names that include the v1 platform, init system, and filesystem, such as `gentoo-test-amd64-openrc-ext4` and `gentoo-test-amd64-systemd-btrfs`.
- Allow an optional manual test image label in the VM naming scheme, such as `gentoo-test-handbook-amd64-openrc-ext4`.
- Derive case-specific qcow2 disks, OVMF variables files, generated XML, SSH connection metadata, install-state files, and logs from the same case identity.
- Update Makefile-facing VM workflows so operators can select `PROFILE=openrc|systemd` and `FILESYSTEM=ext4|btrfs`.
- Add a safe way to list the supported VM cases and their derived domain/disk names before creating or starting anything.
- Add per-case quickstart documentation for creating, booting, planning, installing, validating, and cleaning each disposable VM case through Makefile targets.
- Keep Ansible roles generic and SSH-driven; libvirt case naming remains local validation harness behavior only.
- Update documentation, agent instructions, skills, and OpenSpec task tracking for the case-specific VM workflow.

## Capabilities

### New Capabilities

- `case-specific-libvirt-vms`: Defines deterministic local libvirt VM identities and artifacts for OpenRC/systemd and ext4/Btrfs validation cases.

### Modified Capabilities

## Impact

- `Makefile` VM targets may need to derive `VM_NAME`, `VM_DISK`, and logs from optional `VM_TEST_IMAGE_NAME`, platform `amd64`, `PROFILE`, and `FILESYSTEM`.
- `scripts/vm-*.sh` helpers may need shared case selection and validation logic.
- `scripts/vm-test-matrix-plan.py` should report the same case VM naming used by executable VM targets.
- Local VM install-state and connection artifacts should be separated per case so one case does not overwrite another case's validation evidence.
- `docs/libvirt-manual-install-test.md`, `docs/libvirt-install-test-matrix.md`, and related VM docs should document the four concrete VM cases.
- `docs/quickstarts/` should provide one quickstart per supported amd64 profile/filesystem case.
- `docs/ansible-architecture.md` should keep the boundary clear: case-specific VMs are local harness targets; reusable Ansible remains remote/network-target oriented.
- `AGENTS.md`, `agents/`, and `skills/` may need references to the case-specific local VM workflow and documentation obligations.
