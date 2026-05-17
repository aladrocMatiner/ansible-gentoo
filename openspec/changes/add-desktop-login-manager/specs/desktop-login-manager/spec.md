## ADDED Requirements

### Requirement: Optional Post-Install Desktop Login Manager
The project SHALL provide an optional post-install desktop login manager workflow for already installed Gentoo systems.

#### Scenario: Login manager workflow targets installed system
- **WHEN** the desktop login manager workflow runs
- **THEN** it SHALL connect to an installed Gentoo target over SSH
- **AND** it SHALL fail if the target appears to be the official Gentoo live ISO, a mounted chroot, or an unfinished installation environment

#### Scenario: Login manager workflow uses Makefile
- **WHEN** an operator plans, installs, or validates desktop login manager state
- **THEN** the operation SHALL be exposed through Makefile targets
- **AND** the operator SHALL NOT need to run undocumented ad-hoc Ansible commands or package commands

#### Scenario: Default remains no login manager
- **WHEN** no login manager is explicitly selected
- **THEN** `DESKTOP_DISPLAY_MANAGER` SHALL default to `none`
- **AND** existing desktop profile workflows SHALL continue to validate the no-display-manager state

### Requirement: Desktop Login Manager Planning
The project SHALL provide a read-only plan for desktop login manager changes.

#### Scenario: Plan reports intended login manager state
- **WHEN** `make desktop-login-plan` runs
- **THEN** it SHALL validate target, user, package-policy, init-system, display-manager, and requested-session inputs
- **AND** it SHALL report packages, managed paths, session entries, service changes, and confirmations that would be required
- **AND** it SHALL NOT mutate the installed target

#### Scenario: Plan rejects unsupported manager
- **WHEN** `DESKTOP_DISPLAY_MANAGER` is not `none` or `greetd`
- **THEN** the plan SHALL fail with an actionable unsupported-display-manager error

### Requirement: Greetd Login Manager Profile
The project SHALL support `greetd` as the first implemented desktop login manager profile.

#### Scenario: Install greetd with explicit confirmation
- **WHEN** `make desktop-login-install` runs with `DESKTOP_DISPLAY_MANAGER=greetd`
- **THEN** it SHALL require `I_UNDERSTAND_DESKTOP_LOGIN_MANAGER_CHANGES=yes`
- **AND** it SHALL install only packages available through the documented Gentoo package policy
- **AND** it SHALL fail closed when required package atoms are unavailable

#### Scenario: Greetd service enablement and start are explicit
- **WHEN** `DESKTOP_LOGIN_ENABLE_SERVICE=yes`
- **THEN** the workflow SHALL enable the `greetd` service for boot only after explicit confirmation
- **AND** the workflow SHALL start the `greetd` service immediately only after explicit confirmation
- **AND** it SHALL document the persistent boot behavior change before applying it

#### Scenario: Autologin is not configured
- **WHEN** the `greetd` profile is installed
- **THEN** it SHALL NOT configure autologin
- **AND** it SHALL NOT store passwords, tokens, SSH keys, or other credentials

### Requirement: Desktop Login Sessions
The project SHALL generate login sessions only for allowlisted installed desktop profiles.

#### Scenario: Allowlisted sessions are generated
- **WHEN** login manager session entries are requested
- **THEN** the workflow SHALL support `i3-x11`, `sway-wayland`, `hyprland-wayland`, `niri-wayland`, and `mango-wayland`
- **AND** it SHALL generate system session entries through shared templates rather than duplicating per-profile display-manager logic

#### Scenario: Requested session is unavailable
- **WHEN** a requested session profile is not installed or its required command is unavailable
- **THEN** the workflow SHALL fail closed unless the selected session policy explicitly allows installed-profile auto-detection
- **AND** it SHALL NOT add overlays, keywords, source builds, binary downloads, or alternate repositories to make the profile available

#### Scenario: Session dispatcher is managed centrally
- **WHEN** session entries are generated
- **THEN** they SHALL invoke a project-owned allowlisted dispatcher or equivalent shared launch mechanism
- **AND** launch command mapping SHALL be validated in one shared location

### Requirement: Desktop Login Manager Safety Boundary
The desktop login manager workflow SHALL not perform base installer or destructive operations.

#### Scenario: Installer operations are excluded
- **WHEN** desktop login manager plan, install, or validation runs
- **THEN** it SHALL NOT partition, wipe, format, mount target installation paths, extract stage3, run chroot installation phases, install GRUB, call `efibootmgr`, modify EFI boot entries, modify user passwords, or change SSH authorization

#### Scenario: Managed paths are documented
- **WHEN** the implementation writes login manager or session files
- **THEN** the paths SHALL be documented before release
- **AND** writes SHALL be limited to login-manager config paths, system session-entry paths, and project-owned session dispatcher paths

### Requirement: Desktop Login Manager Validation
The project SHALL provide read-only validation for managed desktop login manager state.

#### Scenario: Validate managed login state
- **WHEN** `make desktop-login-validate` runs
- **THEN** it SHALL verify the selected login manager package, greeter package, config files, session entries, dispatcher, service state, init-specific service command separation, and absence of autologin
- **AND** it SHALL report `changed: false`

#### Scenario: Validate none state
- **WHEN** `DESKTOP_DISPLAY_MANAGER=none`
- **THEN** validation SHALL verify that no project-managed login manager service is enabled by this workflow
- **AND** manual TTY session launch remains the supported fallback
