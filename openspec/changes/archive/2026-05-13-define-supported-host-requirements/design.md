# Design: define-supported-host-requirements

## Required Host Capabilities

For libvirt validation, the host should provide:

- `virsh`,
- libvirt daemon access,
- `qemu-system-x86_64`,
- `qemu-img`,
- OVMF/UEFI firmware,
- default or configured libvirt network,
- CPU virtualization support where practical,
- enough disk space for qcow2 images,
- enough memory for VM defaults,
- `make`,
- Ansible for host-driven validation workflows,
- official Gentoo ISO available at the documented path.

## Host Check

Planned target:

```sh
make host-check
```

The check must be read-only. It may report missing tools or permissions but must not install packages automatically unless a later approved change adds a guarded setup workflow.

## Boundary

Host requirements are not target Gentoo requirements. Docs must distinguish host validation, live ISO validation, and installed target validation.
