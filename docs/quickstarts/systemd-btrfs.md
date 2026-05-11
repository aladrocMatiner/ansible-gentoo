# Quick Start: amd64 systemd + Btrfs Libvirt VM

This quickstart runs the disposable local libvirt VM for the amd64 systemd + Btrfs install case. The reusable installer still runs over SSH into a booted official Gentoo live ISO; this VM is only the local validation harness.

## Case Identity

Use these selectors:

```sh
PROFILE=systemd
FILESYSTEM=btrfs
INSTALL_DISK=/dev/vda
```

The VM helper derives:

```text
case: amd64-systemd-btrfs
domain: gentoo-test-amd64-systemd-btrfs
disk: var/libvirt/gentoo-test-amd64-systemd-btrfs.qcow2
state: var/state/libvirt/gentoo-test-amd64-systemd-btrfs/current-install.json
```

`INSTALL_DISK=/dev/vda` is valid only inside this disposable VM. Btrfs plans must include the approved root subvolume mount option `subvol=@`.

For a manual test label, add `VM_TEST_IMAGE_NAME=<label>` to the commands. Example: `VM_TEST_IMAGE_NAME=handbook` derives `gentoo-test-handbook-amd64-systemd-btrfs`.

## Prerequisites

- Place the official Gentoo live ISO at `./gentoo.iso`, or as the only `.iso` file under `./gentoo.iso/`.
- Ensure libvirt, OVMF/UEFI firmware, `qemu-img`, Ansible, and Make are available.
- Ensure the libvirt `default` network is active, or set `VM_NETWORK=<network-name>`.
- Ensure your SSH public key exists at `~/.ssh/id_ed25519.pub`, `~/.ssh/id_rsa.pub`, or pass `VM_SSH_PUBLIC_KEY`.

```sh
make host-check
make vm-list-cases
make vm-check PROFILE=systemd FILESYSTEM=btrfs
```

## Create And Boot The VM

```sh
make vm-disk PROFILE=systemd FILESYSTEM=btrfs
make vm-define PROFILE=systemd FILESYSTEM=btrfs
make vm-start PROFILE=systemd FILESYSTEM=btrfs
```

Access the console, bootstrap SSH, and validate Ansible connectivity:

```sh
make vm-console PROFILE=systemd FILESYSTEM=btrfs
make vm-bootstrap-ssh PROFILE=systemd FILESYSTEM=btrfs
make vm-ansible-ping PROFILE=systemd FILESYSTEM=btrfs
```

## Run Read-Only Plans

```sh
make install-plan PROFILE=systemd FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
make partition-plan PROFILE=systemd FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
make mount-plan PROFILE=systemd FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
make filesystem-plan PROFILE=systemd FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
```

Review the Btrfs subvolume and fstab plan before running any destructive VM install.

## Run The Disposable VM Install

This wipes only the selected VM qcow2 disk and uses the systemd stage3/profile path.

```sh
make vm-e2e-install \
  PROFILE=systemd \
  FILESYSTEM=btrfs \
  INSTALL_DISK=/dev/vda \
  ADMIN_USER=<admin-user> \
  ENABLE_SSH=yes \
  ADMIN_AUTHORIZED_KEYS_FILE=<public-key-file> \
  I_UNDERSTAND_THIS_WIPES_DISK=yes \
  I_UNDERSTAND_BOOTLOADER_CHANGES=yes
```

For a fresh retry, reset only this generated case VM:

```sh
make vm-e2e-install \
  PROFILE=systemd \
  FILESYSTEM=btrfs \
  INSTALL_DISK=/dev/vda \
  ADMIN_USER=<admin-user> \
  ENABLE_SSH=yes \
  ADMIN_AUTHORIZED_KEYS_FILE=<public-key-file> \
  VM_E2E_RESET_DISK=yes \
  I_UNDERSTAND_CLEANUP_DELETE=DELETE \
  I_UNDERSTAND_THIS_WIPES_DISK=yes \
  I_UNDERSTAND_BOOTLOADER_CHANGES=yes
```

## Validate And Clean Up

```sh
make vm-validate-first-boot PROFILE=systemd FILESYSTEM=btrfs ADMIN_USER=<admin-user>
make vm-clean PROFILE=systemd FILESYSTEM=btrfs I_UNDERSTAND_CLEANUP_DELETE=DELETE
```

## Failure Modes

- Btrfs tools missing in the target: inspect package evidence from `install-system-packages`.
- Root subvolume missing: inspect mount and fstab logs for `subvol=@`.
- systemd service validation fails: inspect service evidence from `install-system-packages` and `final-checks`.
- Install fails mid-run: inspect `make install-state INSTALL_STATE_FILE=var/state/libvirt/gentoo-test-amd64-systemd-btrfs/current-install.json` and logs under `logs/install-runs/`.
