# Tasks: add-niri-wayland-desktop-profile

## OpenSpec
- [x] Create proposal, design, tasks, and spec delta.
- [x] Validate with `openspec validate add-niri-wayland-desktop-profile --strict`.
- [x] Validate with `openspec validate --all --strict`.

## Architecture
- [x] Define Niri as the innovative Wayland post-install profile.
- [x] Define package availability and experimental acknowledgement rules.
- [x] Define `desktop_niri_wayland` role responsibilities.
- [x] Define Xwayland compatibility policy.
- [x] Define validation checks and failure modes.

## Future Implementation
- [x] Add Niri profile variables.
- [x] Add Niri role tasks and templates.
- [x] Reuse shared desktop and Wayland helper tasks where practical.
- [x] Add Makefile help entries.
- [x] Add package availability preflight.
- [x] Run `make ansible-check`.

## Documentation
- [x] Add or update `docs/desktop-profiles.md`.
- [x] Add `docs/desktop-niri-wayland.md`.
- [x] Document experimental acknowledgement and package availability behavior.
- [x] Update relevant skills and OpenSpec tasks.

## Review Checklist
- [x] Confirm no overlay or source-build behavior is implicit.
- [x] Confirm Niri role does not duplicate common desktop behavior.
- [x] Confirm no destructive installer operation exists.
- [x] Confirm docs mark Niri as optional and innovative.
