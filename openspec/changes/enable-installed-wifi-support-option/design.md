# Design: enable-installed-wifi-support-option

## 1. Position In The Project

Installed WiFi support is an optional target-system package policy. It is separate from live ISO WiFi bootstrap.

The installer may connect to the official live ISO over WiFi during installation. That does not automatically mean the installed Gentoo target can use WiFi after reboot. `ENABLE_WIFI=yes` explicitly requests installed-system WiFi support.

## 2. Variable Model

Add:

| Variable | Default | Allowed | Purpose |
| --- | --- | --- | --- |
| `ENABLE_WIFI` | `no` | `yes`, `no` | Install target WiFi firmware/supplicant support and build NetworkManager with WiFi support. |

Mapping:

- Makefile/env: `ENABLE_WIFI`
- Ansible: `enable_wifi`

Default remains `no` to preserve current VM and wired-server behavior.

## 3. Package Policy

When `ENABLE_WIFI=no`:

- keep the existing conservative NetworkManager USE policy without WiFi,
- do not install `sys-kernel/linux-firmware` for WiFi by default,
- do not install `net-wireless/wpa_supplicant` unless another future policy requires it.

When `ENABLE_WIFI=yes`:

- include `sys-kernel/linux-firmware`,
- include `net-wireless/wpa_supplicant`,
- allow Portage to install dependencies such as `net-wireless/wireless-regdb` and `dev-libs/libnl`,
- build `net-misc/networkmanager` with `wifi`,
- build `net-wireless/wpa_supplicant` with `dbus`,
- keep insecure legacy flags such as `tkip` and `wep` disabled unless a later explicit change adds compatibility options.

## 4. Ansible Role Changes

`ansible/roles/common/package_install` should:

- define `package_install_enable_wifi`,
- validate `enable_wifi` as `yes|no`,
- require `wifi_console_packages` and `wifi_package_use`,
- compose package USE entries from base policy plus WiFi policy when enabled,
- add WiFi packages only when enabled,
- record `enable_wifi` and the effective package.use entries in package evidence.

The implementation should avoid duplicating package logic in init-specific roles.

## 5. Final Checks

`ansible/roles/common/final_checks` should:

- validate `enable_wifi`,
- include WiFi packages in expected packages when enabled,
- report `enable_wifi`,
- keep final checks read-only,
- avoid reading or printing NetworkManager connection secrets.

Final checks do not need to prove actual association to a WiFi network. They verify the installed target has the package and USE policy expected for WiFi-capable first boot.

## 6. Makefile And Script Integration

Operator-facing flows remain existing Makefile targets:

- `make config-check ENABLE_WIFI=yes`
- `make install-system-packages ENABLE_WIFI=yes`
- `make final-checks ENABLE_WIFI=yes`
- `make install-systemd ENABLE_WIFI=yes ...`
- `make install-openrc ENABLE_WIFI=yes ...`

Scripts that invoke Ansible must pass `-e enable_wifi=<yes|no>`.

The Makefile help text should mention `ENABLE_WIFI=yes` in the relevant target description or variable documentation.

## 7. Secret Handling

`ENABLE_WIFI=yes` must never carry network credentials.

Docs may explain that live ISO NetworkManager connection profiles can contain secrets and must be handled as sensitive local target state. The project must not commit or log real `.nmconnection` files containing WiFi credentials.

If a future workflow copies live ISO WiFi profiles into the installed target, that must be a separate OpenSpec change or a clearly documented manual recovery action with secret-safe logging.

## 8. Documentation

Add `docs/installed-wifi-policy.md` explaining:

- what `ENABLE_WIFI=yes` installs,
- when to use it,
- how it differs from live ISO WiFi bootstrap,
- how to run the Makefile targets,
- why WiFi secrets are not documented,
- failure modes and recovery.

Update existing package/baseline/config docs so the target baseline mentions optional installed WiFi.

## 9. Review Checklist

- `ENABLE_WIFI` defaults to `no`.
- No WiFi secrets are documented or logged.
- WiFi packages are installed only when requested.
- NetworkManager WiFi USE is enabled only when requested.
- wpa_supplicant D-Bus support is enabled when requested.
- Final checks are read-only.
- No destructive installer behavior changes.
