## ADDED Requirements

### Requirement: libvirt/virsh Manual Install Test Environment
The project SHALL provide a libvirt/virsh-managed local VM environment for rehearsing Gentoo installation flows from the official Gentoo live ISO without touching host block devices.

#### Scenario: Check libvirt prerequisites
- **WHEN** the operator runs `make vm-check`
- **THEN** the workflow SHALL verify required host tools, libvirt connectivity, official ISO resolution, UEFI availability, network mode configuration, and safe project-local paths
- **AND** the workflow SHALL use `qemu:///system` by default
- **AND** the workflow SHALL be read-only and SHALL NOT create domains, disks, NVRAM files, or artifact directories

#### Scenario: Create the VM disk
- **WHEN** the operator runs `make vm-disk`
- **THEN** the workflow SHALL create the configured project-local artifact directory if missing
- **AND** the workflow SHALL create a qcow2 disk if missing
- **AND** the workflow SHALL preserve an existing qcow2 disk
- **AND** the workflow SHALL reject an existing disk file that is not qcow2

#### Scenario: Define the libvirt domain
- **WHEN** the operator runs `make vm-define`
- **THEN** the workflow SHALL define only the configured libvirt domain
- **AND** the domain SHALL include a project ownership marker
- **AND** the domain SHALL boot the official Gentoo live ISO
- **AND** the domain SHALL use the official kernel and initrd extracted from the ISO for direct kernel boot with serial console arguments
- **AND** the domain SHALL attach the project-local qcow2 disk as virtio storage
- **AND** the domain SHALL use OVMF UEFI pflash firmware with per-VM NVRAM
- **AND** the domain SHALL include a serial console
- **AND** the domain SHALL use managed libvirt networking with the default network
- **AND** the domain SHALL use user-mode networking only when explicitly configured
- **AND** the domain SHALL NOT be configured for autostart by default
- **AND** the workflow SHALL NOT modify the ISO or build a custom ISO

#### Scenario: Refuse unrelated existing domain
- **WHEN** a libvirt domain already exists with the configured VM name
- **THEN** the workflow SHALL inspect the existing domain before redefining, destroying, or cleaning it
- **AND** start, SSH, rsync, Ansible, console, viewer, and IP-discovery workflows SHALL fail if the domain does not carry the project ownership marker or does not match the configured official ISO and generated project-local artifacts
- **AND** cleanup, shutdown, destroy, and redefine workflows MAY operate on stale project-marked domains only when those domains do not reference host block devices

#### Scenario: Start and inspect the VM
- **WHEN** the operator runs `make vm-start`
- **THEN** the workflow SHALL start the configured libvirt domain
- **AND** the domain SHALL be project-owned, configured with OVMF UEFI firmware, and matched to the configured official ISO and generated project-local artifacts before it starts
- **AND** the workflow SHALL NOT partition, format, install Gentoo, configure Portage, create users, or install a bootloader automatically

#### Scenario: Access console
- **WHEN** the operator runs `make vm-console`
- **THEN** the workflow SHALL attach to the configured domain console through `virsh`
- **AND** the official live ISO SHALL expose boot output and a root prompt on the serial console through the generated kernel command line

#### Scenario: Access graphical console
- **WHEN** the operator runs `make vm-viewer`
- **THEN** the workflow SHALL open graphical VM access through a Makefile-mediated libvirt viewer command
- **AND** the workflow SHALL fail with documented guidance if the viewer tool is unavailable

#### Scenario: Discover guest IP
- **WHEN** the operator runs `make vm-ip`
- **THEN** the workflow SHALL discover the guest IP through libvirt guest agent data or DHCP lease data when managed network discovery is available
- **AND** any DHCP lease fallback SHALL be filtered by the configured domain MAC address
- **AND** the workflow SHALL fail clearly when no IP can be discovered or when the selected network mode does not support lease discovery
- **AND** the workflow SHALL point operators to the discovered SSH endpoint in default managed networking

