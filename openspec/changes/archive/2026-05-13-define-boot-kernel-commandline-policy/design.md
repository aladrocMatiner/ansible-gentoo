# Design: define-boot-kernel-commandline-policy

## Root Identification

The boot flow should use stable root filesystem identification. Preferred policy:

- root filesystem is referenced by UUID where practical,
- generated fstab uses UUIDs,
- GRUB configuration must point to the intended root filesystem,
- no default disk or partition inference is allowed.

## Btrfs

When `FILESYSTEM=btrfs`, the boot configuration must include the equivalent of:

```text
rootflags=subvol=@
```

or otherwise prove that the bootloader/initramfs will mount the approved root subvolume.

## v1 Exclusions

The command line policy must not include:

- LUKS parameters,
- BIOS boot assumptions,
- unsupported root filesystems,
- host-specific debug parameters unless explicitly configured.

## Validation

Final checks should inspect generated GRUB config and installed kernel/initramfs artifacts to verify:

- root UUID is correct,
- Btrfs root flags are present when needed,
- no LUKS arguments are present in v1,
- EFI/UEFI boot path is consistent.
