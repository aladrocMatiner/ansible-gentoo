# Ansible Partition Apply

`make partition` is the first destructive installer target. It applies only the approved GPT partition layout to an explicitly selected disk:

- partition 1: 512 MiB EFI system partition,
- partition 2: remaining disk for the Gentoo root filesystem.

It does not format filesystems, mount filesystems, extract stage3, chroot, install packages, create users, or install a bootloader.

## Required Confirmation

The target fails before Ansible runs unless both variables are set:

```sh
INSTALL_DISK=/dev/<target-disk>
I_UNDERSTAND_THIS_WIPES_DISK=yes
```

For the local libvirt VM only:

```sh
make partition INSTALL_DISK=/dev/vda I_UNDERSTAND_THIS_WIPES_DISK=yes
```

For a network target:

```sh
make partition ANSIBLE_LIVE_HOST=192.0.2.10 INSTALL_DISK=/dev/<target-disk> I_UNDERSTAND_THIS_WIPES_DISK=yes
```

Use only the disk path reported by `make detect-disks` against the same target.

## Safety Gates

Before partition commands run, the workflow:

- runs `make config-check` in destructive mode,
- requires explicit `INSTALL_DISK`,
- requires `I_UNDERSTAND_THIS_WIPES_DISK=yes`,
- connects to the selected live ISO target over SSH,
- runs `common/disk_detection`,
- runs `common/disk_safety`,
- runs read-only install and partition plan roles,
- prints the exact `sgdisk`/`partprobe` command preview,
- fails if the selected disk or any descendant is mounted.

Preview output is not confirmation. Confirmation must be supplied by the operator as a Makefile variable.

## Tooling

The partition apply role uses `sgdisk` and `partprobe` from the live ISO. The commands are passed as `argv` lists, not shell strings.

## Output

The role writes non-secret local evidence under:

```text
logs/install-runs/<run-id>/partition/
```

These logs are ignored by git. They contain before/after `lsblk` output and the reviewed command preview.

## Recovery

If the target fails before partitioning, fix the reported configuration, SSH, disk, mount, or confirmation issue and rerun the relevant read-only plan target.

If partitioning starts and fails, stop. Do not continue to formatting. Collect the partition logs, rerun `make detect-disks`, and review the current disk state before deciding whether to retry.
