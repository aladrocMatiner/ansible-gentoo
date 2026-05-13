## Why

Stage3 downloads, Gentoo metadata, Portage syncs, and future package operations need predictable mirror/cache behavior. The project should define where downloads go, how retries and partial files are handled, and how evidence is logged.

## What Changes

- Define a project-local download/cache policy.
- Define official mirror usage and operator override rules.
- Define checksum/signature behavior for cached stage3 artifacts.
- Define cleanup boundaries for cached files.
- Require audit evidence for downloaded artifacts.

## Capabilities

### New Capabilities
- `download-cache-mirror`: Defines cache paths, mirror policy, retry behavior, and artifact verification expectations.

### Modified Capabilities

## Impact

- Stage3 install.
- Portage baseline.
- Audit bundle.
- Cleanup/reset policy.
- Config validation.
- Docs and skills.
