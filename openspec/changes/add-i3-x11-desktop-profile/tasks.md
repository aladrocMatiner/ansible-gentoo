# Tasks: add-i3-x11-desktop-profile

## OpenSpec
- [x] Create proposal, design, tasks, and spec delta.
- [x] Validate with `openspec validate add-i3-x11-desktop-profile --strict`.
- [x] Validate with `openspec validate --all --strict`.

## Architecture
- [ ] Define the post-install desktop profile architecture.
- [ ] Define shared `desktop_common` responsibilities.
- [ ] Define `desktop_i3_x11` role responsibilities.
- [ ] Define installed-target SSH preconditions.
- [ ] Define i3/X11 package policy.
- [ ] Define `startx` as the default session start method.
- [ ] Define validation checks.
- [ ] Define safety exclusions for disk, bootloader, stage3, and live ISO workflows.

## Future Implementation
- [ ] Add Makefile targets for desktop plan, install, validate, and i3 convenience install.
- [ ] Add wrapper scripts if needed for installed-target Ansible inventory handling.
- [ ] Add `post-install-desktop.yml`.
- [ ] Add `validate-desktop.yml`.
- [ ] Add shared `desktop_common` role.
- [ ] Add `desktop_i3_x11` role.
- [ ] Add templates for `.xinitrc` and i3 config.
- [ ] Add package availability and installed-state checks.
- [ ] Run `make ansible-check`.

## Documentation
- [ ] Update `README.md` with concise post-install desktop entry points.
- [ ] Add or update `docs/desktop-profiles.md`.
- [ ] Add `docs/desktop-i3-x11.md`.
- [ ] Update `docs/ansible-architecture.md` with post-install role boundaries.
- [ ] Update relevant skills and agent guidance.
- [ ] Document failure modes and recovery.

## Review Checklist
- [ ] Confirm the profile runs only after stable installed-system validation.
- [ ] Confirm all operator-facing commands are Makefile targets.
- [ ] Confirm no destructive install commands are introduced.
- [ ] Confirm the role does not run against the live ISO by accident.
- [ ] Confirm shared desktop behavior is reusable by later profiles.
