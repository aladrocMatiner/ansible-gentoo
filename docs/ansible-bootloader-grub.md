# Ansible GRUB Bootloader

`make install-bootloader` installs GRUB for the UEFI target system mounted at `/mnt/gentoo`.

This is a high-risk workflow because `grub-install` may create or update EFI NVRAM boot entries. It does not partition, format, wipe filesystems, create users, or reboot.

## Run

For the disposable libvirt VM:

```sh
make install-bootloader \
  PROFILE=openrc \
  FILESYSTEM=btrfs \
  INSTALL_DISK=/dev/vda \
  I_UNDERSTAND_BOOTLOADER_CHANGES=yes
```

For real hardware, use the disk reported by `make detect-disks ANSIBLE_LIVE_HOST=...`. Do not copy the VM `/dev/vda` example to real machines.

## Preconditions

Run these first:

```sh
make mount-target INSTALL_DISK=...
make stage3-install PROFILE=...
make prepare-chroot
make configure-portage PROFILE=...
make generate-fstab INSTALL_DISK=... FILESYSTEM=...
make install-kernel PROFILE=... FILESYSTEM=...
```

The workflow requires:

- UEFI mode through `/sys/firmware/efi`.
- EFI system partition mounted at `/mnt/gentoo/boot/efi`.
- Target EFI path `/boot/efi` inside the chroot.
- Generated `/mnt/gentoo/etc/fstab`.
- Generated `/mnt/gentoo/etc/kernel/cmdline`.
- Kernel and initramfs files under `/mnt/gentoo/boot`.
- Explicit `INSTALL_DISK`.
- Explicit `I_UNDERSTAND_BOOTLOADER_CHANGES=yes`.

## Behavior

- Reuses read-only disk detection and disk safety gates.
- Allows mounted descendants because the target root and ESP are expected to be mounted.
- Shows current EFI boot entries before running GRUB actions.
- Ensures `GRUB_PLATFORMS="efi-64"`.
- Installs `sys-boot/grub` and `sys-boot/efibootmgr`.
- Writes `GRUB_CMDLINE_LINUX` from the approved kernel command line.
- Runs `grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Gentoo --recheck` when the EFI loader is missing or GRUB was updated.
- Generates `/boot/grub/grub.cfg` and installs it only when the generated candidate differs.
- Validates `root=UUID=...` and, for Btrfs, `rootflags=subvol=@`.

## Failure Modes

- Missing confirmation: pass `I_UNDERSTAND_BOOTLOADER_CHANGES=yes`.
- Missing `INSTALL_DISK`: run `make detect-disks` and pass the selected target disk explicitly.
- BIOS boot: v1 supports UEFI only.
- Missing EFI mount: rerun `make mount-target`.
- Missing kernel/initramfs: rerun `make install-kernel`.
- Missing command line policy: rerun `make generate-fstab` and `make install-kernel`.
- GRUB package installation failure: inspect Portage output and target `/etc/portage/make.conf`.

## Output Artifacts

Non-secret bootloader evidence is written under:

```text
logs/install-runs/<run-id>/bootloader/grub.json
```

The evidence includes selected disk identity, EFI entries before and after, kernel command line, whether `grub-install` ran, and whether `grub.cfg` changed.
