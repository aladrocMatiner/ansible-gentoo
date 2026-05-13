## Why

As state, logs, audit bundles, VM artifacts, and installer outputs grow, cleanup needs strict rules. Operators need to know what cleanup deletes, what it preserves, and how to reset safely.

## What Changes

- Define cleanup/reset scopes for VM artifacts, logs, state, audit bundles, downloaded stage3 artifacts, and temporary live secrets.
- Include download cache cleanup behavior from the download cache/mirror policy.
- Require explicit confirmation for deleting generated artifacts.
- Never delete host block devices or arbitrary paths.
- Preserve audit evidence by default unless explicit cleanup scope includes it.

## Capabilities

### New Capabilities
- `cleanup-reset-policy`: Defines safe cleanup and reset behavior for project-generated artifacts.

### Modified Capabilities

## Impact

- Makefile cleanup targets, VM docs, state/audit docs, secret cleanup.
