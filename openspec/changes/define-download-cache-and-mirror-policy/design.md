# Design: define-download-cache-and-mirror-policy

## Cache Location

Downloads should use project-local paths when running from the project, such as:

```text
var/cache/downloads/
var/cache/stage3/
```

The exact layout may differ for live ISO local execution, but it must be documented and must not write to arbitrary host paths.

## Mirror Policy

- Prefer official Gentoo metadata and mirrors.
- Allow documented mirror override variables.
- Validate mirror URLs when possible.
- Do not silently use unverified local files.

## Partial Files

Downloads should use temporary filenames and only promote completed verified artifacts to cache paths.

## Verification

Cached stage3 artifacts are reusable only when checksum/signature policy still passes. Cache presence does not replace verification.

## Cleanup

Cleanup/reset policy must define whether cached downloads are preserved or removed. Deleting cached files must stay under project-local cache paths.
