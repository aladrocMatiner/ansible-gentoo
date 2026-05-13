# install-configuration-schema Specification

## Purpose
TBD - created by archiving change define-install-configuration-schema. Update Purpose after archive.
## Requirements
### Requirement: Install Configuration Schema
The project SHALL maintain a canonical schema for installer variables shared by Makefile targets, scripts, and Ansible roles.

#### Scenario: No default install disk
- **WHEN** the schema is evaluated
- **THEN** `INSTALL_DISK` / `install_disk` SHALL have no default value
- **AND** destructive workflows SHALL require it explicitly

#### Scenario: Allowed values
- **WHEN** configuration is validated
- **THEN** `PROFILE`, `FILESYSTEM`, and `BOOT_MODE` SHALL be checked against documented allowed values
- **AND** unsupported values SHALL fail before installer tasks run

#### Scenario: Makefile to Ansible mapping
- **WHEN** a Makefile target invokes Ansible
- **THEN** variables SHALL map to the canonical Ansible variable names defined by the schema

#### Scenario: Documentation
- **WHEN** variables are added or changed
- **THEN** the schema, docs, Makefile help, and relevant skills SHALL be updated in the same change

