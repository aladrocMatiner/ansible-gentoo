# Ansible Filesystem Apply

`make format` is a destructive installer target. It creates filesystems on the approved ESP/root partition layout for an explicitly selected disk.

It does not partition disks, mount the final target root, extract stage3, chroot, install packages, create users, or install a bootloader.

## Required Confirmation

The target fails before Ansible runs unless both variables are set:

```sh
INSTALL_DISK=/dev/<target-disk>
I_UNDERSTAND_THIS_WIPES_DISK=yes
```

For the local libvirt VM only:

```sh
make format FILESYSTEM=ext4 INSTALL_DISK=/dev/vda I_UNDERSTAND_THIS_WIPES_DISK=yes
make format FILESYSTEM=btrfs INSTALL_DISK=/dev/vda I_UNDERSTAND_THIS_WIPES_DISK=yes
```

For a network target:

```sh
make format ANSIBLE_LIVE_HOST=192.0.2.10 FILESYSTEM=ext4 INSTALL_DISK=/dev/<target-disk> I_UNDERSTAND_THIS_WIPES_DISK=yes
```

Use only the disk path reported by `make detect-disks` against the same target.

## Safety Gates

Before formatting commands run, the workflow:

- runs `make config-check` in destructive mode,
- requires explicit `INSTALL_DISK`,
- requires `I_UNDERSTAND_THIS_WIPES_DISK=yes`,
- connects to the selected live ISO target over SSH,
- runs `common/disk_detection`,
- runs `common/disk_safety` with confirmation enabled,
- runs read-only install, partition, mount, and filesystem plan roles,
- prints the exact filesystem command preview,
- fails if the selected disk or any descendant is mounted,
- fails if either planned partition path is missing,
- fails if ESP and root partition paths are not distinct.

Preview output is not confirmation. Confirmation must be supplied by the operator as a Makefile variable.

## ext4 Behavior

For `FILESYSTEM=ext4`, the workflow creates:

- vfat/FAT32 on partition 1 with label `EFI`,
- ext4 on partition 2 with label `GENTOO_ROOT`.

Required tools on the live ISO target:

- `mkfs.vfat`
- `mkfs.ext4`

## Btrfs Behavior

For `FILESYSTEM=btrfs`, the workflow creates:

- vfat/FAT32 on partition 1 with label `EFI`,
- Btrfs on partition 2 with label `GENTOO_ROOT`,
- the approved Btrfs subvolumes from `docs/btrfs-layout-policy.md`.

The temporary setup mount is:

```text
/mnt/gentoo-ai-installer-btrfs-setup
```

The workflow mounts the Btrfs top level there only long enough to create subvolumes, then unmounts it and removes the temporary directory. It fails if the temporary setup mount is still mounted after cleanup.

Required tools on the live ISO target:

- `mkfs.vfat`
- `mkfs.btrfs`
- `btrfs`
- `mount`
- `umount`

Some live ISO tool combinations may not report a newly created Btrfs filesystem through `lsblk` immediately or at all. The filesystem role verifies Btrfs with `btrfs filesystem show` and records that output in the audit logs.

## Output

The role writes non-secret local evidence under:

```text
logs/install-runs/<run-id>/filesystem/
```

The logs include before/after block state, the destructive preview, Btrfs filesystem evidence when applicable, and created subvolume names.

## Recovery

If the target fails before formatting, fix the reported configuration, SSH, disk, partition, mount, tool, or confirmation issue and rerun the relevant read-only plan target.

If formatting starts and fails, stop. Do not continue to mounting or stage3 extraction. Collect filesystem logs, run `make detect-disks`, and review the current partition and filesystem state before deciding whether to retry.
