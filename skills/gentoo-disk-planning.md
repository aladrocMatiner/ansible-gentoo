# Gentoo Disk Planning Skill

## 1. Purpose
This skill describes safe disk detection and partition planning for the `gentoo-ai-installer` project.

The first installer planning version targets UEFI, GRUB, no LUKS, and two filesystem plan variants: ext4 root or Btrfs root with subvolumes. Disk operations are dangerous and require explicit human confirmation. The Makefile is the operator-facing control plane.

This skill plans disk work; it must not perform destructive operations by itself.

## 2. When to Use This Skill
Use this skill:

- Before selecting an installation disk.
- Before partitioning.
- Before formatting.
- Before mounting target filesystems.
- Before bootloader planning.
- When reviewing Ansible disk automation later.
- When reviewing read-only Ansible disk detection or install-plan output.

Do not use this skill to support LUKS, BIOS boot, or advanced layouts in v1. Those require future OpenSpec changes. Btrfs is currently allowed only as a read-only planned layout until destructive filesystem work is approved.

## 3. Required Context
- Official Gentoo live ISO preflight result.
- UEFI status.
- Output from `make detect-disks`.
- Operator-provided `INSTALL_DISK`.
- Expected `FILESYSTEM=ext4` or `FILESYSTEM=btrfs`.
- Expected `BOOT_MODE=uefi`.
- Whether swap is explicitly configured.
- Confirmation policy using `I_UNDERSTAND_THIS_WIPES_DISK`.

Expected variables:

- `INSTALL_DISK`
- `FILESYSTEM=ext4` or `FILESYSTEM=btrfs`
- `BOOT_MODE=uefi`
- `I_UNDERSTAND_THIS_WIPES_DISK`

`INSTALL_DISK` must not have a default value.

## 4. Disk Discovery Procedure
Ask the operator to run:

```text
make detect-disks
```

Disk discovery must display:

- Disk path.
- Disk model.
- Disk serial.
- Disk size.
- Current partition table.
- Current filesystems.
- Current mountpoints.
- Stable `/dev/disk/by-id/...` path when available.

Disk discovery must be read-only. It must not select a target disk automatically. The operator must provide `INSTALL_DISK` explicitly after reviewing the inventory.

## 5. UEFI Verification
Before partition planning:

- Confirm `BOOT_MODE=uefi`.
- Confirm `/sys/firmware/efi` exists.
- Confirm the live ISO was booted in UEFI mode.
- Plan an EFI system partition mounted at `/boot/efi`.

If UEFI is not available, stop. The v1 layout does not support BIOS boot.

## 6. Recommended v1 Partition Layout
For v1, recommend:

- EFI system partition: 512 MiB, FAT32, mounted at `/boot/efi`.
- Root partition: remaining disk, ext4 or Btrfs, mounted at `/mnt/gentoo`.
- If `FILESYSTEM=btrfs`, plan subvolumes for `@`, `@home`, `@var`, `@var/log`, `@var/cache`, and `@snapshots`.
- No separate `/home` in v1.
- No swap partition in v1 unless explicitly configured.
- Optional swapfile after installation.

The partition plan must identify:

- Selected `INSTALL_DISK`.
- Partition numbers or paths that will be created.
- Filesystem for each partition.
- Mountpoint for each partition.
- Existing data that will be destroyed.

## 7. Safety Checks Before Partitioning
Before any partitioning target runs:

- `INSTALL_DISK` must be explicitly provided.
- `INSTALL_DISK` must not be empty.
- `INSTALL_DISK` must not be a wildcard.
- `INSTALL_DISK` must not come from a default value.
- Disk path, model, serial, size, current partition table, current filesystems, and current mountpoints must be displayed.
- Any mounted partition on the selected disk must be shown.
- The proposed partition plan must be displayed.
- The operator must confirm `I_UNDERSTAND_THIS_WIPES_DISK=yes`.
- A safety confirmation script must run when implemented.
- Stop if disk identity changes between `partition-plan` and `partition`.
- Stop if the selected disk cannot be uniquely identified.

Explicitly forbidden:

- Defaulting to `/dev/sda`.
- Defaulting to `/dev/nvme0n1`.
- Wildcard disk matching.
- Partitioning without explicit `INSTALL_DISK`.
- Destructive operations without confirmation.

## 8. Safety Checks Before Formatting
Before formatting:

- The partitions must come from the approved partition plan.
- Current filesystems must be displayed.
- Current mountpoints must be displayed.
- No target partition may be mounted.
- `FILESYSTEM=ext4` or `FILESYSTEM=btrfs` must be confirmed for the root partition.
- If `FILESYSTEM=btrfs`, planned subvolumes and mount options must be displayed before any future formatting or subvolume creation. The root mount options must include `subvol=@`.
- EFI partition formatting must match UEFI requirements.
- `I_UNDERSTAND_THIS_WIPES_DISK=yes` must be present.
- The operator must confirm the exact partition paths to be formatted.

Explicitly forbidden:

- Formatting mounted filesystems.
- Formatting a whole disk when a partition is expected.
- Formatting partitions from a disk other than `INSTALL_DISK`.
- Formatting without confirmation.

## 9. Required Confirmations
Partitioning and formatting are destructive.

Required confirmation variables:

- `INSTALL_DISK=<operator-selected-disk>`
- `I_UNDERSTAND_THIS_WIPES_DISK=yes`

