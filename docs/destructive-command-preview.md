# Destructive Command Preview

Preview targets show what a destructive or high-risk operation would do without making target changes, writing install-state checkpoints, or setting confirmation variables.

## Targets

Generic dispatcher:

```sh
make destructive-preview PREVIEW_TARGET=partition INSTALL_DISK=<disk>
make destructive-preview PREVIEW_TARGET=format FILESYSTEM=ext4 INSTALL_DISK=<disk>
make destructive-preview PREVIEW_TARGET=mount FILESYSTEM=btrfs INSTALL_DISK=<disk>
make destructive-preview PREVIEW_TARGET=users ADMIN_USER=<name>
make destructive-preview PREVIEW_TARGET=bootloader INSTALL_DISK=<disk>
```

Convenience targets:

```sh
make partition-preview INSTALL_DISK=<disk>
make format-preview FILESYSTEM=btrfs INSTALL_DISK=<disk>
make mount-preview FILESYSTEM=btrfs INSTALL_DISK=<disk>
make users-preview ADMIN_USER=<name>
make bootloader-preview INSTALL_DISK=<disk>
```

For the local libvirt VM only, `/dev/vda` is the expected guest disk example. For network or physical targets, use the disk path from `make detect-disks ANSIBLE_LIVE_HOST=...`.

## Preview Schema

Preview output must include:

- `preview_schema_version`
- `preview_type`
- `read_only`
- `destructive_commands_run`
- selected disk path
- disk identity and descendants when applicable
- current filesystems and mountpoints when applicable
- planned operations
- required confirmation variables
- `preview_does_not_confirm`

Existing partition, filesystem, and mount previews reuse:

- `make partition-plan`
- `make filesystem-plan`
- `make mount-plan`

Bootloader preview uses `make bootloader-preview` to show target disk, `/mnt/gentoo/boot/efi`, current EFI entries when readable, planned GRUB steps, and the required `I_UNDERSTAND_BOOTLOADER_CHANGES=yes`.

Users preview uses `make users-preview ADMIN_USER=<name>` to show the target mount state, whether the admin user appears in the target passwd file, planned group/sudo/password-hash/authorized_keys changes, and whether optional secret input files are set. It never prints password hash file paths, password hash contents, or authorized_keys contents.

## Confirmation Boundary

Preview success is not approval.

- `make partition` and `make format` still require `I_UNDERSTAND_THIS_WIPES_DISK=yes`.
- `make install-bootloader` still requires `I_UNDERSTAND_BOOTLOADER_CHANGES=yes`.
- Preview targets must not export, write, infer, or persist confirmation variables.

## Safety

Preview targets are read-only for target disks and boot state. They must not run:

- `sgdisk`
- `parted`
- `fdisk`
- `wipefs`
- `mkfs.*`
- `mount`
- `umount`
- `useradd`
- `usermod`
- `passwd`
- `chpasswd`
- `grub-install`
- boot-entry-changing `efibootmgr`

They may run read-only inventory commands such as `lsblk`, `findmnt`, and `efibootmgr -v`.

## Failure Modes

- Missing `INSTALL_DISK`: pass a disk from the same target's `make detect-disks` output.
- Mounted descendants: partition and filesystem previews fail through shared disk safety if a destructive operation would be unsafe.
- Existing target mountpoints: mount preview reports current path and mountpoint state before `make mount-target`.
- Missing `ADMIN_USER`: users preview requires the explicit target admin username because there is no safe default.
- Missing `/mnt/gentoo/boot/efi`: bootloader preview reports the mount lookup failure without installing anything.
- Missing UEFI/EFI tooling: bootloader preview reports unavailable EFI entry output.

## Recovery

Run the relevant read-only plan again after fixing target state:

```sh
make detect-disks
make partition-preview INSTALL_DISK=<disk>
make format-preview FILESYSTEM=<ext4|btrfs> INSTALL_DISK=<disk>
make mount-preview FILESYSTEM=<ext4|btrfs> INSTALL_DISK=<disk>
make users-preview ADMIN_USER=<name>
make bootloader-preview INSTALL_DISK=<disk>
```

Do not continue to an apply target until the preview output matches the intended target.
