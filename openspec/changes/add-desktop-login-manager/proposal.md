# Proposal: add-desktop-login-manager

## Summary
Add an optional post-install login screen workflow for installed Gentoo systems so an operator can boot the installed machine, authenticate, and choose between installed desktop/window-manager sessions.

The first supported login manager profile is `DESKTOP_DISPLAY_MANAGER=greetd`; `DESKTOP_DISPLAY_MANAGER=none` remains the default. The workflow is implemented through Makefile targets and Ansible roles that run over SSH against an already installed Gentoo target.

## Motivation
The optional desktop profiles currently leave the installed system at a TTY-only launch model: i3 uses `startx`, while Wayland profiles use per-user launcher scripts. That is useful for early validation, but it does not provide a login screen where an operator can select between installed sessions after boot.

The project now has several optional desktop profiles. A shared login manager layer avoids each profile inventing its own display-manager behavior and keeps OpenRC/systemd service differences isolated.

## Problem Statement
Without a shared login manager workflow:

- installed desktop systems require manual TTY commands after login,
- session selection is not reproducible,
- future display-manager support could be duplicated across desktop roles,
- profile validation cannot distinguish "no display manager by design" from "managed login manager installed intentionally",
- OpenRC and systemd service enablement could drift.

## Scope
This change defines and later implements:

- Makefile targets:
  - `make desktop-login-plan`
  - `make desktop-login-install`
  - `make desktop-login-validate`
- Ansible entrypoints for planning, installing, and validating a post-install login manager.
- Shared post-install Ansible roles for installed-target validation, session entry generation, login manager package policy, and validation.
- Init-specific service enablement for OpenRC and systemd.
- `greetd` as the first supported login manager profile, with the exact Gentoo package atoms validated during implementation.
- Session entries for installed profiles:
  - `i3-x11`
  - `sway-wayland`
  - `hyprland-wayland`
  - `niri-wayland`
  - `mango-wayland`
- Documentation for usage, variables, service changes, recovery, and validation.

## Non-Goals
- Do not make a desktop or login manager part of the base console installer.
- Do not run login manager workflows against the official Gentoo live ISO or a mounted chroot.
- Do not change disk partitioning, formatting, mounting, stage3, chroot, kernel, bootloader, EFI, or base user creation behavior.
- Do not add overlays, unstable keyword automation, autounmask writes, source builds, binary downloads, or alternate package repositories.
- Do not implement autologin.
- Do not store passwords, tokens, SSH keys, or credentials.
- Do not add a full graphical desktop environment such as GNOME, KDE Plasma, or XFCE.
- Do not make Hyprland, Niri, or Mango installable when their Gentoo packages are unavailable under the existing package policy.

## Safety Considerations
- The workflow targets only an already installed Gentoo system reachable over SSH through `DESKTOP_TARGET_HOST`.
- The workflow must fail if the target appears to be the official live ISO or an unfinished installation environment.
- `desktop-login-plan` and `desktop-login-validate` must be read-only.
- `desktop-login-install` may install packages, write documented login/session files, enable one login manager service for boot, and start that service immediately only after explicit confirmation.
- Service enablement and immediate service start require `I_UNDERSTAND_DESKTOP_LOGIN_MANAGER_CHANGES=yes`.
- OpenRC service enablement/start must not call `systemctl`; systemd service enablement/start must not call `rc-update` or `rc-service`.
- The workflow must not partition, format, mount target roots, extract stage3, chroot, install GRUB, call `efibootmgr`, change EFI entries, modify passwords, or change SSH authorization.
- Managed paths must be documented before implementation. Expected paths include `/etc/greetd/`, `/usr/share/xsessions/`, `/usr/share/wayland-sessions/`, and a project-owned session dispatcher under `/usr/local/bin/`.
- Package availability failures must fail closed with actionable output.

## Acceptance Criteria
- `make desktop-login-plan` validates inputs and reports login manager/session changes without mutating the target.
- `make desktop-login-install` installs, enables, and starts `greetd` only when `DESKTOP_DISPLAY_MANAGER=greetd` and `I_UNDERSTAND_DESKTOP_LOGIN_MANAGER_CHANGES=yes` are set.
- `make desktop-login-validate` verifies the configured login manager, service state, and generated session entries without mutating the target.
- `DESKTOP_DISPLAY_MANAGER=none` remains the default behavior for existing desktop profile workflows.
- The implementation distinguishes installed-target desktop workflows from live ISO install workflows.
- Common session-entry generation, package policy, installed-target validation, and confirmation checks are implemented once and reused.
- Init-specific service enablement/start is isolated and validated for OpenRC and systemd.
- The workflow can expose installed `i3-x11`, `sway-wayland`, `hyprland-wayland`, `niri-wayland`, and `mango-wayland` sessions without duplicating per-profile login manager logic.
- Experimental desktop profiles remain gated by existing package policy and `DESKTOP_EXPERIMENTAL_OK` where relevant.
- Documentation explains variables, examples, failure modes, recovery, managed paths, and safety confirmations.
- `make ansible-check` passes after implementation.
- `openspec validate add-desktop-login-manager --strict` passes.
- `openspec validate --all --strict` passes.

## Capabilities

### New Capabilities
- `desktop-login-manager`: Optional post-install login manager support for selecting installed desktop/window-manager sessions on an already installed Gentoo target.

### Modified Capabilities
- `ansible-architecture`: Post-install desktop login manager roles must follow the reuse-first Ansible architecture, isolate init-specific service enablement, and reuse installed-target validation rather than duplicating desktop profile safety checks.

## Affected Files
Expected implementation and documentation files include:

- `Makefile`
- `scripts/ansible-desktop-login-plan.sh`
- `scripts/ansible-desktop-login-install.sh`
- `scripts/ansible-desktop-login-validate.sh`
- `scripts/ansible-desktop-common.sh`
- `ansible/playbooks/post-install-desktop-login.yml`
- `ansible/playbooks/validate-desktop-login.yml`
- `ansible/roles/post_install/desktop_login_common/`
- `ansible/roles/post_install/desktop_login_greetd/`
- `ansible/roles/post_install/desktop_common/`
- `ansible/roles/init/openrc/`
- `ansible/roles/init/systemd/`
- `docs/desktop-profiles.md`
- `docs/desktop-login-manager.md`
- `docs/ansible-architecture.md`
- `skills/ansible-gentoo-installer.md`
- `skills/makefile-control-plane.md`
- `agents/ansible-installer-agent.md`
- `agents/safety-review-agent.md`
- `openspec/changes/add-desktop-login-manager/tasks.md`
- `openspec/changes/add-desktop-login-manager/specs/desktop-login-manager/spec.md`
- `openspec/changes/add-desktop-login-manager/specs/ansible-architecture/spec.md`
