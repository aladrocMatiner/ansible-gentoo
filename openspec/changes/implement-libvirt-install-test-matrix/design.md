# Design: implement-libvirt-install-test-matrix

## Matrix Entries

Required planned matrix:

| Profile | Filesystem |
| --- | --- |
| `openrc` | `ext4` |
| `openrc` | `btrfs` |
| `systemd` | `ext4` |
| `systemd` | `btrfs` |

## Test Phases

Matrix validation should progress in phases:

1. read-only preflight, disk detection, install plan, partition plan, mount plan, filesystem plan,
2. destructive install in disposable libvirt disks once apply roles exist,
3. first-boot validation once bootloader and final checks exist.

## Safety

- Use only project-local qcow2 disks under the approved libvirt artifact directory.
- Never use host block devices.
- Require explicit destructive confirmations for full-install matrix runs.
- Use separate disks or restored snapshots per matrix entry.
- Keep VM domains and artifacts named so cleanup cannot affect unrelated VMs.

## Makefile Integration

Planned targets may include:

- `make vm-test-matrix`
- `make vm-test-matrix-plan`
- `make vm-test-matrix-clean`

Only implemented targets should be advertised as runnable in README quickstarts.
