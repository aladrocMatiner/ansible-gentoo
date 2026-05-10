# Design: implement-ansible-kernel-install

## Package
Use `sys-kernel/gentoo-kernel-bin`.

Install or configure `sys-kernel/installkernel` support as needed so kernel installation produces the artifacts expected by the GRUB workflow. For GRUB, the project should enable the required installkernel behavior deliberately rather than relying on implicit defaults.

## Execution
Run package operations inside the prepared target environment through the project chroot mechanism.

## Validation
Check `/boot` for kernel and initramfs artifacts after installation.

Validate that kernel artifacts are compatible with the selected bootloader plan before the GRUB change runs.
