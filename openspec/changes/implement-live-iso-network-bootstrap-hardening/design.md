# Design: implement-live-iso-network-bootstrap-hardening

## Scope

This change validates and hardens access to the live ISO. It does not install Gentoo and does not configure the target root.

Checks should include:

- live ISO booted and reachable,
- network interface has an IP address,
- default route exists,
- DNS resolution works,
- time is sane,
- SSH daemon reachable when using controller-to-live-ISO Ansible over the network,
- known_hosts behavior is explicit,
- project directory can be synchronized or accessed,
- Ansible inventory target is generated from discovered facts.

## Execution Modes

Network live ISO targets, controller-to-VM libvirt testing, and optional local live ISO execution must be documented separately.

Network and controller-to-VM modes use SSH. Local live ISO mode should run Ansible locally only if that optional fallback phase is implemented.

## Makefile Integration

Planned or existing targets may include:

- `make vm-bootstrap-ssh`
- `make vm-ansible-ping`
- `make ansible-live-preflight`
- `make prepare-live-env`

Only implemented targets should be documented as runnable.

## Safety

This workflow is read-only or live-environment-only. It must not partition, format, mount target filesystems, chroot, create target users, or install bootloaders.
