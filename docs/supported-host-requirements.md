# Supported Host Requirements

Host requirements apply to the operator/controller machine used for development and local libvirt validation. They are separate from the official Gentoo live ISO target requirements and separate from the installed Gentoo target baseline.

## Required For Local libvirt Validation

`make host-check` verifies the host-side prerequisites used by `make vm-*` workflows:

- `make`,
- `virsh`,
- libvirt daemon access through `LIBVIRT_URI`,
- `qemu-system-x86_64`,
- `qemu-img`,
- `isoinfo`,
- `ssh`,
- `rsync`,
- `ansible`,
- OVMF/UEFI firmware,
- configured libvirt network when `VM_NET_MODE=network`,
- official Gentoo ISO at `VM_ISO`,
- safe project-local VM paths,
- enough host memory for `VM_RAM` plus overhead,
- enough free project filesystem space for `VM_DISK_SIZE`,
- CPU virtualization evidence where practical.

The check is read-only. It does not install host packages, create VM disks, define libvirt domains, start VMs, or modify host disks.

## Run

```sh
make host-check
```

Run it before local VM validation:

```sh
make host-check
make vm-disk
make vm-define
make vm-start
```

`make vm-check` remains the narrower VM workflow check. `make host-check` adds controller resource checks and then reuses the same libvirt/ISO/OVMF safety checks.

## Boundary

Host requirements do not apply to a remote target booted into the official Gentoo live ISO. For a real network target, use:

```sh
make ansible-live-preflight ANSIBLE_LIVE_HOST=<live-iso-address> ANSIBLE_LIVE_USER=root
```

Local live ISO fallback mode also does not require host libvirt tools, because it runs inside the already booted live ISO with `ansible_connection=local`.

## Failure Modes

- Missing `virsh`, `qemu-img`, `qemu-system-x86_64`, `isoinfo`, `ansible`, `ssh`, or `rsync`: install the missing host tool through the host OS package manager, then rerun `make host-check`.
- `LIBVIRT_URI` is inaccessible: verify libvirt is running and the operator has permission to access the configured URI.
- OVMF firmware missing: install host OVMF/edk2 firmware packages.
- `VM_ISO` missing: place the official Gentoo live ISO at the configured path or set `VM_ISO=...`.
- Not enough memory or disk: reduce `VM_RAM`/`VM_DISK_SIZE` for testing or free host resources.
- Existing domain safety failure: inspect the configured `VM_NAME`; project targets refuse unrelated or unsafe domains.

## Recovery

Fix host requirements before running `vm-*` targets. Do not work around failed host checks by running raw `virsh` or `qemu-system-x86_64` commands; add or adjust a Makefile target if the workflow needs to change.
