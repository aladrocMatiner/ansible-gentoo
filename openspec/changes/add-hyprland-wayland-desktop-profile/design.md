# Design: add-hyprland-wayland-desktop-profile

## 1. Position In The Project

Hyprland is an optional advanced Wayland profile. It is not part of the stable basic-console installer and must not be installed unless the operator selects it explicitly.

It should be treated as experimental until package availability and validation are reliable in the supported Gentoo tree.

## 2. Reuse Model

Expected role layout:

```text
ansible/
  roles/
    post_install/
      desktop_common/
      desktop_hyprland_wayland/
```

Shared desktop and Wayland helper behavior must be reused. The Hyprland role owns compositor-specific packages, config templates, helper selection, and validation.

## 3. Variable Model

Expected variables:

| Variable | Required | Default | Purpose |
| --- | --- | --- | --- |
| `DESKTOP_PROFILE` | yes | none | Must be `hyprland-wayland`. |
| `DESKTOP_USER` | yes | none | Installed user receiving Hyprland config. |
| `DESKTOP_EXPERIMENTAL_OK` | yes | `no` | Required before installing Hyprland while classified experimental. |
| `DESKTOP_ENABLE_PORTAL` | no | `yes` | Install desktop portal support where available. |
| `DESKTOP_INSTALL_RECOMMENDS` | no | `yes` | Include launcher, bar, wallpaper, clipboard, screenshot helpers. |
| `DESKTOP_DISPLAY_MANAGER` | no | `none` | No display manager by default. |
| `DESKTOP_TARGET_HOST` | yes | none | Installed target SSH host or inventory host. |
| `DESKTOP_TARGET_USER` | yes | none | SSH user used by Ansible. |

## 4. Package Policy

Candidate package groups:

- compositor: `gui-wm/hyprland` if available in the selected Gentoo repository,
- bar/launcher: Wayland-compatible helpers such as `waybar` and `wofi` when available,
- wallpaper/lock helpers: optional, only if documented,
- clipboard/screenshot: shared Wayland helper packages where practical,
- portal: Hyprland-compatible portal support if available.

The implementation must not add overlays, accept unstable keywords, or build from source without a separate approved change.

## 5. Makefile Integration

Planned targets:

- `make desktop-plan DESKTOP_PROFILE=hyprland-wayland DESKTOP_TARGET_HOST=... DESKTOP_USER=...`
- `make desktop-install DESKTOP_PROFILE=hyprland-wayland DESKTOP_TARGET_HOST=... DESKTOP_USER=... DESKTOP_EXPERIMENTAL_OK=yes`
- `make desktop-validate DESKTOP_PROFILE=hyprland-wayland DESKTOP_TARGET_HOST=... DESKTOP_USER=...`
- `make desktop-hyprland-install DESKTOP_TARGET_HOST=... DESKTOP_USER=... DESKTOP_EXPERIMENTAL_OK=yes`

The explicit acknowledgement prevents accidental installation of a fast-moving compositor.

## 6. Validation

Validation must check:

- installed target marker,
- target is not live ISO,
- selected user exists,
- Hyprland binary exists,
- config exists under the selected user,
- required helper packages exist when enabled,
- package policy did not silently add overlays/source builds,
- no display manager is enabled by default.

## 7. Safety

The role must not run destructive installer commands or mutate bootloader/EFI/disk/stage3 state.

It may install packages and write desktop configuration only on the installed target.

## 8. Documentation

Documentation must describe:

- Hyprland as advanced/experimental,
- required acknowledgement variables,
- package availability limitations,
- how to launch the session,
- helper packages,
- GPU/session failure modes,
- how to fall back to the console if Hyprland does not start.

## 9. Review Checklist

- Experimental gate is enforced.
- No implicit overlay/source-build behavior exists.
- Common desktop/Wayland behavior is reused.
- Hyprland-specific config is isolated.
- The core installer remains unchanged.
