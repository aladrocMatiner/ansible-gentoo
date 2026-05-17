# Design: add-desktop-login-manager

## Context
The current post-install desktop workflows install optional desktop profiles after the base Gentoo system is complete, booted from disk, and reachable over SSH. They deliberately avoid display managers: i3 is launched with `startx`, and Wayland profiles use managed per-user launcher scripts from a TTY.

The project now supports multiple desktop profiles. A shared login manager layer is needed so an installed target can present a login/session selector after boot without pushing display-manager logic into each desktop role.

Constraints:

- The base installer remains a console installer.
- The official Gentoo live ISO workflow must not be modified by desktop login manager logic.
- The reusable Ansible workflow runs over SSH against an installed target.
- Makefile targets are the operator-facing control plane.
- Ansible implementation must follow reuse-first architecture and Ansible quality standards.
- OpenRC and systemd service behavior must stay isolated.

## Goals / Non-Goals
**Goals:**

- Add a shared optional login manager workflow for already installed Gentoo targets.
- Keep `DESKTOP_DISPLAY_MANAGER=none` as the default.
- Support `DESKTOP_DISPLAY_MANAGER=greetd` as the first login manager profile.
- Generate reusable session entries for installed desktop profiles.
- Reuse installed-target validation and package-policy checks from the existing desktop workflow.
- Isolate only service-manager-specific behavior under OpenRC/systemd task files or roles.
- Expose planning, installation, and validation through Makefile targets.
- Document managed paths, variables, confirmation requirements, failure modes, and recovery.

**Non-Goals:**

- Do not install a login manager during the base console install.
- Do not target the live ISO, `/mnt/gentoo`, or a chroot.
- Do not change disk, stage3, chroot, kernel, bootloader, EFI, or user-password logic.
- Do not add package overlays, keyword automation, source builds, binary downloads, or autounmask writes.
- Do not implement autologin.
- Do not select a graphical desktop as a default system policy.
- Do not make unavailable experimental desktop packages appear installable.

## Decisions
### Use `greetd` first
Use `greetd` as the first supported login manager profile because it is small, works for both X11 and Wayland sessions, and has a simple service model. The implementation must validate the exact Gentoo package atoms before installing, and must fail closed if the package or greeter is unavailable under the current package policy.

Alternatives considered:

- `ly`: also lightweight, but session integration and Gentoo availability must be validated separately.
- `sddm` or `lightdm`: more familiar graphical login managers, but they pull larger desktop stacks and are not needed for the first reusable session-selector layer.
- No display manager: remains the default, but does not solve the requested login screen.

### Keep login manager workflow separate from desktop profile install
Add explicit targets for the login manager layer instead of changing `make desktop-install` to enable a service automatically.

The targets are:

- `make desktop-login-plan`
- `make desktop-login-install`
- `make desktop-login-validate`

This keeps the existing desktop profile workflow safe and predictable. Operators can install one or more desktop profiles first, then install the login manager after they are ready to expose sessions at boot.

### Use shared roles for session and target logic
The login manager implementation should use shared post-install roles:

```text
ansible/
  playbooks/
    post-install-desktop-login.yml
    validate-desktop-login.yml
  roles/
    post_install/
      desktop_login_common/
      desktop_login_greetd/
```

`desktop_login_common` owns installed-target validation, variable normalization, session allowlists, managed path definitions, read-only planning, and shared validation. `desktop_login_greetd` owns only the `greetd` package/config specifics. OpenRC/systemd service enablement is delegated to existing init-specific role/task structure where practical.

### Generate allowlisted session entries
The workflow should expose only known project desktop profiles:

- `i3-x11`
- `sway-wayland`
- `hyprland-wayland`
- `niri-wayland`
- `mango-wayland`

Session entries must be generated from shared templates into documented system paths such as `/usr/share/xsessions/` and `/usr/share/wayland-sessions/`. Commands should call a project-owned root-managed dispatcher such as `/usr/local/bin/gentoo-ai-desktop-session` with an allowlisted profile argument. This avoids duplicating launch commands in several `.desktop` files and provides one validation point for profile-to-command mapping.

