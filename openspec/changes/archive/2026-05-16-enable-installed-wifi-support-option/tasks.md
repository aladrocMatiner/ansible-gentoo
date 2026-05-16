# Tasks: enable-installed-wifi-support-option

## OpenSpec
- [x] Create proposal, design, tasks, and spec delta.
- [x] Validate with `openspec validate enable-installed-wifi-support-option --strict`.
- [x] Validate with `openspec validate --all --strict`.

## Implementation
- [x] Add `ENABLE_WIFI` to `config/install-schema.yml`.
- [x] Validate and report `ENABLE_WIFI` in `scripts/config-check.sh`.
- [x] Pass `ENABLE_WIFI` through package, final-check, and full install wrapper scripts.
- [x] Add WiFi package and package.use variables to `ansible/group_vars/all.yml`.
- [x] Update `ansible/roles/common/package_install` to install WiFi support only when requested.
- [x] Update `ansible/roles/common/final_checks` to validate WiFi support when requested.
- [x] Ensure all changes reuse shared package/final-check roles and do not add init-specific duplication.

## Documentation
- [x] Add `docs/installed-wifi-policy.md`.
- [x] Update `docs/install-configuration.md`.
- [x] Update `docs/ansible-system-packages-and-services.md`.
- [x] Update `docs/target-system-baseline.md`.
- [x] Update relevant skills and Makefile documentation.

## Validation
- [x] Run `make config-check ENABLE_WIFI=yes`.
- [x] Run `make ansible-check`.
- [x] Run `openspec validate enable-installed-wifi-support-option --strict`.
- [x] Run `openspec validate --all --strict`.

## Review Checklist
- [x] Confirm `ENABLE_WIFI=no` preserves existing package policy.
- [x] Confirm `ENABLE_WIFI=yes` adds firmware, supplicant, NetworkManager WiFi support, and wpa_supplicant D-Bus support.
- [x] Confirm no WiFi secrets are logged or documented.
- [x] Confirm no disk, filesystem, stage3, bootloader, or EFI logic changed.
