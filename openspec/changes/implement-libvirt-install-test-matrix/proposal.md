## Why

The installer will support amd64 OpenRC/systemd, ext4/Btrfs, and standard/hardened/musl stage3 flavors. A single happy-path VM test is not enough to catch drift between variants.

## What Changes

- Define a libvirt-backed test matrix for basic console install validation.
- Cover amd64 OpenRC/systemd, ext4/Btrfs, and standard/hardened/musl stage3 flavor combinations.
- Support an optional manual test image label in planned matrix names.
- Keep tests on project-local qcow2 disks and the official Gentoo live ISO.
- Separate read-only plan validation from destructive full-install validation.
- Produce logs and audit bundle references for each matrix entry.

## Capabilities

### New Capabilities
- `libvirt-install-test-matrix`: Runs or plans variant validation across the amd64 platform, init systems, and filesystem types in libvirt.

### Modified Capabilities

## Impact

- Future Makefile targets for matrix validation.
- Future docs for VM matrix operation.
- Existing libvirt end-to-end validation proposal.