Required confirmation text should identify:

- Selected disk.
- Disk model.
- Disk serial.
- Disk size.
- Existing partition table.
- Existing filesystems.
- Existing mountpoints.
- Proposed new layout.

The operator must understand that existing data on the selected disk or partitions may be destroyed.

## 10. Makefile Targets
Expected targets:

These targets define the expected control-plane contract for disk planning. If a target is not present in the current `Makefile`, treat it as planned and do not document it as runnable in user-facing docs.

- `make detect-disks`
- `make install-plan PROFILE=openrc`
- `make install-plan PROFILE=systemd`
- `make install-plan PROFILE=openrc INSTALL_DISK=/dev/vda`
- `make partition-plan INSTALL_DISK=...`
- `make partition INSTALL_DISK=... I_UNDERSTAND_THIS_WIPES_DISK=yes`
- `make format INSTALL_DISK=... I_UNDERSTAND_THIS_WIPES_DISK=yes`

Target expectations:

- `make detect-disks`: read-only disk inventory without selecting an install disk.
- `make install-plan PROFILE=openrc`: read-only OpenRC plan; reports no selected disk unless `INSTALL_DISK` is explicitly provided.
- `make install-plan PROFILE=systemd`: read-only systemd plan; reports no selected disk unless `INSTALL_DISK` is explicitly provided.
- `make install-plan PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda`: VM-only example that reports the Btrfs subvolume plan for the explicitly provided guest disk.
- `make install-plan PROFILE=openrc INSTALL_DISK=/dev/vda`: VM-only example that matches the explicitly provided guest disk for read-only planning.
- `make partition-plan INSTALL_DISK=...`: show proposed v1 layout and current disk state without writing.
- `make partition INSTALL_DISK=... I_UNDERSTAND_THIS_WIPES_DISK=yes`: partition only after safety checks and confirmation.
- `make format INSTALL_DISK=... I_UNDERSTAND_THIS_WIPES_DISK=yes`: format only approved partitions after mount checks and confirmation.

The operator should not be asked to run raw `parted`, `sgdisk`, `fdisk`, `wipefs`, or `mkfs.*` commands when Makefile targets exist.

## 11. Failure Modes
- `INSTALL_DISK` is missing.
- `INSTALL_DISK` has an unsafe default.
- Disk identity changes between plan and apply.
- Disk serial is unavailable and identity is ambiguous.
- A selected partition is mounted.
- The machine is booted in BIOS mode.
- The operator expects LUKS, BIOS boot, separate partitioned `/home`, or swap partition behavior not supported in v1.
- The partition plan would affect the wrong disk.
- Wildcard disk matching selects multiple devices.
- Formatting targets include mounted filesystems.

## 12. Recovery Advice
- Re-run `make detect-disks` before destructive work.
- Use `make install-plan PROFILE=... INSTALL_DISK=...` to confirm read-only disk identity before any future destructive plan.
- Re-run `make partition-plan INSTALL_DISK=...` if disk state changes.
- Stop if disk identity is ambiguous.
- Reboot in UEFI mode if `/sys/firmware/efi` is missing.
- Unmount only after reviewing current mountpoints and using documented targets.
- Do not retry partitioning with a different disk until a new plan is approved.
- If formatting was attempted on the wrong partition, stop immediately and collect evidence before further writes.
- For LUKS, BIOS, swap partition, or separate `/home`, create a future OpenSpec change instead of modifying v1 behavior ad hoc. For Btrfs, stay within the documented subvolume plan until destructive Btrfs implementation is approved.

## 13. Output Artifacts
This skill should produce or request:

- Disk inventory from `make detect-disks`.
- Read-only install-plan output from `make install-plan PROFILE=...`.
- UEFI verification result.
- Operator-provided `INSTALL_DISK`.
- v1 partition plan.
- Disk summary with path, model, serial, size, current partition table, current filesystems, and current mountpoints.
- List of data that will be destroyed.
- Required confirmation variables.
- Safety review notes for destructive targets.
- Go/no-go decision for partitioning and formatting.

## Documentation maintenance
When disk detection, partition planning, or destructive disk behavior changes, documentation must change in the same implementation step.

- If the v1 layout changes, update this skill, manual install documentation under `docs/`, `agents/gentoo-install-agent.md`, and the active OpenSpec `tasks.md`.
- If disk discovery output changes, update the required displayed fields here: disk path, model, serial, size, current partition table, current filesystems, and current mountpoints.
- If read-only install-plan output changes, update `docs/ansible-install-plan.md` and this skill so `PROFILE`, optional `INSTALL_DISK`, v1 layout, and Handbook baseline remain accurate.
- If confirmations, safety gates, or destructive target names change, update `skills/makefile-control-plane.md`, `agents/safety-review-agent.md`, and relevant `README.md` or `docs/` instructions.
- If implementation changes partitioning or formatting behavior, update safety documentation before marking the OpenSpec task complete.
- If Makefile targets such as `make detect-disks`, `make partition-plan`, `make partition`, or `make format` change, update the target examples and required variables here.
- Before finishing, confirm the documentation still forbids default disks, wildcard disk matching, formatting mounted filesystems, and destructive operations without explicit `INSTALL_DISK` and `I_UNDERSTAND_THIS_WIPES_DISK=yes`.
