# Quick Start: amd64 systemd + ext4 + hardened Libvirt VM

Use:

```sh
PROFILE=systemd
FILESYSTEM=ext4
STAGE3_FLAVOR=hardened
INSTALL_DISK=/dev/vda
```

Generated identity:

```text
case: amd64-systemd-ext4-hardened
domain: gentoo-test-amd64-systemd-ext4-hardened
disk: var/libvirt/gentoo-test-amd64-systemd-ext4-hardened.qcow2
state: var/state/libvirt/gentoo-test-amd64-systemd-ext4-hardened/current-install.json
```

Run the case:

```sh
make host-check
make vm-list-cases
make vm-check PROFILE=systemd FILESYSTEM=ext4 STAGE3_FLAVOR=hardened
make vm-e2e-install PROFILE=systemd FILESYSTEM=ext4 STAGE3_FLAVOR=hardened INSTALL_DISK=/dev/vda ADMIN_USER=<admin-user> ENABLE_SSH=yes ADMIN_AUTHORIZED_KEYS_FILE=<public-key-file> VM_E2E_RESET_DISK=yes I_UNDERSTAND_CLEANUP_DELETE=DELETE I_UNDERSTAND_THIS_WIPES_DISK=yes I_UNDERSTAND_BOOTLOADER_CHANGES=yes
```

Clean only this generated case:

```sh
make vm-clean PROFILE=systemd FILESYSTEM=ext4 STAGE3_FLAVOR=hardened I_UNDERSTAND_CLEANUP_DELETE=DELETE
```
