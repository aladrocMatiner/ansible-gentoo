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

## Safety

- Do not write outside `/mnt/gentoo`.
- Validate hostname format.
- Do not overwrite unrelated local host settings.
- Do not change the live ISO hostname as a substitute for target configuration.

## Validation

Final checks should report hostname, timezone, locale, and keymap status.
