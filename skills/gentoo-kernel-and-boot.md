# Gentoo Kernel and Boot Skill

## 1. Purpose
This skill describes the v1 kernel and bootloader workflow for `gentoo-ai-installer`.

The v1 system uses `gentoo-kernel-bin`, GRUB, UEFI, no LUKS, and an explicitly selected root filesystem plan. ext4 is the default; Btrfs subvolumes are allowed only where an approved OpenSpec change defines the plan or implementation. The Makefile is the operator-facing control plane.

This skill defines the workflow and safety requirements. It does not implement scripts.

## 2. When to Use This Skill
Use this skill:

- After stage3 extraction and Portage configuration.
- After the target root is mounted at `/mnt/gentoo`.
- After the EFI system partition is mounted at `/boot/efi` inside the target.
- Before final reboot into the installed system.
- When designing future Ansible `kernel`, `bootloader`, and `final_checks` roles.

Do not use this skill before UEFI, target root, and EFI mount state are confirmed.

## 3. Required Context
- Confirmed UEFI boot mode.
- Target root mounted at `/mnt/gentoo`.
- EFI system partition mounted at `/boot/efi` inside the target.
- Root filesystem is explicitly planned as ext4 or Btrfs.
- Root filesystem UUID.
- `/etc/fstab` entries for root and EFI.
- Kernel package: `gentoo-kernel-bin`.
- Bootloader: GRUB.
- NetworkManager service plan.
- Operator-provided boot disk for GRUB installation.

## 4. Kernel Package Policy
Policy:

- Use `gentoo-kernel-bin` for v1.
- Avoid custom kernel compilation in v1.
- Avoid kernel source configuration workflows in v1 unless a later OpenSpec change approves them.
- Install kernel through Makefile target `make install-kernel`.
- Record installed kernel version and installed files.

Rationale: `gentoo-kernel-bin` reduces build time and risk during the first reproducible installer version.

## 5. Initramfs Policy
Policy:

- No LUKS in v1.
- Btrfs requires explicit `FILESYSTEM=btrfs` planning and documented subvolume behavior.
- Root filesystem defaults to ext4 when no filesystem override is provided.
- Initramfs should not be made complex unless required by `gentoo-kernel-bin`, hardware, or boot validation.
- If an initramfs is generated or installed by package behavior, record it.
- Do not introduce dracut, genkernel, custom initramfs logic, or LUKS/Btrfs boot handling without an OpenSpec change.

## 6. UEFI Requirements
Before installing GRUB for UEFI:

- Confirm `/sys/firmware/efi` exists in the live environment.
- Confirm the machine was booted in UEFI mode.
- Confirm EFI variables are visible if `efibootmgr` will be used.
- Show current EFI boot entries before changing them.
- Stop if the live ISO was booted in BIOS mode.

`efibootmgr` must not be run without showing current boot entries first.

## 7. EFI System Partition Requirements
The EFI system partition must:

- Be the partition from the approved disk plan.
- Be mounted at `/boot/efi` inside the target system.
- Use a UEFI-compatible filesystem.
- Have expected EFI directory structure after bootloader installation.
- Be represented in `/etc/fstab` with a stable identifier.

Safety requirements:

- Confirm target root is mounted at `/mnt/gentoo`.
- Confirm EFI partition is mounted at `/boot/efi`.
- Confirm `/boot/efi` refers to the target mount path, not the live ISO root.
- Stop if the EFI partition mount is missing or ambiguous.

## 8. GRUB Installation Expectations
Use:

```text
make install-bootloader
```

Expectations:

- Confirm UEFI mode before installing GRUB for UEFI.
- Confirm target root is mounted at `/mnt/gentoo`.
- Confirm EFI partition is mounted at `/boot/efi`.
- Require an operator-provided boot disk.
- Do not run `grub-install` against an unspecified disk.
- Show the target disk, EFI mount, bootloader ID, and current EFI boot entries before changes.
- Log bootloader changes.
- Treat GRUB installation as high risk because it changes persistent boot behavior.

## 9. GRUB Configuration Expectations
Use:

```text
make configure-grub
```

Expectations:

- Generate GRUB config only after kernel files exist.
- Use stable root filesystem UUIDs.
- Confirm `/etc/fstab` root and EFI entries match discovered UUIDs.
- Confirm no LUKS is added in v1. For Btrfs, confirm root UUID, subvolume mount options, and GRUB configuration are documented before bootloader work is implemented.
- Log generated GRUB config path and timestamp.
- Review GRUB config for the expected kernel entries.

