# Change: implement-ansible-system-packages-and-services

## Summary
Install and enable the minimal system packages and services needed for a bootable console Gentoo system.

## Motivation
The target system needs networking, privilege escalation, editor, logging, cron, filesystem utilities, and optional SSH support. Service enablement differs between OpenRC and systemd and must be isolated.

This change maps to the Gentoo AMD64 Handbook "Installing system tools" and "Networking tools" sections. The project deliberately uses NetworkManager as the v1 network manager instead of the Handbook's basic `dhcpcd` example, and that decision must be documented as a project policy.

## Scope
- Add shared `common/package_install`.
- Add shared `common/ssh` where appropriate.
- Add init-specific service enablement.
- Install NetworkManager, sudo or doas, editor, syslog/cron for OpenRC, filesystem utilities, and SSH if enabled.
- Follow the target system baseline for required and optional packages/services.
- Follow installed time-sync and installed SSH policies.
- Keep time-sync package and service names as variant data: OpenRC uses `net-misc/chrony`/`chronyd`; systemd uses `systemd-timesyncd.service`.
- Keep SSH package and service names as variant data: OpenRC uses `net-misc/openssh`/`sshd`; systemd uses `net-misc/openssh`/`sshd.service`.
- Do not run a broad `@world` update as part of package installation unless a later approved policy adds it.
- Install `sys-fs/dosfstools` because the UEFI ESP is FAT32/vfat.
- Install `sys-fs/btrfs-progs` when `FILESYSTEM=btrfs`.
- Ensure `sys-fs/e2fsprogs` is present or already provided by the base system for ext4 workflows.

## Non-goals
- Do not create users.
- Do not install bootloader.
- Do not configure graphical desktop.

## Safety Requirements
- OpenRC flows must not call `systemctl`.
- systemd flows must not call `rc-update` or `rc-service`.
- Package lists must be variables, not duplicated task bodies.

## Acceptance Criteria
- NetworkManager is installed and enabled for selected init system.
- FAT32/vfat tooling is installed for the EFI system partition.
- Btrfs tooling is installed when `FILESYSTEM=btrfs`.
- Required console packages are installed.
- Service enablement uses init-specific isolated tasks.
- Package/service status contributes to final baseline checks and install report.
- Time-sync and SSH service status are reported when applicable.
- `openspec validate implement-ansible-system-packages-and-services --strict` passes.

## Affected Files
- `ansible/roles/common/package_install/`
- `ansible/roles/common/ssh/`
- `ansible/roles/init/openrc/`
- `ansible/roles/init/systemd/`
- `docs/`
- `skills/`
