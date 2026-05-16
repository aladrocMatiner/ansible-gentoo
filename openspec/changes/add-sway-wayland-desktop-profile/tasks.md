# Tasks: add-sway-wayland-desktop-profile

## OpenSpec
- [x] Create proposal, design, tasks, and spec delta.
- [x] Validate with `openspec validate add-sway-wayland-desktop-profile --strict`.
- [x] Validate with `openspec validate --all --strict`.

## Architecture
- [x] Define Sway as the conservative Wayland post-install profile.
- [x] Define shared desktop flow reuse.
- [x] Define `desktop_sway_wayland` role responsibilities.
- [x] Define Sway package groups.
- [x] Define session launch policy without a display manager by default.
- [x] Define validation checks.

## Future Implementation
- [x] Add Sway profile variables.
- [x] Add Sway role tasks and templates.
- [x] Reuse `desktop_common` for installed-target validation and package framework.
- [x] Add Makefile target help entries.
- [x] Add desktop plan/install/validate wrapper behavior.
- [x] Run `make ansible-check`.

## Documentation
- [x] Add or update `docs/desktop-profiles.md`.
- [x] Add `docs/desktop-sway-wayland.md`.
- [x] Update Ansible architecture docs if shared desktop role layout changes.
- [x] Update relevant skills and OpenSpec tasks.

## Review Checklist
- [x] Confirm no live ISO install workflow is changed.
- [x] Confirm no destructive disk or bootloader logic exists.
- [x] Confirm Sway-specific tasks do not duplicate common desktop setup.
- [x] Confirm package availability failures are actionable.
