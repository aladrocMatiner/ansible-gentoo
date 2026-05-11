# Ansible Kernel Install

`make install-kernel` installs the Gentoo distribution kernel into the mounted target root using the shared Ansible flow.

This target follows the Gentoo AMD64 Handbook distribution-kernel phase. It installs `sys-kernel/gentoo-kernel-bin` with installkernel/dracut initramfs support, then validates target `/boot` artifacts for the later GRUB workflow.

Kernel command line behavior follows `docs/boot-kernel-commandline-policy.md`.

## Scope

This target modifies the target root under `/mnt/gentoo`.

It does:

- require a prepared chroot environment under `/mnt/gentoo`,
- require `/mnt/gentoo/boot/efi` to be mounted as vfat,
- configure target Portage package USE for installkernel/dracut support,
- derive the kernel command line from target `/etc/fstab`,
- write `/mnt/gentoo/etc/kernel/cmdline`,
- write `/mnt/gentoo/etc/cmdline.d/00-gentoo-ai-installer.conf`,
- install `sys-kernel/installkernel`, `sys-kernel/dracut`, and `sys-kernel/gentoo-kernel-bin`,
- run `emerge --config sys-kernel/gentoo-kernel-bin` when needed,
- validate kernel, initramfs, and module artifacts,
- write non-secret evidence under `logs/install-runs/<run-id>/kernel/`.

It does not:

- partition disks,
- format filesystems,
- install GRUB,
- run `grub-install`,
- run `efibootmgr`,
- create users,
- enable services,
- reboot the system.

## Required State

Run the earlier targets first:

```sh
make mount-target PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda
make stage3-install PROFILE=openrc FILESYSTEM=ext4
make prepare-chroot PROFILE=openrc FILESYSTEM=ext4
make configure-portage PROFILE=openrc FILESYSTEM=ext4
make generate-fstab PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda
```

Inside the local libvirt VM, `/dev/vda` is the disposable guest disk. On a real network target, use the disk path reported by `make detect-disks`; do not reuse the VM example path as a default.

For Btrfs, keep the same selected filesystem through all targets:

```sh
make install-kernel PROFILE=openrc FILESYSTEM=btrfs
```

## Command

```sh
make install-kernel PROFILE=openrc FILESYSTEM=ext4
```

For a remote official Gentoo live ISO target, pass the SSH endpoint:

```sh
make install-kernel PROFILE=openrc FILESYSTEM=ext4 ANSIBLE_LIVE_HOST=192.0.2.10
```

If `ANSIBLE_LIVE_HOST` is empty, the wrapper may discover the configured local libvirt VM for testing.

## Kernel Command Line

The role reads the root entry from `/mnt/gentoo/etc/fstab`.

For ext4, the generated command line uses:

```text
root=UUID=<root-uuid> rootfstype=ext4
```

For Btrfs, the generated command line uses:

```text
root=UUID=<root-uuid> rootfstype=btrfs rootflags=subvol=@
```

The role rejects command lines that contain `/dev/`, LUKS arguments, resume arguments, or missing Btrfs `rootflags=subvol=@`.

## Validation

Successful output must show:

- `gentoo-kernel-bin` installed in the target,
- at least one `vmlinuz-*` file under `/mnt/gentoo/boot`,
- at least one `initramfs-*` or `initrd*` file under `/mnt/gentoo/boot`,
- at least one module directory under `/mnt/gentoo/lib/modules`,
- a kernel report with `final_checks_input: true`.

The target is intended to be rerunnable. A second run should normally report no changes if the kernel package, command line files, and artifacts are already correct.

## Failure Modes

- `/mnt/gentoo` is not mounted.
- Stage3 was not extracted.
- Chroot pseudo-filesystems were not prepared.
- `/mnt/gentoo/boot/efi` is missing or is not vfat.
- `/mnt/gentoo/etc/fstab` is missing a UUID root entry.
- `FILESYSTEM=btrfs` is selected but fstab root options do not include `subvol=@`.
- Portage cannot resolve or install kernel packages.
- `installkernel` refuses to generate initramfs because no command line is configured.
- Kernel or initramfs files are missing after package configuration.

## Recovery

- If mount checks fail, rerun `make mount-target` and `make prepare-chroot`.
- If fstab checks fail, rerun `make generate-fstab` with the same `PROFILE`, `FILESYSTEM`, and `INSTALL_DISK`.
- If Portage package resolution fails, rerun `make configure-portage` and inspect target Portage configuration.
- If initramfs generation fails, inspect `/mnt/gentoo/etc/kernel/cmdline` and `/mnt/gentoo/etc/cmdline.d/00-gentoo-ai-installer.conf`.
- Do not continue to GRUB until kernel and initramfs artifacts are present.

## Output Artifacts

- `/mnt/gentoo/etc/portage/package.use/gentoo-ai-installer-kernel`
- `/mnt/gentoo/etc/kernel/cmdline`
- `/mnt/gentoo/etc/cmdline.d/00-gentoo-ai-installer.conf`
- `/mnt/gentoo/boot/vmlinuz-*`
- `/mnt/gentoo/boot/initramfs-*` or `/mnt/gentoo/boot/initrd*`
- `/mnt/gentoo/lib/modules/<kernel-version>/`
- `logs/install-runs/<run-id>/kernel/kernel.json`
