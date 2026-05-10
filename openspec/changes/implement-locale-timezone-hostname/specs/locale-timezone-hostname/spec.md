## ADDED Requirements

### Requirement: Locale Timezone Hostname
The project SHALL configure target hostname, timezone, locale, and keymap as part of the shared basic-console install flow.

#### Scenario: Configure target identity
- **WHEN** target system configuration runs
- **THEN** it SHALL configure the target hostname under `/mnt/gentoo`
- **AND** it SHALL NOT rely on changing the live ISO hostname

#### Scenario: Configure locale and timezone
- **WHEN** target system configuration runs
- **THEN** it SHALL configure timezone and locale according to validated variables
- **AND** unsupported or missing required values SHALL fail clearly

#### Scenario: Final validation
- **WHEN** final checks run
- **THEN** they SHALL report hostname, timezone, locale, and keymap status