### Require explicit confirmation for service enablement and start
Installing packages and writing session entries is post-install system mutation. Enabling a login manager changes persistent boot behavior, and starting it changes the current graphical login state. `desktop-login-install` must require:

```text
I_UNDERSTAND_DESKTOP_LOGIN_MANAGER_CHANGES=yes
```

when `DESKTOP_LOGIN_ENABLE_SERVICE=yes`. With that confirmation, the workflow may enable the service for boot and start it immediately. The confirmation does not bypass installed-target validation, package policy, or init-specific service checks.

### Preserve package policy
The login manager workflow uses the same package-source policy as desktop profiles:

- `DESKTOP_PACKAGE_SOURCE=gentoo`
- no overlays,
- no automatic keyword changes,
- no autounmask writes,
- no source builds,
- no binary downloads.

If `greetd`, its greeter, or a requested desktop profile package is unavailable, the plan/install command must fail with a package-policy error that explains the missing atom and the unsupported remediation paths.

### Validation model
`desktop-login-validate` must be read-only and should verify:

- target is an installed Gentoo system, not the live ISO,
- selected login manager package and greeter are installed,
- managed config files exist with expected ownership/mode,
- session entries exist only for requested/installed profiles,
- dispatcher exists and is root-owned,
- OpenRC uses OpenRC service state only for enablement and runtime checks,
- systemd uses systemd service state only for enablement and runtime checks,
- no autologin is configured,
- `DESKTOP_DISPLAY_MANAGER=none` still validates the no-login-manager case for existing desktop profiles.

## Risks / Trade-offs
- [Risk] Gentoo package atom names for `greetd` or a greeter vary by repository state. -> Mitigation: implementation must validate atoms with the target Portage tree before install and document exact atoms after testing.
- [Risk] Enabling a login manager can hide a broken session behind a login loop. -> Mitigation: keep service enablement explicit, provide `desktop-login-plan`, provide validation, and document how to disable the service from a TTY or SSH session.
- [Risk] Wayland sessions may require seat, dbus, or XDG runtime integration differences. -> Mitigation: keep launch behavior in a shared dispatcher and reuse existing Wayland profile validation before exposing sessions.
- [Risk] OpenRC and systemd service tasks can drift. -> Mitigation: isolate service enablement in init-specific tasks and require safety review for cross-init behavior.
- [Risk] Experimental desktop profiles are not available in Gentoo stable repositories. -> Mitigation: session generation must fail or skip according to documented requested-session policy; it must not weaken package policy.

## Migration Plan
1. Add Makefile targets and wrapper scripts for plan/install/validate.
2. Add Ansible playbooks and shared login manager roles.
3. Add `greetd` role behavior and init-specific service tasks.
4. Update desktop validation to accept `DESKTOP_DISPLAY_MANAGER=greetd` when explicitly requested while preserving `none` as default.
5. Add documentation and skills updates.
6. Run `make ansible-check`, OpenSpec validation, and at least one installed-target validation test.

Rollback path:

- Disable the login manager service with the init-appropriate command through a documented recovery target or manual recovery note.
- Rerun `make desktop-login-install DESKTOP_DISPLAY_MANAGER=none` only if a later implementation defines managed removal behavior; otherwise document manual removal separately.
- Keep existing TTY `startx` and Wayland launcher behavior intact as fallback.

## Open Questions
- Which exact Gentoo package atoms should be used for `greetd` and the initial greeter after target Portage validation?
- Should a later change add a graphical greeter profile such as `regreet`, `sddm`, or `lightdm`?
- Should login manager session generation skip unavailable requested profiles or fail when any requested session is unavailable? The first implementation should default to failing for explicitly requested sessions and only auto-detect installed profiles when `DESKTOP_LOGIN_SESSIONS=installed`.
