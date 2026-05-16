# Tasks: add-hyprland-wayland-desktop-profile

## OpenSpec
- [x] Create proposal, design, tasks, and spec delta.
- [x] Validate with `openspec validate add-hyprland-wayland-desktop-profile --strict`.
- [x] Validate with `openspec validate --all --strict`.

## Architecture
- [x] Define Hyprland as an advanced experimental Wayland profile.
- [x] Define experimental acknowledgement requirements.
- [x] Define `desktop_hyprland_wayland` role responsibilities.
- [x] Define Hyprland package and helper policy.
- [x] Define validation checks.

## Future Implementation
- [x] Add Hyprland profile variables.
- [x] Add Hyprland role tasks and templates.
- [x] Reuse shared desktop and Wayland helper tasks.
- [x] Add Makefile help entries.
- [x] Add package availability preflight.
- [x] Run `make ansible-check`.

## Documentation
- [x] Add or update `docs/desktop-profiles.md`.
- [x] Add `docs/desktop-hyprland-wayland.md`.
- [x] Document experimental status, launch method, and recovery.
- [x] Update relevant skills and OpenSpec tasks.

## Review Checklist
- [x] Confirm no automatic overlays, unmasking, or source builds.
- [x] Confirm no destructive installer behavior.
- [x] Confirm Hyprland-specific behavior is isolated.
- [x] Confirm docs do not present Hyprland as the default.
