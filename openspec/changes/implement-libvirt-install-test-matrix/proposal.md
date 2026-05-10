## Why

The installer will support OpenRC/systemd and ext4/Btrfs. A single happy-path VM test is not enough to catch drift between variants.

## What Changes

- Define a libvirt-backed test matrix for basic console install validation.
- Cover OpenRC + ext4, OpenRC + Btrfs, systemd + ext4, and systemd + Btrfs.
- Keep tests on project-local qcow2 disks and the official Gentoo live ISO.
- Separate read-only plan validation from destructive full-install validation.
- Produce logs and audit bundle references for each matrix entry.

## Capabilities

### New Capabilities
- `libvirt-install-test-matrix`: Runs or plans variant validation across init systems and filesystem types in libvirt.

### Modified Capabilities

## Impact

- Future Makefile targets for matrix validation.
- Future docs for VM matrix operation.
- Existing libvirt end-to-end validation proposal.
