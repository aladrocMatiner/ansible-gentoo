# Btrfs Layout Policy

This policy applies when `FILESYSTEM=btrfs` is selected for the basic console installer.

The same Btrfs behavior must be reused by OpenRC and systemd workflows. Init-specific roles must not redefine subvolume names, mount options, or safety checks.

## Approved Subvolumes

The approved v1 Btrfs layout is:

| Subvolume | Target mountpoint |
| --- | --- |
| `@` | `/mnt/gentoo` during install, `/` after boot |
| `@home` | `/mnt/gentoo/home` during install, `/home` after boot |
| `@var` | `/mnt/gentoo/var` during install, `/var` after boot |
| `@var_log` | `/mnt/gentoo/var/log` during install, `/var/log` after boot |
| `@var_cache` | `/mnt/gentoo/var/cache` during install, `/var/cache` after boot |
| `@snapshots` | `/mnt/gentoo/.snapshots` during install, `/.snapshots` after boot |

The root mount must use `subvol=@`. Plans, formatting, mounting, fstab generation, and final checks must all use this same mapping.

## Mount Options

The default Btrfs root mount options are:

```text
noatime,compress=zstd,subvol=@
```

Other Btrfs subvolumes must include their explicit `subvol=...` option and reuse the shared Btrfs option set. Do not hardcode a different layout in OpenRC or systemd-specific roles.

## Snapshot Policy

The installer creates the `@snapshots` subvolume as a mount location only.

v1 does not install snapshot management tools, create automatic snapshots, or configure snapshot timers. A later OpenSpec change must approve that behavior before implementation.

## Safety Rules

Btrfs formatting and subvolume creation are destructive and require the same confirmation model as ext4 formatting:

```sh
make format FILESYSTEM=btrfs INSTALL_DISK=/dev/<target-disk> I_UNDERSTAND_THIS_WIPES_DISK=yes
```

Rules:

- `INSTALL_DISK` must be explicit and has no default.
- The selected disk and target partitions must pass shared disk safety gates.
- Target partitions must not be mounted before formatting.
- Temporary Btrfs setup mounts must be under a documented safe path and unmounted before completion.
- The workflow must fail if cleanup cannot verify that the temporary setup mount is gone.
- Final checks must verify that Btrfs root uses `subvol=@`.
- Btrfs creation evidence must include Btrfs-native verification, such as `btrfs filesystem show`, because generic `lsblk` output on the live ISO may not always report newly created Btrfs metadata.

## Related Targets

Read-only planning:

```sh
make filesystem-plan PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
make mount-plan PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
```

Destructive formatting, only after review and confirmation:

```sh
make format PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda I_UNDERSTAND_THIS_WIPES_DISK=yes
```

Target mounting and fstab generation:

```sh
make mount-target PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
make generate-fstab PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
```

Kernel installation consumes the generated fstab and must keep the Btrfs boot command line aligned with the root subvolume:

```sh
make install-kernel PROFILE=openrc FILESYSTEM=btrfs
```

The generated kernel command line must include `rootflags=subvol=@`.

Inside the local libvirt VM, `/dev/vda` is the disposable guest disk. On real network targets, use the disk path reported by `make detect-disks`.
