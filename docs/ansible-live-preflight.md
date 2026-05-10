# Ansible Live ISO Preflight

The live ISO Ansible preflight validates that a booted official Gentoo live ISO target is reachable over SSH and can run read-only Ansible checks.

This is the first network Ansible checkpoint. The target can be real hardware, a remote VM, or the project local libvirt VM. The reusable installer must remain inventory-driven and must not depend on libvirt.

This workflow is not an installer. It does not partition, format, mount target filesystems, extract stage3, chroot, install packages, create users, change passwords, or install bootloaders.

## Required State

For a network target, boot the official Gentoo live ISO, enable SSH according to the live ISO procedure, and provide the target explicitly:

```sh
make ansible-live-ping ANSIBLE_LIVE_HOST=192.0.2.10 ANSIBLE_LIVE_USER=root
make ansible-live-preflight ANSIBLE_LIVE_HOST=192.0.2.10 ANSIBLE_LIVE_USER=root
```

For the local validation harness, start the libvirt VM and bootstrap temporary SSH access first:

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

Both targets use `ANSIBLE_LIVE_HOST` when it is provided. When it is empty, they discover the local VM IP through libvirt when `VM_NET_MODE=network`. Pass `VM_IP=<address>` only for the local VM when discovery is unavailable and the address is known.

The live ISO SSH wrappers use temporary host-key relaxation because the official live ISO regenerates SSH host keys across boots. That exception is scoped to these wrapper invocations; `ansible.cfg` must not disable host-key checking globally.

After this preflight passes, continue with read-only disk detection and planning:

```sh
make ansible-check
make detect-disks ANSIBLE_LIVE_HOST=192.0.2.10
make install-plan PROFILE=openrc ANSIBLE_LIVE_HOST=192.0.2.10
make install-plan PROFILE=openrc ANSIBLE_LIVE_HOST=192.0.2.10 INSTALL_DISK=/dev/<target-disk>
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
- Visible disks for later explicit operator selection.

The workflow observes block devices only. It must not select `install_disk`, write partition tables, create filesystems, or require `I_UNDERSTAND_THIS_WIPES_DISK`. In the local libvirt VM, `/dev/vda` is expected, but it is still only an example until passed explicitly.

UEFI evidence is mandatory. If `/sys/firmware/efi` is missing, the preflight fails because v1 installation planning assumes UEFI and GRUB-on-UEFI.

## Safety

The preflight role uses read-only Ansible fact gathering and inspection commands. Forbidden commands for this workflow include `parted`, `sgdisk`, `fdisk`, `wipefs`, `mkfs.*`, `mount`, `umount`, `chroot`, `passwd`, `useradd`, `usermod`, `grub-install`, and `efibootmgr`.

Ansible may create temporary connection files in the live ISO session. Those files are not installation state and are lost when the live ISO reboots.

## Failure Modes

- `make ansible-live-ping ANSIBLE_LIVE_HOST=...` fails: verify the live ISO has SSH enabled, the address is reachable, and the selected port is correct.
- Local VM discovery fails: verify the VM is running on the libvirt managed network with `make vm-ip`.
- Ansible cannot find roles: verify commands are run from the repository root so `ansible.cfg` is loaded.
- `/dev/vda` is missing in the local VM summary: verify the VM was started through `make vm-start` and the qcow2 disk exists with `make vm-disk` before using VM disk examples.
- `/sys/firmware/efi` is missing: the live ISO target was not booted in UEFI mode. For the local VM, stop it with `make vm-destroy`, regenerate it with `make vm-define`, then restart and bootstrap SSH.
- Gentoo release evidence is missing: verify the VM booted the official Gentoo live ISO configured by `VM_ISO`.

## Recovery

Use Makefile targets rather than raw commands:

```sh
make vm-ip
make vm-bootstrap-ssh
make ansible-live-ping
make ansible-live-preflight
```

For a network target, rerun the targets with the explicit address:

```sh
make ansible-live-ping ANSIBLE_LIVE_HOST=192.0.2.10
make ansible-live-preflight ANSIBLE_LIVE_HOST=192.0.2.10
```

If the live ISO session is wedged, stop and restart the project VM:

```sh
make vm-destroy
make vm-start
make vm-bootstrap-ssh
```

Do not run installer playbooks or disk commands to recover a failed preflight.
