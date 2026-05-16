# installed-wifi-policy Specification

## Purpose
TBD - created by archiving change enable-installed-wifi-support-option. Update Purpose after archive.
## Requirements
### Requirement: Optional Installed WiFi Support
The project SHALL provide an explicit installed-system WiFi support option controlled by `ENABLE_WIFI`.

#### Scenario: Default WiFi behavior remains disabled
- **WHEN** `ENABLE_WIFI` is unset or set to `no`
- **THEN** the installed target package policy SHALL preserve the conservative no-WiFi NetworkManager baseline
- **AND** WiFi firmware and supplicant packages SHALL NOT be installed solely by the base console package role

#### Scenario: Enable installed WiFi packages
- **WHEN** `ENABLE_WIFI=yes`
- **THEN** the installed target SHALL include the approved WiFi package set
- **AND** the package set SHALL include `sys-kernel/linux-firmware`
- **AND** the package set SHALL include `net-wireless/wpa_supplicant`
- **AND** Portage MAY install required dependencies such as wireless regulatory data

#### Scenario: Enable NetworkManager WiFi support
- **WHEN** `ENABLE_WIFI=yes`
- **THEN** the target package policy SHALL build `net-misc/networkmanager` with WiFi support
- **AND** it SHALL build `net-wireless/wpa_supplicant` with D-Bus support required by NetworkManager WiFi integration
- **AND** it SHALL keep legacy `tkip` and `wep` support disabled unless a future approved change alters that policy

#### Scenario: Preserve secret safety
- **WHEN** WiFi support is configured
- **THEN** the workflow SHALL NOT require, log, document, commit, or store WiFi passwords, real SSIDs, or secret-bearing NetworkManager connection files

#### Scenario: Validate installed WiFi support
- **WHEN** final checks run with `ENABLE_WIFI=yes`
- **THEN** final checks SHALL verify the approved WiFi packages are installed
- **AND** final checks SHALL remain read-only
- **AND** final checks SHALL NOT print WiFi connection secrets

#### Scenario: Preserve installer safety boundary
- **WHEN** `ENABLE_WIFI` is enabled
- **THEN** the workflow SHALL NOT change partitioning, formatting, mount-over behavior, stage3 extraction, bootloader installation, EFI entries, or destructive confirmation requirements

