# implement-live-iso-ansible-preflight

## Summary
Add the first read-only Ansible workflow against a booted official Gentoo live ISO target over SSH.

The workflow validates that the live ISO is reachable over SSH, that Ansible can execute read-only checks, and that the environment is suitable for future installer planning. It must not partition, format, mount target filesystems, extract stage3, or otherwise install Gentoo.

## Motivation
The libvirt workflow now boots the official Gentoo live ISO, exposes a serial console, bootstraps temporary SSH access, discovers the guest IP, and validates `ansible ping`. That VM is the local validation target. The reusable Ansible workflow must also support an explicit network live ISO target selected by `ANSIBLE_LIVE_HOST`.

The next step is a structured Ansible preflight that proves the project can safely gather facts from the live ISO before any installer automation is introduced.

## Problem Statement
Ad-hoc SSH and `ansible ping` prove connectivity, but they do not provide a reusable project contract for live ISO validation. Before disk planning or installation playbooks are implemented, the project needs a Makefile-mediated Ansible preflight that is:

- read-only,
- explicit about the live ISO target,
- reusable by future OpenRC and systemd install flows,
- aligned with the Ansible reuse-first architecture,
- safe to run repeatedly.

## Scope
- Add Makefile targets for live ISO Ansible connectivity and preflight.
- Add a minimal Ansible inventory for a network-reachable live ISO target.
- Add a read-only playbook that validates live ISO facts and reports environment state.
- Add shared/common Ansible structure only where it supports future reuse.
- Document how to run the preflight with `ANSIBLE_LIVE_HOST=...` and how the local VM harness discovers the target when it is omitted.
- Keep all operator-facing commands behind Makefile targets.

## Non-goals
- Do not partition or format disks.
- Do not mount target filesystems.
- Do not extract stage3.
- Do not configure Portage.
- Do not chroot.
- Do not install kernels, bootloaders, users, services, or packages.
- Do not implement OpenRC or systemd installation flows.
- Do not store secrets, passwords, private keys, or tokens.

## Safety Considerations
- The playbook must be read-only.
- The playbook must not use shell commands that mutate state.
- Any disk checks must gather facts only.
- `/dev/vda` may be observed as the VM disk in local validation but must not be modified or treated as a default for real network targets.
- The workflow must fail if SSH is unavailable.
- The workflow must fail if it cannot identify the environment as Gentoo live ISO or compatible Gentoo live environment.
- The workflow must not infer an install disk or set `install_disk`.
- The workflow must not require `I_UNDERSTAND_THIS_WIPES_DISK`.

## Acceptance Criteria
- `make ansible-live-ping` validates Ansible SSH connectivity to the live ISO.
- `make ansible-live-preflight` runs a read-only Ansible preflight against the live ISO.
- The preflight reports architecture, kernel, OS family/distribution data, UEFI availability, network addresses, DNS configuration, default route, and visible block devices. Local VM validation may additionally report whether `/dev/vda` is present.
- The preflight does not change the live ISO or VM disk.
- The preflight does not choose an install disk.
- The preflight does not run installer playbooks.
- Documentation explains explicit network target usage and the local VM harness sequence: `make vm-start`, `make vm-bootstrap-ssh`, `make ansible-live-ping`, `make ansible-live-preflight`.
- OpenSpec validation passes with `openspec validate implement-live-iso-ansible-preflight --strict`.
- Full validation passes with `openspec validate --all --strict`.

## Affected Files
- `Makefile`
- `ansible/`
- `docs/libvirt-manual-install-test.md`
- `docs/ansible-live-preflight.md`
- `skills/ansible-gentoo-installer.md`
- `skills/makefile-control-plane.md`
- `openspec/changes/implement-live-iso-ansible-preflight/`
