# Design: add-i3-x11-desktop-profile

## 1. Position In The Project

The i3 profile is a post-install customization. It runs after the base Gentoo installation is stable and reachable over SSH as an installed system.

Required preconditions:

- base install completed,
- installed system booted from disk,
- installed SSH access works,
- admin user exists and can use sudo or the configured privilege tool,
- first-boot validation passed where available.

The role must not run inside the live ISO installation chroot or before final checks.

## 2. Reuse Model

The first desktop profile should establish a reusable post-install desktop architecture:

```text
ansible/
  playbooks/
    post-install-desktop.yml
    validate-desktop.yml
  roles/
    post_install/
      desktop_common/
      desktop_i3_x11/
```

`desktop_common` owns shared behavior:

- target validation,
- package installation framework,
- desktop user selection,
- common shell/session directory creation,
- D-Bus/session prerequisites,
- reusable validation output,
- common documentation and evidence paths.

`desktop_i3_x11` owns only i3/X11-specific behavior:

- i3 package set,
- X11 package set,
- `.xinitrc` or equivalent session launcher,
- i3 config template,
- i3 validation checks.

## 3. Variable Model

Expected variables:

| Variable | Required | Default | Purpose |
| --- | --- | --- | --- |
| `DESKTOP_PROFILE` | yes | none | Must be `i3-x11` for this profile. |
| `DESKTOP_USER` | yes | none | Installed user that receives session config. |
| `DESKTOP_INSTALL_RECOMMENDS` | no | `yes` | Include terminal, launcher, status bar, and clipboard helpers. |
| `DESKTOP_DISPLAY_MANAGER` | no | `none` | v1 default is no display manager. |
| `DESKTOP_SESSION_START` | no | `startx` | Session start method for i3. |
| `DESKTOP_TARGET_HOST` | yes | none | Installed target SSH host or inventory host. |
| `DESKTOP_TARGET_USER` | yes | none | SSH user used by Ansible. |
| `DESKTOP_PRIVILEGE_TOOL` | no | project default | `sudo` or approved equivalent. |

The role must fail if `DESKTOP_USER` is missing, if the user does not exist, or if the target appears to be the live ISO instead of the installed system.

## 4. Package Policy

Candidate package groups:

- X11 base: `x11-base/xorg-server`, `x11-apps/xinit`.
- Window manager: `x11-wm/i3`.
- Usability helpers: `x11-misc/i3status` or `x11-misc/i3blocks`, `x11-misc/dmenu` or `rofi`.
- Terminal: a conservative terminal package such as `x11-terms/alacritty` if available in the target tree, otherwise a documented alternative.
- Clipboard/tools: optional X11 clipboard helpers.

The implementation must verify package availability against the target Gentoo repository before hard-failing with an unclear Portage resolver error.

## 5. Makefile Integration

Planned targets:

- `make desktop-plan DESKTOP_PROFILE=i3-x11 DESKTOP_TARGET_HOST=... DESKTOP_USER=...`
- `make desktop-install DESKTOP_PROFILE=i3-x11 DESKTOP_TARGET_HOST=... DESKTOP_USER=...`
- `make desktop-validate DESKTOP_PROFILE=i3-x11 DESKTOP_TARGET_HOST=... DESKTOP_USER=...`
- `make desktop-i3-install DESKTOP_TARGET_HOST=... DESKTOP_USER=...`

All targets must have help output. The generic targets should be preferred so future desktop profiles share the same flow.

## 6. Validation

Validation must check:

- installed system marker exists,
- target is not the live ISO,
- selected user exists,
- selected packages are installed,
- `i3` binary exists,
- `startx` exists,
- user session file exists and launches i3,
- no display manager is enabled unless explicitly requested,
- no disk, mount, bootloader, or stage3 command ran.

## 7. Safety

The implementation must not invoke:

- `parted`, `sgdisk`, `fdisk`, `wipefs`, `mkfs.*`, `dd`,
- `mount` or `umount` for target installation paths,
- `grub-install`, `efibootmgr`,
- stage3 extraction,
- installer chroot phases.

Package installation and user config changes must be logged as post-install desktop changes.

## 8. Documentation

Documentation must explain:

- i3 is optional and post-install,
- how to run the Makefile targets,
- required SSH/admin prerequisites,
- packages installed,
- how to start the session with `startx`,
- how to validate and uninstall/disable manually if needed,
- failure modes such as missing Xorg, missing user, no GPU driver, or no input permissions.

## 9. Review Checklist

- Shared desktop logic is in `desktop_common`.
- i3-specific logic is isolated.
- No basic-console installer behavior changes.
- No destructive disk or bootloader operations exist.
- OpenRC/systemd differences are isolated where needed.
- Documentation and OpenSpec tasks are updated.
