# Local Live ISO Ansible Fallback

The primary installer workflow runs Ansible from an operator/controller machine over SSH into a network-reachable official Gentoo live ISO target. Local live ISO mode is an optional fallback for diagnostics when the repository has been copied into the booted live ISO and Ansible runs on that same system with `ansible_connection=local`.

This mode is not the preferred production workflow and it is not a custom ISO. It reuses the same read-only playbooks as the SSH workflow.

## When To Use It

Use local mode only when:

- the target is already booted into the official Gentoo live ISO,
- the project repository is available and writable inside that live ISO session,
- Ansible is installed in that live ISO session,
- SSH from an external controller is unavailable or not useful for diagnostics.

Use the normal network workflow for reusable installs:

```sh
make ansible-live-preflight ANSIBLE_LIVE_HOST=<live-iso-address> ANSIBLE_LIVE_USER=root
make detect-disks ANSIBLE_LIVE_HOST=<live-iso-address>
make install-plan ANSIBLE_LIVE_HOST=<live-iso-address>
```

## Local Targets

Run these from inside the official Gentoo live ISO:

```sh
make local-live-preflight
make local-detect-disks
make local-install-plan PROFILE=openrc FILESYSTEM=ext4
make local-install-plan PROFILE=systemd FILESYSTEM=btrfs
make local-partition-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/<target-disk>
```

`local-partition-plan` is read-only but still requires `INSTALL_DISK` because it describes a concrete future disk layout. `INSTALL_DISK` has no default in local mode.

## What Local Mode Checks

The local preflight reuses `ansible/playbooks/live-preflight.yml` and verifies:

- amd64 architecture,
- official Gentoo live environment evidence,
- UEFI firmware evidence,
- root execution inside the live ISO,
- network addresses,
- default route,
- DNS resolution for `distfiles.gentoo.org`,
- plausible UTC clock,
- visible block devices.

## Safety

Local mode must not weaken installer safety:

- It must not infer a disk.
- It must not use `/dev/vda` unless the operator explicitly passes it as `INSTALL_DISK` in a VM guest.
- It must not set `I_UNDERSTAND_THIS_WIPES_DISK`.
- It must not partition, format, mount, chroot, create users, change passwords, install bootloaders, or alter EFI boot entries.
- It must not disable Ansible host-key checking globally.

The local targets in this document are read-only planning and inspection targets.

## Host Versus Local Requirements

Host-side libvirt validation requires host tools such as `virsh`, `qemu-img`, OVMF firmware, and access to the configured libvirt URI. Local live ISO mode does not require libvirt because it runs inside the already booted live ISO.

Local mode requires the live ISO session itself to provide:

- `bash`,
- `make`,
- `ansible-playbook`,
- `/usr/bin/python3` for the local Ansible interpreter,
- root shell privileges,
- network, DNS, and correct time for later download steps,
- write access to the project directory for Ansible temporary files and state logs.

## Failure Modes

- `ansible-playbook` is missing: install Ansible through a documented Makefile/scripted bootstrap path before using local mode.
- UEFI evidence is missing: reboot the live ISO in UEFI mode.
- DNS or default route is missing: configure live ISO networking before running installer plans.
- `INSTALL_DISK` is missing for `local-partition-plan`: rerun with the exact disk path reported by `make local-detect-disks`.
- Local mode is run on an installed system instead of the live ISO: stop and boot the official Gentoo live ISO before continuing.

## Recovery

Prefer the network workflow when possible. If local mode fails because the live ISO environment is incomplete, return to controller-driven targets:

```sh
make ansible-live-preflight ANSIBLE_LIVE_HOST=<live-iso-address> ANSIBLE_LIVE_USER=root
```

If the live ISO session is temporary or inconsistent, reboot the official live ISO and rerun local preflight before any planning target.
