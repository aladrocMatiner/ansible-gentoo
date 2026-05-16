# Tasks: add-niri-wayland-desktop-profile

## OpenSpec
- [x] Create proposal, design, tasks, and spec delta.
- [x] Validate with `openspec validate add-niri-wayland-desktop-profile --strict`.
- [x] Validate with `openspec validate --all --strict`.

## Architecture
- [ ] Define Niri as the innovative Wayland post-install profile.
- [ ] Define package availability and experimental acknowledgement rules.
- [ ] Define `desktop_niri_wayland` role responsibilities.
- [ ] Define Xwayland compatibility policy.
- [ ] Define validation checks and failure modes.

## Future Implementation
- [ ] Add Niri profile variables.
- [ ] Add Niri role tasks and templates.
- [ ] Reuse shared desktop and Wayland helper tasks where practical.
- [ ] Add Makefile help entries.
- [ ] Add package availability preflight.
- [ ] Run `make ansible-check`.

## Documentation
- [ ] Add or update `docs/desktop-profiles.md`.
- [ ] Add `docs/desktop-niri-wayland.md`.
- [ ] Document experimental acknowledgement and package availability behavior.
- [ ] Update relevant skills and OpenSpec tasks.

## Review Checklist
- [ ] Confirm no overlay or source-build behavior is implicit.
- [ ] Confirm Niri role does not duplicate common desktop behavior.
- [ ] Confirm no destructive installer operation exists.
- [ ] Confirm docs mark Niri as optional and innovative.
