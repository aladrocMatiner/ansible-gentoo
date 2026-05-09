# gentoo-ai-installer

`gentoo-ai-installer` helps a human operator install Gentoo Linux safely, then gradually turns validated manual steps into reproducible automation.

## Project Shape
- Phase 1: boot the official Gentoo live ISO and use temporary Codex assistance.
- Phase 2: build a local Ansible-based installer from the live ISO.
- QEMU: test manual installation flows with a qcow2 disk before using real hardware.
- OpenSpec: control project changes.
- Makefile: expose operator-facing workflows.

## Main Targets
Run `make help` to see available targets.

Current QEMU manual test targets:

```sh
make qemu-check
make qemu-disk
make qemu-boot
make qemu-clean
```

Detailed QEMU usage is in `docs/qemu-manual-install-test.md`.

## Safety
Operator-facing actions should go through Makefile targets. Destructive workflows must require explicit confirmation and must document the target disk, paths, variables, failure modes, and recovery steps.

Documentation maintenance rules for agents are in `AGENTS.md`.
