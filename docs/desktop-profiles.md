# Post-Install Desktop Profiles

Desktop profiles are optional post-install Ansible workflows. They run after the base Gentoo system has been installed, booted from its own disk, reached over SSH, and validated with the normal first-boot checks.

They are not part of the basic-console installer. They must not run against the official Gentoo live ISO, a mounted `/mnt/gentoo` chroot, or an unfinished install.

## Implemented Profiles

| Profile | Status | Session | Default display manager |
| --- | --- | --- | --- |
| `i3-x11` | implemented | `startx` | `none` |
| `sway-wayland` | implemented, conservative Wayland | manual TTY launch | `none` |
| `hyprland-wayland` | implemented, experimental | manual TTY launch | `none` |
| `niri-wayland` | implemented, experimental/innovative | manual TTY launch | `none` |
| `mango-wayland` | implemented, experimental package availability | manual TTY launch | `none` |

Future desktop profiles should reuse the same Makefile targets, wrapper scripts, `post_install/desktop_common` role, shared Wayland helper role where relevant, and installed-target SSH model.

An optional post-install login screen is implemented separately through `make desktop-login-plan`, `make desktop-login-install`, and `make desktop-login-validate`. It currently supports `DESKTOP_DISPLAY_MANAGER=greetd` with `tuigreet`; see `docs/desktop-login-manager.md`.

## Required Target State

Before running a desktop profile:

- the installed system has completed `make final-checks` before reboot,
- the installed system has booted from disk,
- installed SSH access works,
- the target has `/etc/gentoo-release` and `/etc/fstab`,
- the root filesystem is not the live ISO overlay, squashfs, iso9660, or tmpfs root,
- `DESKTOP_USER` already exists,
- `DESKTOP_TARGET_USER` is `root` or has passwordless `sudo`,
- the target has a usable Portage tree for package availability checks.

## Makefile Targets

Plan the selected desktop profile without mutating the target:

```sh
make desktop-plan \
  DESKTOP_PROFILE=i3-x11 \
  DESKTOP_TARGET_HOST=<host-or-ip> \
  DESKTOP_TARGET_USER=<ssh-user> \
  DESKTOP_USER=<installed-user>
```

Install the selected desktop profile:

```sh
make desktop-install \
  DESKTOP_PROFILE=i3-x11 \
  DESKTOP_TARGET_HOST=<host-or-ip> \
  DESKTOP_TARGET_USER=<ssh-user> \
  DESKTOP_USER=<installed-user>
```

Validate the selected profile after installation:

```sh
make desktop-validate \
  DESKTOP_PROFILE=i3-x11 \
  DESKTOP_TARGET_HOST=<host-or-ip> \
  DESKTOP_TARGET_USER=<ssh-user> \
  DESKTOP_USER=<installed-user>
```

The i3 convenience target is equivalent to `DESKTOP_PROFILE=i3-x11 make desktop-install`:

```sh
make desktop-i3-install \
  DESKTOP_TARGET_HOST=<host-or-ip> \
  DESKTOP_TARGET_USER=<ssh-user> \
  DESKTOP_USER=<installed-user>
```

Wayland convenience targets:

```sh
make desktop-sway-install DESKTOP_TARGET_HOST=<host-or-ip> DESKTOP_TARGET_USER=<ssh-user> DESKTOP_USER=<installed-user>
make desktop-hyprland-install DESKTOP_TARGET_HOST=<host-or-ip> DESKTOP_TARGET_USER=<ssh-user> DESKTOP_USER=<installed-user> DESKTOP_EXPERIMENTAL_OK=yes
make desktop-niri-install DESKTOP_TARGET_HOST=<host-or-ip> DESKTOP_TARGET_USER=<ssh-user> DESKTOP_USER=<installed-user> DESKTOP_EXPERIMENTAL_OK=yes
make desktop-mango-install DESKTOP_TARGET_HOST=<host-or-ip> DESKTOP_TARGET_USER=<ssh-user> DESKTOP_USER=<installed-user> DESKTOP_EXPERIMENTAL_OK=yes
```

## Variables

| Variable | Default | Required | Meaning |
| --- | --- | --- | --- |
| `DESKTOP_PROFILE` | `i3-x11` | yes | Desktop profile to run. |
| `DESKTOP_TARGET_HOST` | none | yes | Installed Gentoo target hostname or IP. |
| `DESKTOP_TARGET_PORT` | `22` | no | SSH port on the installed target. |
| `DESKTOP_TARGET_USER` | none | yes | SSH user for Ansible. Must be root or passwordless sudo. |
| `DESKTOP_USER` | none | yes | Installed user that receives session files. |
| `DESKTOP_INSTALL_RECOMMENDS` | `yes` | no | Install profile helper packages. |
| `DESKTOP_ENABLE_PORTAL` | `yes` | no | Install Wayland portal support where the profile defines portal packages. |
| `DESKTOP_ENABLE_XWAYLAND` | `yes` | no | Install Xwayland compatibility packages where the profile defines them. |
| `DESKTOP_EXPERIMENTAL_OK` | `no` | for experimental installs | Required for Hyprland, Niri, and Mango install targets. |
| `DESKTOP_PACKAGE_SOURCE` | `gentoo` | no | Only `gentoo` is allowed; overlays/source builds need a later OpenSpec change. |
| `DESKTOP_DISPLAY_MANAGER` | `none` | no | Display manager policy. `none` is default; `greetd` is implemented through the separate desktop login manager workflow. |
| `DESKTOP_LOGIN_MANAGER` | `DESKTOP_DISPLAY_MANAGER` | no | Login manager selector for `desktop-login-*`; must match `DESKTOP_DISPLAY_MANAGER`. |
| `DESKTOP_LOGIN_SESSIONS` | `installed` | no | `installed` auto-detects sessions, or pass comma-separated profile names. |
| `DESKTOP_LOGIN_DEFAULT_SESSION` | first selected session | no | Default session for `tuigreet --cmd`. |
| `DESKTOP_LOGIN_ENABLE_SERVICE` | `yes` | no | Enable the selected login manager service after install. |
| `DESKTOP_SESSION_START` | profile default | no | `startx` for i3; `manual` for Wayland profiles. |
| `DESKTOP_PRIVILEGE_TOOL` | `sudo` | no | Privilege tool. Only `sudo` is implemented. |

