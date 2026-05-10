# Design: implement-install-report-summary

## Report Contents

Include:

- run id,
- profile/init system,
- filesystem,
- boot mode,
- target disk identity,
- partitions and mountpoints,
- filesystem UUIDs,
- hostname/timezone/locale,
- admin user summary without secrets,
- SSH status if enabled,
- NetworkManager status,
- kernel and bootloader status,
- final checks result,
- audit bundle path,
- first-boot validation status when available,
- next recommended action.

## Output

The report should be readable in terminal and optionally written under the run log directory.

## Safety

Do not include passwords, password hashes, private keys, tokens, or local credentials.

## Makefile Integration

Planned target:

```sh
make install-report
```
