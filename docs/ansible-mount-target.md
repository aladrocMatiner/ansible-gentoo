# Ansible Mount Target

`make mount-target` mounts the formatted Gentoo target filesystems through the shared SSH-based Ansible workflow.

It does not partition, format, wipe, extract stage3, chroot, install packages, create users, enable services, or install a bootloader.

## Required State

Run these steps first against the same live ISO target:

```sh
make ansible-live-preflight
make detect-disks
make partition-plan PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
make partition PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda I_UNDERSTAND_THIS_WIPES_DISK=yes
make format PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda I_UNDERSTAND_THIS_WIPES_DISK=yes
```

Inside the local libvirt VM, `/dev/vda` is the expected guest disk backed by the project-local qcow2 image. It must still be passed explicitly. For a network target, use the disk path reported by `make detect-disks` on that target.

## Command

For the local libvirt VM:

```sh
make mount-target PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda
make mount-target PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
```

For a network live ISO target:

```sh
make mount-target ANSIBLE_LIVE_HOST=192.0.2.10 PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/<target-disk>
```

`PROFILE` may be `openrc` or `systemd`. `FILESYSTEM` may be `ext4` or `btrfs`.

## Mount Layout

For `FILESYSTEM=ext4`, the workflow mounts:

- root partition at `/mnt/gentoo` with `-t ext4 -o defaults`
- EFI system partition at `/mnt/gentoo/boot/efi` with `-t vfat -o defaults`

For `FILESYSTEM=btrfs`, the workflow mounts:

- root partition at `/mnt/gentoo` with `noatime,compress=zstd,subvol=@`
- `@home` at `/mnt/gentoo/home`
- `@var` at `/mnt/gentoo/var`
- `@var_log` at `/mnt/gentoo/var/log`
- `@var_cache` at `/mnt/gentoo/var/cache`
- `@snapshots` at `/mnt/gentoo/.snapshots`
- EFI system partition at `/mnt/gentoo/boot/efi`

The Btrfs subvolume names and mountpoints are the approved shared policy from `docs/btrfs-layout-policy.md`.

## Safety Gates

The workflow:

- requires explicit `INSTALL_DISK`; there is no default disk,
- validates `PROFILE` and `FILESYSTEM`,
- connects to the booted official Gentoo live ISO over SSH,
- reuses shared disk detection, disk safety, install plan, partition plan, mount plan, and filesystem plan roles,
- allows already-mounted descendants only for this mount workflow,
- validates any existing target mounts against the approved source, filesystem type, and Btrfs subvolume,
- refuses target mount paths other than `/mnt/gentoo` and `/mnt/gentoo/boot/efi`,
- refuses to mount ESP and root from the same partition,
- verifies ext4 with `blkid`,
- verifies Btrfs with `btrfs filesystem show`,
- verifies EFI with `blkid`,
- prints planned mount-over behavior before mounting,
- records mount state before and after apply.

`make mount-target` is not a disk-wiping target, so it does not require `I_UNDERSTAND_THIS_WIPES_DISK=yes`. It is still safety-sensitive because mounting over an unexpected path can hide data. If an existing mount does not match the plan, the role fails closed with `MOUNT_UNSAFE`.

## Idempotency

Re-running the target is expected to report `changed=0` when all mounts already match the approved plan.

The role validates existing mounts instead of remounting them. For Btrfs, it checks that root is mounted with `subvol=@` and that every approved subvolume mount uses the expected source and subvolume option.

## Output

The role writes non-secret local evidence under:

```text
logs/install-runs/<run-id>/mount-target/
```

The evidence includes:

- selected disk,
- filesystem selection,
- mount preview,
- `findmnt` output before apply,
- `findmnt` output after apply.

## Recovery

If `make mount-target` fails, do not run manual mount commands first. Review the reported `MOUNT_UNSAFE`, filesystem, SSH, or plan error and rerun:

```sh
make detect-disks
make mount-plan PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
make filesystem-plan PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
```

If an unrelated filesystem is mounted under `/mnt/gentoo`, stop and inspect the target manually before continuing. Unmount only paths that you have confirmed belong to the disposable test VM or the intended target.
