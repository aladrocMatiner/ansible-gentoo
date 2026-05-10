# Design: implement-ansible-filesystem-apply

## Sequence
1. Reuse disk detection and partition state.
2. Reuse filesystem plan.
3. Run shared destructive safety gates.
4. Verify planned partition paths exist.
5. Verify target partitions are not mounted.
6. Verify formatting tools for the selected plan.
7. Create ESP filesystem.
8. Create root filesystem.
9. For Btrfs, create subvolumes using a reviewed temporary mount path.
10. Re-read filesystem state.

## Tooling
Required tools depend on the selected filesystem:

- ESP: `mkfs.vfat` from `dosfstools`.
- ext4 root: `mkfs.ext4` from e2fsprogs.
- Btrfs root: `mkfs.btrfs` from btrfs-progs.

## Btrfs Temporary Mount
If Btrfs subvolumes are created in this change, use a project-documented temporary mount path under `/mnt`, unmount it before completion, and fail if cleanup cannot be verified.

## Safety
No init-specific role may format filesystems.
