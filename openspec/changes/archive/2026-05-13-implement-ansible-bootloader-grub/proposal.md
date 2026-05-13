# Change: implement-ansible-bootloader-grub

## Summary
Install and configure GRUB for UEFI boot on the target Gentoo system.

## Motivation
The installed system must boot from UEFI using GRUB. This is high-risk because it can alter persistent boot entries.

This change maps to the Gentoo AMD64 Handbook bootloader phase. The project intentionally standardizes on GRUB for UEFI v1 and must use the EFI mount layout produced by earlier roles.

## Scope
- Add shared `common/bootloader` role.
- Verify UEFI mode.
- Verify EFI partition mounted at `/boot/efi` inside the target system, corresponding to host path `/mnt/gentoo/boot/efi` before chroot.
- Install GRUB package if not already present.
- Run `grub-install` and generate GRUB config.
- Show EFI boot entries before changes.
- Print or call destructive preview before changing bootloader or EFI state.
- Record bootloader evidence for install state and audit bundle.
- Follow boot kernel command line policy for root UUID and Btrfs `rootflags=subvol=@`.

## Non-goals
- Do not support BIOS boot in v1.
- Do not support Secure Boot in v1.
- Do not install alternative bootloaders.

## Safety Requirements
- Require explicit boot disk.
- Do not run `grub-install` without showing disk identity.
- Do not run `efibootmgr` changes without showing current entries.
- Do not treat preview output as confirmation.
- Log bootloader changes.

## Acceptance Criteria
- GRUB EFI files exist after installation.
- GRUB config exists.
- GRUB uses the project EFI mountpoint consistently.
- Current EFI entries are shown before changes.
- Bootloader changes are recorded in logs/audit output.
- Generated GRUB config follows the approved boot command line policy.
- `openspec validate implement-ansible-bootloader-grub --strict` passes.

## Affected Files
- `ansible/roles/common/bootloader/`
- `docs/`
- `skills/`
