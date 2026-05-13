# Design: implement-ansible-final-checks-and-reboot-readiness

## Checks
Validate fstab UUIDs, kernel artifacts, GRUB config, EFI files, enabled networking, users, hostname, and target root identity.

Hostname, timezone, locale, and keymap validation should use the state configured by `common/locale_timezone_hostname` and may reference `logs/install-runs/<run-id>/system-config/identity.json` as install evidence. Final checks must still verify the current target files under `/mnt/gentoo` instead of trusting evidence alone.

## Output
Produce a structured reboot readiness report and do not reboot automatically.
