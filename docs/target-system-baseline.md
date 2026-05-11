# Target System Baseline

The v1 target is a basic console Gentoo installation produced from the official Gentoo live ISO through Makefile-mediated Ansible workflows. The official Gentoo AMD64 Handbook remains the baseline procedure; this document defines the project-specific completion contract.

## Shared Baseline

Every supported v1 install must provide:

- amd64 architecture,
- UEFI boot,
- GRUB bootloader,
- `gentoo-kernel-bin`,
- ext4 root or the approved Btrfs subvolume layout,
- UUID-based `/etc/fstab`,
- NetworkManager,
- hostname,
- timezone,
- locale,
- console keymap where relevant,
- conservative Portage `make.conf`,
- official Gentoo repository configuration,
- GURU disabled in the installed system unless a later approved change requires it,
- privilege escalation through `sudo` or `doas`,
- an explicit admin user when user configuration is run,
- a console editor,
- logging service or journald equivalent,
- cron service or systemd timer equivalent,
- installed time synchronization according to `docs/installed-time-sync-policy.md`,
- optional installed SSH only when `ENABLE_SSH=yes`.

## OpenRC Baseline

For `PROFILE=openrc`, the installed target must use:

- OpenRC stage3 variant,
- OpenRC profile,
- service enablement through `rc-update`,
- NetworkManager service enabled through OpenRC,
- OpenRC-compatible syslog package and service,
- OpenRC-compatible cron package and service,
- OpenRC time-sync service according to the installed time-sync policy,
- optional OpenSSH service enabled through OpenRC when `ENABLE_SSH=yes`.

OpenRC workflows must not call `systemctl`.

## systemd Baseline

For `PROFILE=systemd`, the installed target must use:

- systemd stage3 variant,
- systemd profile,
- service enablement through `systemctl`,
- NetworkManager service enabled through systemd,
- journald as the default logging baseline,
- systemd timer/service assumptions instead of OpenRC cron/syslog packages,
- systemd time-sync service according to the installed time-sync policy,
- optional OpenSSH service enabled through systemd when `ENABLE_SSH=yes`.

systemd workflows must not call `rc-update` or `rc-service`.

## Out Of Scope

The v1 baseline does not include:

- desktop environment,
- LUKS,
- Secure Boot,
- custom kernel build,
- custom ISO,
- automatic snapshot management,
- remote fleet orchestration,
- unattended real-hardware reboot,
- arbitrary package customization beyond approved variables.

## Validation

Final checks and first-boot validation must evaluate the baseline where practical:

- target identity: hostname, timezone, locale, keymap,
- boot readiness: UEFI, kernel, initramfs, GRUB, root UUID, EFI files,
- filesystem policy: ext4 or approved Btrfs layout,
- service policy: NetworkManager, time sync, logging/cron or systemd equivalents, optional SSH,
- access policy: admin user, groups, shell, privilege escalation,
- Portage policy: selected profile, conservative flags, repo sync, pending config updates,
- secret safety: no plaintext credentials or private keys in state, logs, or reports.

Missing baseline evidence must be reported as unavailable or failed; reports must not invent state.

## Documentation Maintenance

When packages, services, users, final checks, install reports, or profile behavior change, update this document, the relevant workflow docs, and the active OpenSpec tasks in the same change.
