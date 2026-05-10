# Documentation Maintenance Checklist

Use this checklist before finishing any behavior-changing task.

## Required Checks
- New commands are documented.
- New Makefile targets are documented.
- Changed Makefile targets are documented.
- Removed Makefile targets are removed from docs.
- Changed variables and defaults are documented.
- Required confirmations are documented.
- Safety risks are documented.
- Failure modes are documented.
- Recovery steps are documented.
- Examples still match implementation.
- Stale instructions are corrected.
- `README.md` remains concise and accurate.
- Detailed procedures live under `docs/`.
- Reusable procedures live under `skills/`.
- Agent behavior rules live under `agents/` and `AGENTS.md`.
- OpenSpec implementation tasks include documentation tasks.

## Change-specific Checks
- Makefile change: update `README.md` or `docs/`; update `skills/makefile-control-plane.md` for reusable behavior.
- Script change: update `docs/` or relevant `skills/` with arguments, environment variables, safety checks, examples, and failure modes.
- Ansible change: update Ansible docs with variables, inventory, safety gates, and execution target.
- VM/libvirt change: update VM docs with ISO path, qcow2 path, libvirt URI, network mode, ports or forwarding when implemented, guest `/dev/vda`, and cleanup behavior.
- Codex bootstrap change: update Codex bootstrap docs with install method, token handling, validation, and cleanup.
- Safety change: update safety docs and relevant agent or skill files.
- OpenSpec workflow change: update OpenSpec workflow docs.

## Do Not Include
- Real API keys.
- Real tokens.
- Private SSH keys.
- Local credentials.
- Password values.
- Personal local paths except as clearly marked examples.
