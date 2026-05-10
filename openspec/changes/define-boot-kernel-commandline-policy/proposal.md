## Why

GRUB, fstab, initramfs, and Btrfs behavior all depend on a consistent kernel command line policy. The project needs to define how the installed system identifies root and which boot arguments are allowed before bootloader implementation.

## What Changes

- Define root identification policy for GRUB/kernel command line.
- Define Btrfs `rootflags=subvol=@` behavior.
- Define v1 exclusions such as LUKS and BIOS boot.
- Require final checks to verify generated GRUB config references the intended root.

## Capabilities

### New Capabilities
- `boot-kernel-commandline`: Defines bootloader/kernel command line requirements for the installed target.

### Modified Capabilities

## Impact

- Kernel install.
- fstab generation.
- GRUB bootloader.
- Final checks.
- Btrfs policy.
- Docs and skills.
