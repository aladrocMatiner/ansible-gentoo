# Tasks: add-i3-x11-desktop-profile

## OpenSpec
- [x] Create proposal, design, tasks, and spec delta.
- [x] Validate with `openspec validate add-i3-x11-desktop-profile --strict`.
- [x] Validate with `openspec validate --all --strict`.

## Architecture
- [x] Define the post-install desktop profile architecture.
- [x] Define shared `desktop_common` responsibilities.
- [x] Define `desktop_i3_x11` role responsibilities.
- [x] Define installed-target SSH preconditions.
- [x] Define i3/X11 package policy.
- [x] Define `startx` as the default session start method.
- [x] Define validation checks.
- [x] Define safety exclusions for disk, bootloader, stage3, and live ISO workflows.

## Future Implementation
- [x] Add Makefile targets for desktop plan, install, validate, and i3 convenience install.
- [x] Add wrapper scripts if needed for installed-target Ansible inventory handling.
- [x] Add `post-install-desktop.yml`.
- [x] Add `validate-desktop.yml`.
- [x] Add shared `desktop_common` role.
- [x] Add `desktop_i3_x11` role.
- [x] Add templates for `.xinitrc` and i3 config.
- [x] Add package availability and installed-state checks.
- [x] Run `make ansible-check`.

## Documentation
- [x] Update `README.md` with concise post-install desktop entry points.
- [x] Add or update `docs/desktop-profiles.md`.
- [x] Add `docs/desktop-i3-x11.md`.
- [x] Update `docs/ansible-architecture.md` with post-install role boundaries.
- [x] Update relevant skills and agent guidance.
- [x] Document failure modes and recovery.

## Review Checklist
- [x] Confirm the profile runs only after stable installed-system validation.
- [x] Confirm all operator-facing commands are Makefile targets.
- [x] Confirm no destructive install commands are introduced.
- [x] Confirm the role does not run against the live ISO by accident.
- [x] Confirm shared desktop behavior is reusable by later profiles.
