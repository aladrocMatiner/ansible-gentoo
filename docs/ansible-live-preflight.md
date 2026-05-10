# Ansible Live ISO Preflight

The live ISO Ansible preflight validates that the booted official Gentoo live ISO VM is reachable over SSH and can run read-only Ansible checks.

This workflow is not an installer. It does not partition, format, mount target filesystems, extract stage3, chroot, install packages, create users, change passwords, or install bootloaders.

## Required State

Start the libvirt VM and bootstrap temporary SSH access first:

```sh
make vm-start
make vm-bootstrap-ssh
```

The VM must be booted from the official Gentoo live ISO. The SSH bootstrap writes the operator public key into the temporary live ISO session only; it does not persist across reboot.

## Targets

Validate Ansible SSH connectivity:

```sh
make ansible-live-ping
```

Run the read-only preflight:

```sh
make ansible-live-preflight
```

Both targets discover the VM IP through libvirt when `VM_NET_MODE=network`. Pass `VM_IP=<address>` only when discovery is unavailable and the address is known.

After this preflight passes, continue with read-only disk detection and planning:

```sh
make ansible-check
make detect-disks
make install-plan PROFILE=openrc
make install-plan PROFILE=openrc INSTALL_DISK=/dev/vda
```

The install plan targets still do not install Gentoo. They use the official Gentoo AMD64 Handbook as the baseline procedure and stop at read-only planning.

## Checks Performed

`make ansible-live-preflight` reports:

- Gentoo release evidence from `/etc/gentoo-release`.
- Distribution facts gathered by Ansible.
- CPU architecture and kernel.
- UEFI availability from `/sys/firmware/efi`.
- DNS resolver configuration.
- Default route.
- Network addresses.
- Visible block devices from `lsblk`.
- Whether `/dev/vda` exists as the expected VM disk.

The workflow observes `/dev/vda` only. It must not select `install_disk`, write partition tables, create filesystems, or require `I_UNDERSTAND_THIS_WIPES_DISK`.

## Safety

The preflight role uses read-only Ansible fact gathering and inspection commands. Forbidden commands for this workflow include `parted`, `sgdisk`, `fdisk`, `wipefs`, `mkfs.*`, `mount`, `umount`, `chroot`, `passwd`, `useradd`, `usermod`, `grub-install`, and `efibootmgr`.

Ansible may create temporary connection files in the live ISO session. Those files are not installation state and are lost when the live ISO reboots.

## Failure Modes

- `make ansible-live-ping` fails because SSH was not bootstrapped: run `make vm-bootstrap-ssh` again and verify `make vm-ip`.
- VM IP discovery fails: verify the VM is running on the libvirt managed network with `make vm-ip`.
- Ansible cannot find roles: verify commands are run from the repository root so `ansible.cfg` is loaded.
- `/dev/vda` is missing: verify the VM was started through `make vm-start` and the qcow2 disk exists with `make vm-disk`.
- Gentoo release evidence is missing: verify the VM booted the official Gentoo live ISO configured by `VM_ISO`.

## Recovery

Use Makefile targets rather than raw commands:

```sh
make vm-ip
make vm-bootstrap-ssh
make ansible-live-ping
make ansible-live-preflight
```

If the live ISO session is wedged, stop and restart the project VM:

```sh
make vm-destroy
make vm-start
make vm-bootstrap-ssh
```

Do not run installer playbooks or disk commands to recover a failed preflight.
