# Tasks: add-desktop-login-manager

## OpenSpec
- [x] Create proposal, design, tasks, and spec deltas.
- [x] Validate with `openspec validate add-desktop-login-manager --strict`.
- [x] Validate with `openspec validate --all --strict`.

## Makefile and Wrapper Entry Points
- [x] Add Makefile variables for desktop login manager behavior:
  - `DESKTOP_LOGIN_MANAGER`
  - `DESKTOP_LOGIN_SESSIONS`
  - `DESKTOP_LOGIN_DEFAULT_SESSION`
  - `DESKTOP_LOGIN_ENABLE_SERVICE`
  - `I_UNDERSTAND_DESKTOP_LOGIN_MANAGER_CHANGES`
- [x] Add help entries for `desktop-login-plan`, `desktop-login-install`, and `desktop-login-validate`.
- [x] Add `scripts/ansible-desktop-login-plan.sh`.
- [x] Add `scripts/ansible-desktop-login-install.sh`.
- [x] Add `scripts/ansible-desktop-login-validate.sh`.
- [x] Reuse existing desktop SSH wrapper behavior and avoid duplicating raw SSH option strings.

## Ansible Implementation
- [x] Add `ansible/playbooks/post-install-desktop-login.yml`.
- [x] Add `ansible/playbooks/validate-desktop-login.yml`.
- [x] Add shared `post_install/desktop_login_common` role for installed-target validation, variables, session allowlist, session templates, read-only plan output, and shared validation.
- [x] Add `post_install/desktop_login_greetd` role for `greetd` package/config/greeter behavior.
- [x] Add init-specific OpenRC service enablement/start without `systemctl`.
- [x] Add init-specific systemd service enablement/start without `rc-update` or `rc-service`.
- [x] Keep `DESKTOP_DISPLAY_MANAGER=none` as the default and preserve existing manual session workflows.

## Safety and Package Policy
- [x] Require `I_UNDERSTAND_DESKTOP_LOGIN_MANAGER_CHANGES=yes` before enabling or starting the login manager service.
- [x] Keep `desktop-login-plan` and `desktop-login-validate` read-only.
- [x] Fail if the target appears to be the live ISO, a chroot, or an unfinished install.
- [x] Fail closed for unavailable `greetd`, greeter, or requested-session packages under `DESKTOP_PACKAGE_SOURCE=gentoo`.
- [x] Refuse overlays, keyword automation, autounmask writes, source builds, binary downloads, password changes, SSH authorization changes, disk work, bootloader work, and EFI changes.

## Session Integration
- [x] Generate allowlisted session entries for `i3-x11`, `sway-wayland`, `hyprland-wayland`, `niri-wayland`, and `mango-wayland`.
- [x] Add a shared project-owned session dispatcher or equivalent shared launch mechanism.
- [x] Validate requested sessions against installed profile commands and package state.
- [x] Ensure experimental profiles still require existing experimental/package-policy gates when installed.

## Documentation
- [x] Add `docs/desktop-login-manager.md`.
- [x] Update `docs/desktop-profiles.md`.
- [x] Update `docs/ansible-architecture.md`.
- [x] Update `skills/ansible-gentoo-installer.md`.
- [x] Update `skills/makefile-control-plane.md`.
- [x] Update agent guidance if project-wide desktop-login behavior or safety review rules change.

## Validation and Review
- [x] Run `make ansible-check`.
- [x] Run `make desktop-login-plan` against at least one installed test target.
- [x] Run `make desktop-login-install DESKTOP_DISPLAY_MANAGER=greetd I_UNDERSTAND_DESKTOP_LOGIN_MANAGER_CHANGES=yes` against at least one installed test target after package availability is confirmed.
- [x] Run `make desktop-login-validate` after installation.
- [x] Confirm no base installer, disk, chroot, bootloader, EFI, password, or live ISO workflow changed.
- [x] Confirm OpenRC/systemd service enablement/start logic is isolated and cannot bypass shared confirmation checks.
- [x] Document any unavoidable Ansible command-like tasks, check-mode limitations, package availability issues, or duplication.
