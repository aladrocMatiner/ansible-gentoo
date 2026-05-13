# Design: define-installed-time-sync-policy

## Policy

The installed target must have a time synchronization plan.

Recommended policy:

- OpenRC: install and enable `chrony`, unless a later approved change selects another OpenRC-compatible NTP client.
- systemd: use `systemd-timesyncd` when available and appropriate, unless a later approved change selects another systemd-compatible NTP client.

The final package names and service names must be variant data, not duplicated task logic.

## Validation

Final checks should verify:

- expected time-sync package or built-in service exists,
- service is enabled for the selected init system,
- no OpenRC workflow calls `systemctl`,
- no systemd workflow calls `rc-update` or `rc-service`.

## Scope

This change defines policy only. It does not implement package installation or service enablement.

## Documentation

Docs must distinguish live ISO time checks from installed-system time sync.
