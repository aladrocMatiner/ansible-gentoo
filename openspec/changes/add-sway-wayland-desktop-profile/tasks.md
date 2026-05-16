# Tasks: add-sway-wayland-desktop-profile

## OpenSpec
- [x] Create proposal, design, tasks, and spec delta.
- [x] Validate with `openspec validate add-sway-wayland-desktop-profile --strict`.
- [x] Validate with `openspec validate --all --strict`.

## Architecture
- [ ] Define Sway as the conservative Wayland post-install profile.
- [ ] Define shared desktop flow reuse.
- [ ] Define `desktop_sway_wayland` role responsibilities.
- [ ] Define Sway package groups.
- [ ] Define session launch policy without a display manager by default.
- [ ] Define validation checks.

## Future Implementation
- [ ] Add Sway profile variables.
- [ ] Add Sway role tasks and templates.
- [ ] Reuse `desktop_common` for installed-target validation and package framework.
- [ ] Add Makefile target help entries.
- [ ] Add desktop plan/install/validate wrapper behavior.
- [ ] Run `make ansible-check`.

## Documentation
- [ ] Add or update `docs/desktop-profiles.md`.
- [ ] Add `docs/desktop-sway-wayland.md`.
- [ ] Update Ansible architecture docs if shared desktop role layout changes.
- [ ] Update relevant skills and OpenSpec tasks.

## Review Checklist
- [ ] Confirm no live ISO install workflow is changed.
- [ ] Confirm no destructive disk or bootloader logic exists.
- [ ] Confirm Sway-specific tasks do not duplicate common desktop setup.
- [ ] Confirm package availability failures are actionable.