#### Scenario: Connect by SSH
- **WHEN** the operator runs `make vm-ssh`
- **THEN** the workflow SHALL connect to the guest through the configured discovered SSH endpoint or discovered guest IP only after SSH is reachable
- **AND** the configured libvirt domain SHALL be project-owned, UEFI-configured, matched to generated project-local artifacts, and running before the workflow connects
- **AND** the workflow SHALL fail clearly when SSH has not been enabled inside the official live ISO
- **AND** the workflow SHALL NOT commit or require committed passwords, tokens, or private SSH keys

#### Scenario: Bootstrap temporary live ISO SSH
- **WHEN** the operator runs `make vm-bootstrap-ssh`
- **THEN** the workflow SHALL use the serial console to install an operator public key into the temporary live ISO session
- **AND** the workflow SHALL start `sshd` inside the live ISO
- **AND** the workflow SHALL NOT write private keys, passwords, or tokens into the repository

#### Scenario: Validate Ansible connectivity
- **WHEN** the operator runs `make vm-ansible-ping`
- **THEN** the workflow SHALL discover the guest IP when managed networking is used
- **AND** the workflow SHALL run only an Ansible ping connectivity check against the live ISO
- **AND** the workflow SHALL NOT run Gentoo installer playbooks or mutate the target installation

#### Scenario: Copy files by rsync
- **WHEN** the operator runs `make vm-rsync`
- **THEN** the workflow SHALL copy only documented non-secret project files or artifacts to the guest
- **AND** the configured libvirt domain SHALL be project-owned, UEFI-configured, matched to generated project-local artifacts, and running before the workflow connects
- **AND** the guest destination SHALL remain under `/root/gentoo-ai-installer/`
- **AND** the workflow SHALL NOT copy `.env`, private keys, credentials, tokens, or ignored large artifacts unless a future change explicitly approves a safe exception

#### Scenario: Refuse host block devices
- **WHEN** a configured VM disk path points to `/dev/*` or another host block-device path
- **THEN** the workflow SHALL fail before defining, starting, or cleaning the VM
- **AND** no Makefile target or script SHALL attach host block devices as VM disks

#### Scenario: Refuse unsafe artifact paths
- **WHEN** a configured artifact path contains parent traversal, wildcard characters, option-injection characters, symlinked path components, or resolves to the project root
- **THEN** the workflow SHALL fail before creating, defining, starting, or cleaning VM artifacts
- **AND** generated VM artifacts SHALL remain under the configured project-local artifact directory

#### Scenario: Refuse unsafe network configuration
- **WHEN** the configured network mode, network name, SSH host, or SSH port values are empty, malformed, ambiguous, or contain option-injection characters
- **THEN** the workflow SHALL fail before defining or starting the VM
- **AND** default managed networking SHALL use an explicit validated libvirt network name

#### Scenario: Reject unsupported BIOS boot
- **WHEN** the operator sets `VM_BOOT_MODE=bios`
- **THEN** the workflow SHALL fail before defining or starting the VM
- **AND** the workflow SHALL state that v1 supports UEFI only

#### Scenario: Clean generated libvirt artifacts
- **WHEN** the operator runs `make vm-clean`
- **THEN** the workflow SHALL show the configured domain and generated files that would be removed
- **AND** the workflow SHALL require the operator to type `DELETE`
- **AND** the workflow SHALL undefine or remove only the configured domain
- **AND** the workflow SHALL delete only generated project-local disk, XML, NVRAM, and log artifacts
- **AND** the workflow SHALL NOT delete unrelated libvirt domains, networks, pools, volumes, ISO files, or secrets

#### Scenario: Preserve Ansible phase boundary
- **WHEN** the libvirt VM is running and reachable
- **THEN** the workflow MAY provide SSH and rsync access for future installation rehearsal and Ansible preparation
- **AND** the workflow SHALL NOT run Ansible installer playbooks unless a separate approved implementation change adds that behavior
