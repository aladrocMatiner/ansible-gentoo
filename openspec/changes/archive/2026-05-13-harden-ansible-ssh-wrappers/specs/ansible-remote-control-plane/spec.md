## ADDED Requirements

### Requirement: Hardened Ansible SSH Wrapper Transport
Controller-to-live-ISO Ansible wrappers SHALL use a shared, documented SSH transport policy for connection timeout, keepalive, control connection reuse, and temporary live ISO host-key handling.

#### Scenario: Wrapper builds SSH options from shared policy
- **WHEN** a Makefile-mediated Ansible wrapper connects to an official Gentoo live ISO target over SSH
- **THEN** the wrapper SHALL obtain its SSH common arguments from a shared helper or equivalent single policy point
- **AND** it SHALL NOT duplicate incompatible hard-coded SSH option strings across wrapper scripts

#### Scenario: Operator tunes SSH timeouts through Makefile variables
- **WHEN** the operator sets `ANSIBLE_SSH_CONNECT_TIMEOUT`, `ANSIBLE_SSH_SERVER_ALIVE_INTERVAL`, `ANSIBLE_SSH_SERVER_ALIVE_COUNT_MAX`, `ANSIBLE_SSH_CONTROL_MASTER`, `ANSIBLE_SSH_CONTROL_PERSIST`, or `ANSIBLE_SSH_CONTROL_PATH_DIR`
- **THEN** Makefile-mediated Ansible wrappers SHALL apply those values to controller-to-live-ISO SSH connections
- **AND** invalid values SHALL fail before invoking Ansible

#### Scenario: Default SSH transport values are consistent
- **WHEN** the operator does not override SSH transport variables
- **THEN** Makefile-mediated Ansible wrappers SHALL use `ANSIBLE_SSH_CONNECT_TIMEOUT=10`, `ANSIBLE_SSH_SERVER_ALIVE_INTERVAL=30`, `ANSIBLE_SSH_SERVER_ALIVE_COUNT_MAX=6`, `ANSIBLE_SSH_CONTROL_MASTER=auto`, `ANSIBLE_SSH_CONTROL_PERSIST=10m`, and `ANSIBLE_SSH_CONTROL_PATH_DIR=var/ssh-control`
- **AND** control socket paths SHALL remain project-local

#### Scenario: Temporary live ISO host keys remain scoped
- **WHEN** a wrapper connects to a temporary official Gentoo live ISO target
- **THEN** it MAY disable strict host-key persistence for that wrapper invocation
- **AND** global `ansible.cfg` SHALL NOT disable host-key checking for unrelated Ansible workflows

#### Scenario: Long install guidance is documented
- **WHEN** documentation describes long-running install targets
- **THEN** it SHALL recommend running the controller-side Makefile command inside `tmux` or `screen`
- **AND** it SHALL explain that this protects the operator-to-controller session but does not replace controller-to-target SSH keepalives or resumable install phases

#### Scenario: Local libvirt and network targets share transport policy
- **WHEN** `ANSIBLE_LIVE_HOST` points at a real network live ISO target or is discovered from the local libvirt harness
- **THEN** Ansible wrapper SSH transport options SHALL be applied consistently
- **AND** reusable Ansible roles SHALL NOT depend on libvirt-specific SSH discovery
