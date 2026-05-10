# Design: implement-ansible-bootloader-grub

## Checks
Verify UEFI, target mount, EFI mount, kernel artifacts, fstab, and boot disk identity before GRUB actions.

The project mount layout is:

- live ISO path before chroot: `/mnt/gentoo/boot/efi`
- target path inside chroot: `/boot/efi`

GRUB commands must use the target-system EFI directory consistently and must not assume an alternate ESP path such as `/boot` or `/efi` unless a later approved change changes the layout.

## Commands
Use chroot-scoped GRUB commands where appropriate. Show `efibootmgr` current entries before installation.

## Safety
Bootloader work is high-risk and must be isolated from partitioning and formatting.