## Safety Boundary

Desktop workflows may install packages and write session files under the selected installed user's home directory. They must not:

- partition, wipe, format, or mount disks,
- extract stage3,
- run installer chroot phases,
- install GRUB,
- call `efibootmgr`,
- change EFI boot entries,
- edit live ISO state as if it were the installed target,
- enable overlays, accept unstable keywords, clone upstream repositories, source-build compositors, or install prebuilt binaries,
- store passwords, tokens, or private keys.

The role validates the installed target boundary before package work. If the target looks like a live ISO root, the workflow fails.

The desktop login manager workflow may additionally install `gui-libs/greetd` and `gui-apps/tuigreet`, write `/etc/greetd/config.toml`, write system session entries under `/usr/share/xsessions` and `/usr/share/wayland-sessions`, write `/usr/local/bin/gentoo-ai-desktop-session`, enable the `greetd` service for boot, and start it after `I_UNDERSTAND_DESKTOP_LOGIN_MANAGER_CHANGES=yes`. It must not configure autologin or change user passwords.

## Portage USE Policy

Desktop profiles manage one Portage USE policy entry before installing packages. If `/etc/portage/package.use` is a directory or absent, the managed file is `/etc/portage/package.use/zz-gentoo-ai-installer-desktop`; if it is a regular file, the role inserts a marked block into that file.

The `zz-` prefix is intentional. The base console installer may keep desktop-related flags disabled in `gentoo-ai-installer-system`; the post-install desktop role must apply its explicit graphical USE policy after that baseline without using autounmask.

The managed entries enable the minimal graphical dependency flags required by the implemented profiles. GTK-related packages deliberately keep both `X` and `wayland` enabled where both stacks can be installed on the same target; otherwise a Wayland profile installed after i3 can try to rebuild shared libraries without X support.

```text
dev-cpp/cairomm X
dev-cpp/gtkmm X wayland
dev-libs/glib introspection
media-libs/freetype harfbuzz
media-libs/libglvnd X
media-libs/mesa X wayland
x11-libs/cairo X
x11-libs/gtk+ X wayland
x11-libs/libxkbcommon X wayland
x11-libs/pango X introspection
```

The desktop workflow still refuses autounmask, keyword changes, overlays, source builds, and binary downloads. If Portage asks for additional USE flags, update the role and this document rather than running ad-hoc `emerge --autounmask-write`.

## Failure Modes

- `DESKTOP_TARGET_HOST is required`: pass the installed system SSH host or IP.
- `DESKTOP_TARGET_USER is required`: pass a user that can connect over SSH and elevate with `sudo`.
- `DESKTOP_USER must name an existing installed-system user`: create or select the user before running the desktop profile.
- `target does not look like an installed amd64 Gentoo system`: boot the installed system, not the live ISO.
- `requested packages are unavailable`: the target Portage tree has no matching ebuild for one or more requested package atoms. Sync or fix the target Portage tree, then rerun the plan; the current roles do not add overlays, keywords, source builds, or binary downloads.
- Portage requests extra USE flags: update the managed desktop package.use policy and rerun `make desktop-install`.
- `DESKTOP_EXPERIMENTAL_OK=yes is required`: only install Hyprland, Niri, or Mango after accepting their package availability and compatibility risk.
- `DESKTOP_PACKAGE_SOURCE must be gentoo`: overlay, source-build, or binary package behavior is not implemented in these profiles.
- SSH timeouts: verify the installed system network, firewall, SSH daemon, port, and host key.
- Login manager package unavailable: sync or fix the target Portage tree; the role will not add overlays, keywords, autounmask changes, source builds, or binary downloads.
- Login manager service enabled by mistake: disable `greetd` with the target init system, then rerun `make desktop-login-plan`.

## Recovery

Run `make desktop-plan` again after correcting inputs or target state. If package installation fails, fix the Portage error on the installed target and rerun `make desktop-install`; the package task uses `--noreplace` and validates installed state before deciding whether to run.

If session files are wrong, rerun `make desktop-install` for the same `DESKTOP_USER`. Managed session launchers and profile configs are rewritten from templates.

If login manager session entries are wrong, rerun `make desktop-login-install DESKTOP_DISPLAY_MANAGER=greetd ... I_UNDERSTAND_DESKTOP_LOGIN_MANAGER_CHANGES=yes`. Managed system session entries and `greetd` config are rewritten from templates.

For Wayland profile details:

- `docs/desktop-sway-wayland.md`
- `docs/desktop-hyprland-wayland.md`
- `docs/desktop-niri-wayland.md`
- `docs/desktop-mango-wayland.md`
