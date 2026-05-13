## Context

The primary installer path is an operator/controller machine running Makefile targets that invoke Ansible over SSH against a network-reachable official Gentoo live ISO target. The same Ansible flow is tested locally through libvirt, but reusable Ansible roles must remain network/inventory-driven and must not depend on libvirt details.

Several wrapper scripts currently pass hard-coded SSH options such as `ConnectTimeout=10`, temporary live ISO host-key options, and no consistent keepalive or control connection policy. This creates two problems:

- Long Gentoo install phases are more vulnerable to transient SSH stalls than necessary.
- Operators cannot tune transport behavior through the Makefile without editing scripts.

Running the controller command inside `tmux` or `screen` protects the operator's login session to the controller, but it does not protect the controller-to-live-ISO SSH connection. This change addresses the latter and documents the former.

## Goals / Non-Goals

**Goals:**

- Make SSH transport options configurable through Makefile variables.
- Use one shared helper to build Ansible SSH arguments for wrapper scripts.
- Apply the same transport policy to local libvirt targets and real network live ISO targets.
- Keep host-key relaxation scoped to temporary live ISO wrapper invocations.
- Keep global Ansible defaults conservative.
- Preserve compatibility with the existing `ANSIBLE_LIVE_HOST`, `ANSIBLE_LIVE_PORT`, and `ANSIBLE_LIVE_USER` model.
- Document when `tmux` or `screen` helps and what it does not solve.

**Non-Goals:**

- Do not implement resumable install phases in this change.
- Do not change the installation sequence.
- Do not introduce a local-in-live-ISO runner as the default path.
- Do not disable host key checking globally in `ansible.cfg`.
- Do not add destructive behavior.
- Do not make libvirt-specific SSH discovery part of reusable Ansible roles.

## Decisions

### Centralize SSH option construction

Add a shared shell helper, likely in `scripts/vm-libvirt-common.sh` or a new sourced helper, that validates SSH transport variables and emits Ansible-compatible `--ssh-common-args` content.

Rationale: every wrapper should get the same timeout, keepalive, host-key, and control connection behavior. Repeated strings drift quickly and are difficult to audit.

Alternative considered: keep per-wrapper SSH strings and update each one. This is rejected because it preserves duplication and makes future policy changes error-prone.

### Keep host-key relaxation scoped to temporary live ISO wrappers

The shared helper may continue to include `StrictHostKeyChecking=no` and `UserKnownHostsFile=/dev/null` only for temporary official live ISO wrapper invocations. It must not edit `ansible.cfg` to disable host-key checking globally.

Rationale: the official live ISO host key is temporary and changes after reboot, while global host-key relaxation would weaken unrelated Ansible workflows.

Alternative considered: use global `host_key_checking = False`. This is rejected by existing project quality standards.

### Use fixed conservative transport defaults

The implementation must use these defaults unless an operator overrides them through Makefile variables:

- `ANSIBLE_SSH_CONNECT_TIMEOUT ?= 10`
- `ANSIBLE_SSH_SERVER_ALIVE_INTERVAL ?= 30`
- `ANSIBLE_SSH_SERVER_ALIVE_COUNT_MAX ?= 6`
- `ANSIBLE_SSH_CONTROL_MASTER ?= auto`
- `ANSIBLE_SSH_CONTROL_PERSIST ?= 10m`
- `ANSIBLE_SSH_CONTROL_PATH_DIR ?= var/ssh-control`

These values keep failures bounded while allowing temporary stalls of roughly three minutes before the SSH client gives up.

Alternative considered: very long timeouts. This is rejected because failures should remain visible and recoverable.

### Enable control sockets by default for Ansible wrappers

Control socket paths should live under the project-local ignored runtime directory `var/ssh-control` by default and must not contain secrets. The implementation should create the directory only when a wrapper that needs it runs. Ansible wrappers should enable `ControlMaster=auto` and `ControlPersist=10m` by default because repeated role and playbook invocations are common during install planning, apply, validation, and recovery.

Rationale: connection reuse improves repeated Ansible calls and avoids relying on user-specific SSH config. Project-local sockets are easier to clean.

Alternative considered: rely on `~/.ssh/config`. This is rejected because the Makefile should remain the operator-facing control plane.

Alternative considered: enable control sockets only for full install targets. This is rejected because the same target can run against local libvirt or a real network live ISO, and consistent behavior across wrappers is simpler to test and document. Operators can disable reuse with `ANSIBLE_SSH_CONTROL_MASTER=no` when needed.

### Recommend controller-side tmux or screen

Documentation should recommend running long install targets from `tmux` or `screen` on the controller. This is guidance, not a hard requirement.

Rationale: it protects the operator's terminal session without changing the Ansible architecture.

Alternative considered: execute the full installer inside the live ISO by default. This is out of scope and would require a separate change because the current primary product is the remote SSH Ansible installer.

## Risks / Trade-offs

- Control socket path length limits -> Keep `ANSIBLE_SSH_CONTROL_PATH_DIR` short and use a compact `ControlPath` pattern.
- Stale control sockets -> Use `ControlMaster=auto` and document cleanup; avoid storing sockets outside project-local runtime paths.
- Longer keepalive windows delay failure detection -> Keep defaults bounded and configurable.
- Host-key relaxation may be over-applied -> Restrict the helper to live ISO wrappers and keep global `ansible.cfg` unchanged.
- Wrapper drift may remain if not all scripts are migrated -> Tasks must inventory and update every `ansible-playbook` and `ansible` wrapper invocation.

## Migration Plan

1. Add documented Makefile variables with conservative defaults.
2. Add or update a shared shell helper for SSH transport arguments.
3. Replace repeated `--ssh-common-args` strings in Ansible wrapper scripts with the helper output.
4. Update docs and skills.
5. Run syntax, secret, release, and OpenSpec checks.

Rollback is simple: revert to the previous hard-coded wrapper arguments. No target system state or disk state is affected.

## Open Questions

- Should a future change add a dedicated `make ssh-transport-check` target, or is validation through existing Ansible targets sufficient?
