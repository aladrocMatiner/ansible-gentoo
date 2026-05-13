# Design: Live ISO Ansible Preflight

## Overview
This change adds the first Ansible workflow that connects to the booted official Gentoo live ISO over SSH and gathers read-only facts.

The workflow is intentionally limited to preflight validation. It prepares for future installer automation without making installation changes.

## Operator Flow
Expected operator sequence:

```sh
make vm-start
make vm-bootstrap-ssh
make ansible-live-ping
make ansible-live-preflight
```

`make vm-start` and `make vm-bootstrap-ssh` are provided by the libvirt VM workflow. This change adds the Ansible targets.

## Makefile Targets
Add:

- `make ansible-live-ping`: run Ansible ping against the live ISO IP discovered by `make vm-ip`.
- `make ansible-live-preflight`: run the read-only preflight playbook against the live ISO.

Rules:

- Targets must discover the VM IP through `scripts/vm-ip.sh` unless `VM_IP` is explicitly provided.
- Targets must use `VM_SSH_USER`, default `root`.
- Targets must not expose raw `ansible-playbook` commands as the normal operator workflow.
- Targets must fail clearly when SSH is unavailable.

## Ansible Layout
Use a minimal layout that is compatible with the reuse-first architecture:

```text
ansible/
  inventory/
    live.yml
  playbooks/
    live-preflight.yml
  roles/
    common/
      live_preflight/
        tasks/
          main.yml
```

This role should remain read-only and may later be reused by OpenRC and systemd installation plans.

## Inventory Model
`ansible/inventory/live.yml` should define a logical host such as `gentoo_live`.

The live IP and SSH user should be passed by Makefile or environment, not hardcoded:

- `VM_IP`
- `VM_SSH_USER`
- `VM_SSH_GUEST_PORT`

No secrets or private key paths should be committed.

## Preflight Checks
The playbook should report:

- Ansible connectivity.
- Python interpreter discovered by Ansible.
- Kernel and architecture.
- Gentoo distribution facts when available.
- `/etc/gentoo-release` content when present.
- UEFI availability via `/sys/firmware/efi`.
- Network addresses.
- Default route.
- DNS resolver configuration.
- Visible block devices.
- Whether `/dev/vda` exists.

## Safety Rules
- Use Ansible fact gathering and read-only commands only.
- Disk commands must be inspection-only, such as `lsblk`.
- Do not call `parted`, `sgdisk`, `fdisk`, `wipefs`, `mkfs.*`, `mount`, `umount`, `chroot`, `passwd`, `useradd`, `usermod`, `grub-install`, or `efibootmgr`.
- Do not set `install_disk`.
- Do not require or consume destructive confirmation variables.
- Do not write files to the live ISO except temporary Ansible connection artifacts created by Ansible itself.

## Logging and Output
The Makefile target should print:

- target IP,
- SSH user,
- playbook name,
- that the workflow is read-only.

The playbook should produce a concise summary suitable for later install-plan work.

## Documentation
Update:

- `docs/ansible-live-preflight.md` with the operator flow, checks, failure modes, and recovery.
- `docs/libvirt-manual-install-test.md` with the Ansible validation handoff.
- relevant skills for Makefile and Ansible workflow expectations.

## Review Checklist
- Are all operator actions exposed through Makefile targets?
- Is the playbook read-only?
- Are dangerous commands absent?
- Does the workflow avoid selecting an install disk?
- Does documentation show the sequence from VM boot to Ansible preflight?
- Does OpenSpec validation pass?
