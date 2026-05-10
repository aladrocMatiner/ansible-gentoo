# Change: implement-ansible-final-checks-and-reboot-readiness

## Summary
Implement final read-only checks before rebooting into the installed Gentoo system.

## Motivation
Before reboot, the installer must verify target system completeness and detect obvious boot failures.

## Scope
- Add shared `common/final_checks` role.
- Verify fstab, kernel, initramfs, GRUB, EFI files, NetworkManager, users, hostname, and logs.
- Verify no secrets were written to project files.
- Produce reboot readiness report.
- Produce or reference the install audit bundle.
- Verify Btrfs root uses `subvol=@` when `FILESYSTEM=btrfs`.
- Evaluate the target system baseline, including locale/timezone/hostname.
- Validate time-sync, SSH when enabled, Portage config-update status, and boot kernel command line policy.
- Feed the human-readable install report summary.

## Non-goals
- Do not reboot automatically.
- Do not install missing components in final checks.

## Safety Requirements
- Final checks are read-only.
- Fail closed if required boot artifacts are missing.

## Acceptance Criteria
- Final checks report PASS/FAIL readiness.
- Missing kernel, fstab, bootloader, or network enablement fails.
- Final checks include audit bundle path or generation status.
- Btrfs final checks validate approved subvolume mount options.
- Final checks report baseline coverage and install report inputs.
- Final checks report time sync, SSH, Portage update/config status, and boot command line status.
- `openspec validate implement-ansible-final-checks-and-reboot-readiness --strict` passes.

## Affected Files
- `ansible/roles/common/final_checks/`
- `docs/`
- `skills/`
