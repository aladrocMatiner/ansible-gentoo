# Quick Start: amd64 systemd + Btrfs + hardened Libvirt VM

Use:

```sh
PROFILE=systemd
FILESYSTEM=btrfs
STAGE3_FLAVOR=hardened
INSTALL_DISK=/dev/vda
```

Generated identity:

```text
case: amd64-systemd-btrfs-hardened
domain: gentoo-test-amd64-systemd-btrfs-hardened
disk: var/libvirt/gentoo-test-amd64-systemd-btrfs-hardened.qcow2
state: var/state/libvirt/gentoo-test-amd64-systemd-btrfs-hardened/current-install.json
```

Run the case:

```sh
make host-check
make vm-list-cases
make vm-check PROFILE=systemd FILESYSTEM=btrfs STAGE3_FLAVOR=hardened
make vm-e2e-install PROFILE=systemd FILESYSTEM=btrfs STAGE3_FLAVOR=hardened INSTALL_DISK=/dev/vda ADMIN_USER=<admin-user> ENABLE_SSH=yes ADMIN_AUTHORIZED_KEYS_FILE=<public-key-file> VM_E2E_RESET_DISK=yes I_UNDERSTAND_CLEANUP_DELETE=DELETE I_UNDERSTAND_THIS_WIPES_DISK=yes I_UNDERSTAND_BOOTLOADER_CHANGES=yes
```

Clean only this generated case:

```sh
make vm-clean PROFILE=systemd FILESYSTEM=btrfs STAGE3_FLAVOR=hardened I_UNDERSTAND_CLEANUP_DELETE=DELETE
```
