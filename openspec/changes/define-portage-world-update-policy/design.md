# Design: define-portage-world-update-policy

## Recommended v1 Policy

- Run official Gentoo repository sync through documented logic.
- Do not run a broad `emerge -avuDN @world` by default in v1 unless a later approved change explicitly adds it.
- Install required baseline packages explicitly.
- Detect pending configuration file updates after package operations.
- Fail or warn clearly if config file updates require manual review.

## Rationale

The goal is a simple reproducible basic-console install, not a maximal update/tuning workflow. A broad world update increases time, variability, and failure surface.

## Config File Updates

The project must define how it handles updates normally handled by `etc-update` or `dispatch-conf`. In v1, unattended merging should be conservative and avoid overwriting local changes without review.

## Evidence

Portage sync, package install, world update skip/perform status, and config-update status must be logged and included in final audit/report output.
