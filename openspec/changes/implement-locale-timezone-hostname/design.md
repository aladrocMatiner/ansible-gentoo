# Design: implement-locale-timezone-hostname

## Variables

Planned variables:

- `HOSTNAME` / `hostname`, default `gentoo`.
- `TIMEZONE` / `timezone`, explicit or documented default.
- `LOCALE` / `locale`, explicit or documented default such as `en_US.UTF-8`.
- `KEYMAP` / `keymap`, optional based on install context.

Any defaults must be documented in the configuration schema.

## Handbook Alignment

This maps to the Gentoo AMD64 Handbook system configuration steps for timezone, locale, and hostname. Automation may write files directly when that is more idempotent than shell commands, but final state must match Handbook intent.

Minimal stage3 variants may not contain the requested timezone data before additional packages are installed. The shared role should install `sys-libs/timezone-data` inside the target root when the selected timezone file is missing, then revalidate the target `/usr/share/zoneinfo` path before linking `/etc/localtime`.

Musl stage3 variants may not provide `/usr/sbin/locale-gen`. The shared role should still write `locale.gen` and `02locale`, but locale generation must be conditional on the helper existing in the target root. Evidence should record whether `locale-gen` was available and whether it ran.

## Safety

- Do not write outside `/mnt/gentoo`.
- Validate hostname format.
- Do not overwrite unrelated local host settings.
- Do not change the live ISO hostname as a substitute for target configuration.

## Validation

Final checks should report hostname, timezone, locale, and keymap status.
