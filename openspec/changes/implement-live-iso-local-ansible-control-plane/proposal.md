# Change: implement-live-iso-local-ansible-control-plane

## Summary
Add an optional local live ISO Ansible execution path for fallback and diagnostics. The primary phase-2 installer path is network Ansible from an operator/controller machine to a target booted into the official Gentoo live ISO.

## Motivation
The project is centered on a reusable network Ansible installer. A local live ISO control plane can still be useful when an operator deliberately copies the project into the live ISO and wants diagnostics or an emergency fallback, but it must not replace or constrain the remote/inventory-driven architecture.

## Scope
- Add optional local Ansible inventory and wrappers.
- Add Makefile targets for local live ISO execution.
- Keep host VM validation targets separate.
- Integrate hardened live ISO network/bootstrap checks before Ansible handoff.
- Use supported host requirements for controller-driven libvirt checks and separate them from local live ISO execution checks.
- Document local Ansible as optional fallback or diagnostics, not the primary installer workflow.
- Preserve no-default-disk safety rules.
- Preserve Ansible quality standards and avoid global host-key disabling.

## Non-goals
- Do not implement destructive installer tasks.
- Do not remove controller-to-VM libvirt testing.
- Do not build a custom ISO.

## Safety Requirements
- Local targets must not infer `INSTALL_DISK`.
- Local targets must use the same variables as VM planning targets.
- Network, DNS, time, SSH, and project path failures must fail early with actionable errors.
- Destructive targets must remain blocked until later approved changes add safety gates.
- Local execution must be covered by `make ansible-check` and must not inherit temporary VM SSH host-key exceptions.

## Acceptance Criteria
- Local inventory exists for `ansible_connection=local`.
- Makefile exposes optional local Ansible check/preflight/plan targets or a safe selector.
- Docs explain host VM mode versus local live ISO mode.
- Docs explain network Ansible mode as the primary product path.
- Live ISO network/bootstrap hardening is documented as the prerequisite for Ansible handoff.
- Host requirements are documented separately from live ISO local execution requirements.
- `openspec validate implement-live-iso-local-ansible-control-plane --strict` passes.

## Affected Files
- `Makefile`
- `ansible/inventory/local.yml`
- `scripts/`
- `docs/`
- `skills/ansible-gentoo-installer.md`
