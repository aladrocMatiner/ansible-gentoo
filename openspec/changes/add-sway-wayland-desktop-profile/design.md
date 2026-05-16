# Design: add-sway-wayland-desktop-profile

## 1. Position In The Project

Sway is an optional post-install desktop profile. It is installed after the system has completed the basic-console workflow and passed installed-system validation.

It is not part of v1 disk installation and must not run against the live ISO install environment.

## 2. Reuse Model

Sway must reuse the generic post-install desktop flow:

```text
ansible/
  playbooks/
    post-install-desktop.yml
    validate-desktop.yml
  roles/
    post_install/
      desktop_common/
      desktop_sway_wayland/
```

Shared behavior belongs in `desktop_common`. Sway-specific behavior belongs in `desktop_sway_wayland`.

## 3. Variable Model

Expected variables:

| Variable | Required | Default | Purpose |
| --- | --- | --- | --- |
| `DESKTOP_PROFILE` | yes | none | Must be `sway-wayland`. |
| `DESKTOP_USER` | yes | none | Installed user receiving Sway config. |
| `DESKTOP_SESSION_START` | no | `manual` | Default is command-line launch, not display manager. |
| `DESKTOP_DISPLAY_MANAGER` | no | `none` | Display manager disabled by default. |
| `DESKTOP_ENABLE_PORTAL` | no | `yes` | Install portal support where available. |
| `DESKTOP_INSTALL_RECOMMENDS` | no | `yes` | Include terminal, launcher, bar, clipboard, screenshot helpers. |
| `DESKTOP_TARGET_HOST` | yes | none | Installed target SSH host or inventory host. |
| `DESKTOP_TARGET_USER` | yes | none | SSH user used by Ansible. |

## 4. Package Policy

Candidate package groups:

- compositor: `gui-wm/sway`,
- terminal: `gui-apps/foot` or a documented alternative,
- bar: `gui-apps/waybar` or Sway-compatible minimal status tooling,
- launcher: `gui-apps/wofi` or `dmenu`-compatible alternative,
- clipboard: `gui-apps/wl-clipboard`,
- screenshot: `gui-apps/grim` and `gui-apps/slurp`,
- portal: `xdg-desktop-portal` and a wlroots portal implementation where available.

Implementation must verify package availability in the target repository and fail with an actionable package-policy error when a package is unavailable.

## 5. Session Policy

The default should not enable a display manager. Documentation should show how to start Sway from a TTY.

If a later change adds `greetd`, `ly`, or another display manager, it must be optional, documented, and shared with other desktop profiles where practical.

## 6. Makefile Integration

Planned targets:

- `make desktop-plan DESKTOP_PROFILE=sway-wayland DESKTOP_TARGET_HOST=... DESKTOP_USER=...`
- `make desktop-install DESKTOP_PROFILE=sway-wayland DESKTOP_TARGET_HOST=... DESKTOP_USER=...`
- `make desktop-validate DESKTOP_PROFILE=sway-wayland DESKTOP_TARGET_HOST=... DESKTOP_USER=...`
- `make desktop-sway-install DESKTOP_TARGET_HOST=... DESKTOP_USER=...`

All targets must have help entries and must use installed-target Ansible inventory.

## 7. Validation

Validation must check:

- installed target marker,
- target is not live ISO,
- selected user exists,
- Sway binary exists,
- Wayland session dependencies are installed,
- user config exists,
- no display manager is enabled by default,
- no destructive installer commands ran.

## 8. Safety

Sway installation must not change disks, filesystems, bootloader, EFI entries, stage3, chroot install phases, or the official live ISO.

The role may install packages and write user-level or system-level desktop config files only under documented paths.

## 9. Documentation

Documentation must cover:

- why Sway is the conservative Wayland profile,
- required installed SSH/admin access,
- package groups,
- how to launch Sway,
- validation targets,
- common failure modes: missing seat/session permissions, no GPU/KMS support, missing portal, missing fonts, unavailable packages.

## 10. Review Checklist

- Sway-specific logic is isolated.
- Shared desktop behavior is reused.
- No display manager is enabled by default.
- Makefile targets are documented.
- Ansible quality standards are followed.
