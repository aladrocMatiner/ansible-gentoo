# gentoo-ai-installer

`gentoo-ai-installer` helps a human operator install Gentoo Linux safely, then gradually turns validated manual steps into reproducible automation.

## Project Shape
- Phase 1: boot the official Gentoo live ISO and use temporary Codex assistance.
- Phase 2: build a reusable Ansible installer for network-reachable Gentoo live ISO targets.
- libvirt/virsh: local validation harness for manual and Ansible workflow testing with a managed VM and qcow2 disk before using real hardware.
- OpenSpec: control project changes.
- Makefile: expose operator-facing workflows.

## Main Targets
Run `make help` to see available targets.

Check implemented Ansible content:

```sh
make ansible-check
```

This syntax-checks implemented playbooks and runs `ansible-lint` when it is installed.

Validate installer configuration before connecting to a target:

```sh
make config-check
```

Configuration rules are documented in `docs/install-configuration.md`.

Check for accidental high-risk secrets before committing:

```sh
make secret-check
```

Secret handling rules are documented in `docs/secret-input-policy.md`.

Current Ansible planning targets run from the operator machine over SSH into a booted official Gentoo live ISO. For a real network target, pass `ANSIBLE_LIVE_HOST=<address>` and optionally `ANSIBLE_LIVE_USER=root ANSIBLE_LIVE_PORT=22`. When `ANSIBLE_LIVE_HOST` is empty, the wrapper targets discover the local libvirt VM as the test target.

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
