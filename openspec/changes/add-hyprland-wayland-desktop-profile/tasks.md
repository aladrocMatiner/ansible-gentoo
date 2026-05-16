# Tasks: add-hyprland-wayland-desktop-profile

## OpenSpec
- [x] Create proposal, design, tasks, and spec delta.
- [x] Validate with `openspec validate add-hyprland-wayland-desktop-profile --strict`.
- [x] Validate with `openspec validate --all --strict`.

## Architecture
- [ ] Define Hyprland as an advanced experimental Wayland profile.
- [ ] Define experimental acknowledgement requirements.
- [ ] Define `desktop_hyprland_wayland` role responsibilities.
- [ ] Define Hyprland package and helper policy.
- [ ] Define validation checks.

## Future Implementation
- [ ] Add Hyprland profile variables.
- [ ] Add Hyprland role tasks and templates.
- [ ] Reuse shared desktop and Wayland helper tasks.
- [ ] Add Makefile help entries.
- [ ] Add package availability preflight.
- [ ] Run `make ansible-check`.

## Documentation
- [ ] Add or update `docs/desktop-profiles.md`.
- [ ] Add `docs/desktop-hyprland-wayland.md`.
- [ ] Document experimental status, launch method, and recovery.
- [ ] Update relevant skills and OpenSpec tasks.

## Review Checklist
- [ ] Confirm no automatic overlays, unmasking, or source builds.
- [ ] Confirm no destructive installer behavior.
- [ ] Confirm Hyprland-specific behavior is isolated.
- [ ] Confirm docs do not present Hyprland as the default.
