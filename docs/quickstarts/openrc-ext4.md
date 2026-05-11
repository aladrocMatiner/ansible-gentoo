# Quick Start: amd64 OpenRC + ext4 Libvirt VM

This quickstart runs the disposable local libvirt VM for the amd64 OpenRC + ext4 install case. The reusable installer still runs over SSH into a booted official Gentoo live ISO; this VM is only the local validation harness.

## Case Identity

Use these selectors:

```sh
PROFILE=openrc
FILESYSTEM=ext4
INSTALL_DISK=/dev/vda
```

The VM helper derives:

```text
case: amd64-openrc-ext4
domain: gentoo-test-amd64-openrc-ext4
disk: var/libvirt/gentoo-test-amd64-openrc-ext4.qcow2
state: var/state/libvirt/gentoo-test-amd64-openrc-ext4/current-install.json
```

`INSTALL_DISK=/dev/vda` is valid only inside this disposable VM.

For a manual test label, add `VM_TEST_IMAGE_NAME=<label>` to the commands. Example: `VM_TEST_IMAGE_NAME=handbook` derives `gentoo-test-handbook-amd64-openrc-ext4`.

## Prerequisites

- Place the official Gentoo live ISO at `./gentoo.iso`, or as the only `.iso` file under `./gentoo.iso/`.
- Ensure libvirt, OVMF/UEFI firmware, `qemu-img`, Ansible, and Make are available.
- Ensure the libvirt `default` network is active, or set `VM_NETWORK=<network-name>`.
- Ensure your SSH public key exists at `~/.ssh/id_ed25519.pub`, `~/.ssh/id_rsa.pub`, or pass `VM_SSH_PUBLIC_KEY`.

```sh
make host-check
make vm-list-cases
make vm-check PROFILE=openrc FILESYSTEM=ext4
```

## Create And Boot The VM

```sh
make vm-disk PROFILE=openrc FILESYSTEM=ext4
make vm-define PROFILE=openrc FILESYSTEM=ext4
make vm-start PROFILE=openrc FILESYSTEM=ext4
```

Access the console, bootstrap SSH, and validate Ansible connectivity:

```sh
make vm-console PROFILE=openrc FILESYSTEM=ext4
make vm-bootstrap-ssh PROFILE=openrc FILESYSTEM=ext4
make vm-ansible-ping PROFILE=openrc FILESYSTEM=ext4
```

## Run Read-Only Plans

```sh
make install-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda
make partition-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda
make mount-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda
make filesystem-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda
```

Review the output before running any destructive VM install.

## Run The Disposable VM Install

This wipes only the selected VM qcow2 disk.

```sh
make vm-e2e-install \
  PROFILE=openrc \
  FILESYSTEM=ext4 \
  INSTALL_DISK=/dev/vda \
  ADMIN_USER=<admin-user> \
  ENABLE_SSH=yes \
  ADMIN_AUTHORIZED_KEYS_FILE=<public-key-file> \
  I_UNDERSTAND_THIS_WIPES_DISK=yes \
  I_UNDERSTAND_BOOTLOADER_CHANGES=yes
```

Disposable E2E installs default to passwordless sudo for the test admin through `VM_E2E_ADMIN_SUDO_NOPASSWD=yes`. After first boot, `ssh <admin-user>@<vm-ip>` followed by `sudo su -` should work without a password. Override with `ADMIN_SUDO_NOPASSWD=no` if this case should validate password-requiring sudo.

For a fresh retry, reset only this generated case VM:

```sh
make vm-e2e-install \
  PROFILE=openrc \
  FILESYSTEM=ext4 \
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
make vm-validate-first-boot PROFILE=openrc FILESYSTEM=ext4 ADMIN_USER=<admin-user>
make vm-clean PROFILE=openrc FILESYSTEM=ext4 I_UNDERSTAND_CLEANUP_DELETE=DELETE
```

## Failure Modes

- SSH bootstrap fails: open `make vm-console PROFILE=openrc FILESYSTEM=ext4`.
- Plan targets cannot find the VM: verify `make vm-ip PROFILE=openrc FILESYSTEM=ext4`.
- Install fails mid-run: inspect `make install-state INSTALL_STATE_FILE=var/state/libvirt/gentoo-test-amd64-openrc-ext4/current-install.json` and logs under `logs/install-runs/`.
