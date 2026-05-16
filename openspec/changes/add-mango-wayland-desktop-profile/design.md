# Design: add-mango-wayland-desktop-profile

## 1. Position In The Project

Mango is an optional experimental Wayland desktop profile. It is a post-install customization for installed systems only.

The profile is not guaranteed to be installable on every Gentoo tree until package availability is confirmed. The role must expose that limitation clearly.

## 2. Reuse Model

Expected role layout:

```text
ansible/
  roles/
    post_install/
      desktop_common/
      desktop_mango_wayland/
```

Common desktop setup, installed-target validation, package framework, and evidence reporting belong in `desktop_common`. Mango-specific config belongs in `desktop_mango_wayland`.

## 3. Variable Model

Expected variables:

| Variable | Required | Default | Purpose |
| --- | --- | --- | --- |
| `DESKTOP_PROFILE` | yes | none | Must be `mango-wayland`. |
| `DESKTOP_USER` | yes | none | Installed user receiving Mango config. |
| `DESKTOP_EXPERIMENTAL_OK` | yes | `no` | Required before attempting Mango installation. |
| `DESKTOP_PACKAGE_SOURCE` | no | `gentoo` | v1 allows only packaged Gentoo source unless later changed. |
| `DESKTOP_DISPLAY_MANAGER` | no | `none` | No display manager by default. |
| `DESKTOP_TARGET_HOST` | yes | none | Installed target SSH host or inventory host. |
| `DESKTOP_TARGET_USER` | yes | none | SSH user used by Ansible. |

## 4. Package Policy

Candidate package groups:

- compositor: a Gentoo package for Mango/MangoWC if available in the configured tree,
- terminal: Wayland terminal shared with other profiles,
- launcher/bar/clipboard: optional helpers shared with Sway/Hyprland where compatible.

If the compositor package is unavailable, the role must fail with a clear `PACKAGE_UNAVAILABLE`-style message. It must not clone upstream, compile from source, install prebuilt binaries, or add overlays by default.

## 5. Makefile Integration

Planned targets:

- `make desktop-plan DESKTOP_PROFILE=mango-wayland DESKTOP_TARGET_HOST=... DESKTOP_USER=...`
- `make desktop-install DESKTOP_PROFILE=mango-wayland DESKTOP_TARGET_HOST=... DESKTOP_USER=... DESKTOP_EXPERIMENTAL_OK=yes`
- `make desktop-validate DESKTOP_PROFILE=mango-wayland DESKTOP_TARGET_HOST=... DESKTOP_USER=...`
- `make desktop-mango-install DESKTOP_TARGET_HOST=... DESKTOP_USER=... DESKTOP_EXPERIMENTAL_OK=yes`

The plan target should show whether the package is available before install.

## 6. Validation

Validation must check:

- installed target marker,
- target is not live ISO,
- selected user exists,
- Mango compositor package and binary are installed,
- session config exists,
- experimental acknowledgement was provided,
- no overlay/source build was performed implicitly.

## 7. Safety

The Mango role must not run destructive installer commands. It must not run arbitrary upstream build commands or fetch executable code outside Portage package policy.

Only installed target packages and desktop config files may be changed.

## 8. Documentation

Documentation must describe:

- Mango as experimental,
- package availability limitations,
- required acknowledgement,
- launch method,
- validation,
- how to skip/fall back to Sway or i3 when Mango is unavailable.

## 9. Review Checklist

- Package availability failure is explicit.
- No source-build or overlay behavior is implicit.
- Shared desktop behavior is reused.
- Mango-specific behavior is isolated.
- The base installer remains unchanged.
