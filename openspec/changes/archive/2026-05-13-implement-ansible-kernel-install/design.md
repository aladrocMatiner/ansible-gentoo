# Design: implement-ansible-kernel-install

## Package
Use `sys-kernel/gentoo-kernel-bin`.

Install or configure `sys-kernel/installkernel` support as needed so kernel installation produces the kernel and initramfs artifacts expected by the later GRUB workflow.

This change enables the `dracut` installkernel behavior required for distribution-kernel initramfs generation. It must not enable package settings that pull in or install `sys-boot/grub`; GRUB package installation, `grub-install`, `grub-mkconfig`, and EFI boot entry changes belong to the bootloader change.

## Execution
Run package operations inside the prepared target environment through the project chroot mechanism.

## Validation
Check `/boot` for kernel and initramfs artifacts after installation.

Validate that kernel artifacts are compatible with the selected bootloader plan before the GRUB change runs.
