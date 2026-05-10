# gentoo-ai-installer

`gentoo-ai-installer` helps a human operator install Gentoo Linux safely, then gradually turns validated manual steps into reproducible automation.

## Project Shape
- Phase 1: boot the official Gentoo live ISO and use temporary Codex assistance.
- Phase 2: build a local Ansible-based installer from the live ISO.
- libvirt/virsh: test manual installation flows with a managed VM and qcow2 disk before using real hardware.
- OpenSpec: control project changes.
- Makefile: expose operator-facing workflows.

## Main Targets
Run `make help` to see available targets.

Current libvirt manual test targets:

```sh
make vm-check
make vm-disk
make vm-define
make vm-start
make vm-console
make vm-viewer
make vm-ip
make vm-bootstrap-ssh
make vm-ssh
make vm-rsync
make vm-ansible-ping
make vm-shutdown
make vm-destroy
make vm-clean
```

Detailed VM usage is in `docs/libvirt-manual-install-test.md`. Legacy `qemu-*` targets are compatibility aliases for the libvirt workflow.

## Safety
Operator-facing actions should go through Makefile targets. Destructive workflows must require explicit confirmation and must document the target disk, paths, variables, failure modes, and recovery steps.

Documentation maintenance rules for agents are in `AGENTS.md`.
