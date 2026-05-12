# Quick Start: amd64 systemd + Btrfs + musl Libvirt VM

Use:

```sh
PROFILE=systemd
FILESYSTEM=btrfs
STAGE3_FLAVOR=musl
INSTALL_DISK=/dev/vda
```

Generated identity:

```text
case: amd64-systemd-btrfs-musl
domain: gentoo-test-amd64-systemd-btrfs-musl
disk: var/libvirt/gentoo-test-amd64-systemd-btrfs-musl.qcow2
state: var/state/libvirt/gentoo-test-amd64-systemd-btrfs-musl/current-install.json
```

Run the case:

```sh
make host-check
make vm-list-cases
make vm-check PROFILE=systemd FILESYSTEM=btrfs STAGE3_FLAVOR=musl
make vm-e2e-install PROFILE=systemd FILESYSTEM=btrfs STAGE3_FLAVOR=musl INSTALL_DISK=/dev/vda ADMIN_USER=<admin-user> ENABLE_SSH=yes ADMIN_AUTHORIZED_KEYS_FILE=<public-key-file> VM_E2E_RESET_DISK=yes I_UNDERSTAND_CLEANUP_DELETE=DELETE I_UNDERSTAND_THIS_WIPES_DISK=yes I_UNDERSTAND_BOOTLOADER_CHANGES=yes
```

Clean only this generated case:

```sh
make vm-clean PROFILE=systemd FILESYSTEM=btrfs STAGE3_FLAVOR=musl I_UNDERSTAND_CLEANUP_DELETE=DELETE
```
