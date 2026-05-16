# Tasks: add-mango-wayland-desktop-profile

## OpenSpec
- [x] Create proposal, design, tasks, and spec delta.
- [x] Validate with `openspec validate add-mango-wayland-desktop-profile --strict`.
- [x] Validate with `openspec validate --all --strict`.

## Architecture
- [x] Define Mango as an experimental Wayland post-install profile.
- [x] Define package availability and source/overlay boundaries.
- [x] Define `desktop_mango_wayland` role responsibilities.
- [x] Define validation checks and failure modes.
- [x] Define fallback guidance to stable profiles.

## Future Implementation
- [x] Add Mango profile variables.
- [x] Add Mango role tasks and templates.
- [x] Reuse shared desktop and Wayland helper tasks.
- [x] Add Makefile help entries.
- [x] Add package availability preflight.
- [x] Run `make ansible-check`.

## Documentation
- [x] Add or update `docs/desktop-profiles.md`.
- [x] Add `docs/desktop-mango-wayland.md`.
- [x] Document package availability limitations and fallback guidance.
- [x] Update relevant skills and OpenSpec tasks.

## Review Checklist
- [x] Confirm no implicit overlay, source build, or binary download behavior.
- [x] Confirm no destructive installer behavior.
- [x] Confirm Mango docs mark the profile experimental.
- [x] Confirm shared desktop behavior is reused.
