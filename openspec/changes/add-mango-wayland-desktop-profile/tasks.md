# Tasks: add-mango-wayland-desktop-profile

## OpenSpec
- [x] Create proposal, design, tasks, and spec delta.
- [x] Validate with `openspec validate add-mango-wayland-desktop-profile --strict`.
- [x] Validate with `openspec validate --all --strict`.

## Architecture
- [ ] Define Mango as an experimental Wayland post-install profile.
- [ ] Define package availability and source/overlay boundaries.
- [ ] Define `desktop_mango_wayland` role responsibilities.
- [ ] Define validation checks and failure modes.
- [ ] Define fallback guidance to stable profiles.

## Future Implementation
- [ ] Add Mango profile variables.
- [ ] Add Mango role tasks and templates.
- [ ] Reuse shared desktop and Wayland helper tasks.
- [ ] Add Makefile help entries.
- [ ] Add package availability preflight.
- [ ] Run `make ansible-check`.

## Documentation
- [ ] Add or update `docs/desktop-profiles.md`.
- [ ] Add `docs/desktop-mango-wayland.md`.
- [ ] Document package availability limitations and fallback guidance.
- [ ] Update relevant skills and OpenSpec tasks.

## Review Checklist
- [ ] Confirm no implicit overlay, source build, or binary download behavior.
- [ ] Confirm no destructive installer behavior.
- [ ] Confirm Mango docs mark the profile experimental.
- [ ] Confirm shared desktop behavior is reused.
