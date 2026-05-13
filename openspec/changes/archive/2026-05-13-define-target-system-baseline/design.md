# Design: define-target-system-baseline

## Shared Baseline

The v1 basic console system should include:

- amd64,
- UEFI,
- GRUB,
- `gentoo-kernel-bin`,
- root filesystem `ext4` or approved Btrfs layout,
- NetworkManager,
- hostname,
- timezone,
- locale,
- keymap where relevant,
- admin user when configured,
- privilege escalation through sudo or doas,
- editor (`vim` or `nano`),
- logging,
- cron or timer-equivalent where appropriate,
- optional SSH.
- installed time synchronization according to the installed time-sync policy.

## OpenRC Baseline

OpenRC-specific baseline:

- OpenRC stage3 and profile,
- OpenRC service enablement through `rc-update`,
- OpenRC-compatible syslog and cron choices,
- OpenRC validation.

## systemd Baseline

systemd-specific baseline:

- systemd stage3 and profile,
- service enablement through `systemctl`,
- journald assumptions,
- systemd validation.

## Non-goals

The baseline does not include:

- desktop environment,
- LUKS,
- Secure Boot,
- custom kernel build,
- custom ISO,
- remote fleet orchestration,
- automatic snapshot management.

SSH is optional and must follow the installed SSH policy when enabled.

## Documentation

Final checks and install report must use this baseline to decide whether the system is complete.