## 10. Boot Validation Checks
Use:

```text
make final-boot-checks
```

Validation should check:

- Kernel files exist in `/boot`.
- GRUB config exists.
- EFI boot files exist.
- `/etc/fstab` has correct entries.
- NetworkManager is enabled for boot.
- Root filesystem UUIDs are correct.
- EFI partition UUID or stable identifier is correct.
- Target root is still mounted at `/mnt/gentoo` during checks.
- No BIOS-only boot assumptions are present.
- Logs of bootloader changes exist.

Do not recommend reboot until final boot checks pass or the operator has accepted a documented recovery plan.

## 11. Makefile Targets
Expected targets:

These targets define the expected control-plane contract for kernel and bootloader setup. If a target is not present in the current `Makefile`, treat it as planned and do not document it as runnable in user-facing docs.

- `make install-kernel`
- `make install-bootloader`
- `make configure-grub`
- `make final-boot-checks`

Target expectations:

- `make install-kernel`: install `gentoo-kernel-bin` in the target and record installed kernel files.
- `make install-bootloader`: install GRUB for UEFI only after safety gates pass.
- `make configure-grub`: generate and review GRUB configuration.
- `make final-boot-checks`: validate kernel, GRUB, EFI files, fstab, UUIDs, and NetworkManager.

The operator should not be asked to run raw `grub-install`, `efibootmgr`, GRUB config, kernel install, or service enablement commands when Makefile targets exist.

## 12. Failure Modes
- Live ISO booted in BIOS mode.
- `/sys/firmware/efi` is missing.
- EFI variables are unavailable.
- Target root is not mounted at `/mnt/gentoo`.
- EFI partition is not mounted at `/boot/efi`.
- GRUB target disk is unspecified.
- GRUB is installed to the wrong disk.
- Current EFI boot entries were not shown before changes.
- Kernel files are missing from `/boot`.
- GRUB config is missing or references the wrong root UUID.
- `/etc/fstab` uses volatile disk names or wrong UUIDs.
- NetworkManager is not enabled for boot.
- Bootloader changes were not logged.

## 13. Recovery Advice
- If UEFI is missing, reboot the live ISO using the UEFI boot entry.
- If target root or EFI mount is missing, return to mount validation before bootloader work.
- If root UUIDs differ from fstab or GRUB config, regenerate the plan before making more bootloader changes.
- If `grub-install` fails, do not retry with a different disk until UEFI mode, EFI mount, target root, and operator-provided boot disk are re-confirmed.
- If EFI boot entries look wrong, record current entries before changing anything else.
- If final boot checks fail, do not reboot until failures are corrected or a recovery plan is documented.
- Keep the official Gentoo live ISO available for recovery after first reboot.

## 14. Output Artifacts
This skill should produce or request:

- Installed kernel package version.
- List of kernel files in `/boot`.
- Root filesystem UUID.
- EFI partition UUID or stable identifier.
- `/etc/fstab` review result.
- Current EFI boot entries before changes.
- GRUB installation log.
- GRUB configuration path and timestamp.
- EFI boot files summary.
- NetworkManager enablement status.
- Final boot validation report.
- Recovery notes before reboot.

## Documentation maintenance
When kernel, initramfs, GRUB, UEFI, EFI mount, or boot validation behavior changes, documentation must change in the same implementation step.

- If the kernel package, initramfs policy, GRUB package, UEFI assumptions, EFI mount point, or boot validation checks change, update this skill and the relevant manual install documentation under `docs/`.
- If bootloader installation behavior changes, update `agents/safety-review-agent.md` and safety documentation because GRUB and EFI changes are high risk.
- If Makefile targets such as `make install-kernel`, `make install-bootloader`, `make configure-grub`, or `make final-boot-checks` change, update this skill and `skills/makefile-control-plane.md`.
- If validation now checks different kernel files, GRUB config paths, EFI files, fstab entries, UUIDs, or NetworkManager enablement, update output artifacts, failure modes, and recovery advice here.
- If Ansible later automates bootloader work, update `skills/ansible-gentoo-installer.md` and the active OpenSpec `tasks.md` with the same safety gates.
- Before finishing, confirm documentation still requires UEFI mode, EFI mounted at `/boot/efi`, target root mounted at `/mnt/gentoo`, and no unspecified disk for `grub-install`.
