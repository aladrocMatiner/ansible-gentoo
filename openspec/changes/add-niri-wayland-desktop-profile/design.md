# Design: add-niri-wayland-desktop-profile

## 1. Position In The Project

Niri is an optional post-install Wayland desktop profile. It is not part of the base console install and must run only against an installed target over SSH.

The profile is classified as innovative rather than conservative. Operators should expect more package availability and compatibility checks than Sway.

## 2. Reuse Model

The role layout should be:

```text
ansible/
  roles/
    post_install/
      desktop_common/
      desktop_niri_wayland/
```

`desktop_common` provides installed-target validation, package framework, desktop user validation, common directories, and evidence writing.

`desktop_niri_wayland` provides Niri package selection, session files, Niri config templates, Xwayland compatibility checks, and Niri validation.

## 3. Variable Model

Expected variables:

| Variable | Required | Default | Purpose |
| --- | --- | --- | --- |
| `DESKTOP_PROFILE` | yes | none | Must be `niri-wayland`. |
| `DESKTOP_USER` | yes | none | Installed user receiving Niri config. |
| `DESKTOP_EXPERIMENTAL_OK` | yes | `no` | Must be `yes` if package policy marks Niri experimental on the selected host. |
| `DESKTOP_ENABLE_XWAYLAND` | no | `yes` | Install/configure Xwayland compatibility where available. |
| `DESKTOP_DISPLAY_MANAGER` | no | `none` | No display manager by default. |
| `DESKTOP_TARGET_HOST` | yes | none | Installed target SSH host or inventory host. |
| `DESKTOP_TARGET_USER` | yes | none | SSH user used by Ansible. |

## 4. Package Policy

Candidate package groups:

- compositor: `gui-wm/niri` if available in the configured Gentoo repository,
- Xwayland compatibility: `xwayland-satellite` or the approved Gentoo package when available,
- terminal: Wayland-capable terminal such as `gui-apps/foot` or documented alternative,
- launcher/bar: only if compatible and explicitly selected,
- clipboard/screenshot: Wayland helpers shared with Sway where practical.

The role must not add overlays or source-build Niri by default. If package availability is insufficient, it should fail with a message that names the missing atoms and the required future policy decision.

## 5. Makefile Integration

Planned targets:

- `make desktop-plan DESKTOP_PROFILE=niri-wayland DESKTOP_TARGET_HOST=... DESKTOP_USER=...`
- `make desktop-install DESKTOP_PROFILE=niri-wayland DESKTOP_TARGET_HOST=... DESKTOP_USER=... DESKTOP_EXPERIMENTAL_OK=yes`
- `make desktop-validate DESKTOP_PROFILE=niri-wayland DESKTOP_TARGET_HOST=... DESKTOP_USER=...`
- `make desktop-niri-install DESKTOP_TARGET_HOST=... DESKTOP_USER=... DESKTOP_EXPERIMENTAL_OK=yes`

The explicit experimental acknowledgement is required if Niri is not considered stable in the project package policy.

## 6. Validation

Validation must check:

- installed system marker,
- target is not live ISO,
- user exists,
- Niri binary exists,
- session config exists,
- optional Xwayland compatibility binary exists when requested,
- package policy did not silently add overlays or source builds,
- no display manager is enabled by default.

## 7. Safety

The Niri role must not run destructive installer operations. It must only manage installed target packages and desktop configuration.

Experimental package handling must fail closed. No overlay, source build, or unmasked package may be enabled without a later explicit OpenSpec change.

## 8. Documentation

Documentation must describe:

- Niri's scrollable-tiling workflow,
- experimental/innovative status,
- required acknowledgement variables,
- package availability behavior,
- launch method,
- Xwayland compatibility expectations,
- validation and recovery.

## 9. Review Checklist

- Niri-specific tasks are isolated.
- Common Wayland helper logic is shared with Sway where practical.
- Experimental package handling is explicit.
- No unreviewed overlay/source-build behavior exists.
- The base installer remains unchanged.
