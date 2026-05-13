# Design: implement-ansible-system-packages-and-services

## Shared Package Framework
Use one shared package installation role with package lists from common and variant variables.

The role must follow the Gentoo AMD64 Handbook system tools phase while preserving project decisions:

- vfat/FAT32 support requires `sys-fs/dosfstools`.
- Btrfs support requires `sys-fs/btrfs-progs`.
- ext4 support uses `sys-fs/e2fsprogs`, which is commonly present as part of the system set, but the role should verify it or include it explicitly if needed.
- NetworkManager is the project v1 network manager, even though the Handbook's basic networking example often uses `dhcpcd`.

## OpenRC
Enable services through `rc-update`. Use OpenRC-compatible syslog and cron packages.

## systemd
Enable services through `systemctl`. Rely on journald where appropriate.

## Network
NetworkManager is the v1 network manager unless a later approved change changes policy.

OpenRC must enable NetworkManager through OpenRC service management. systemd must enable the NetworkManager systemd service.
