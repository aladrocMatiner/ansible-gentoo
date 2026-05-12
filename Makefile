SHELL := /usr/bin/env bash

LIBVIRT_URI ?= qemu:///system
VM_NET_MODE ?= network
VM_NAME ?= gentoo-test
VM_TEST_IMAGE_NAME ?=
VM_ISO ?= gentoo.iso
VM_DIR ?= var/libvirt
VM_DISK ?= $(VM_DIR)/gentoo-test.qcow2
VM_DISK_SIZE ?= 40G
VM_RAM ?= 4096
VM_CPUS ?= 2
VM_NETWORK ?= default
VM_SSH_HOST ?= 127.0.0.1
VM_SSH_HOST_PORT ?= 2222
VM_SSH_GUEST_PORT ?= 22
VM_SSH_USER ?= root
VM_BOOT_MODE ?= uefi
VM_KERNEL_ARGS ?= dokeymap nodhcp root=live:CDLABEL=__VM_ISO_LABEL__ rd.live.dir=/ rd.live.squashimg=image.squashfs cdroot console=tty0 console=ttyS0,115200n8
ANSIBLE_LIVE_HOST ?=
ANSIBLE_LIVE_PORT ?= 22
ANSIBLE_LIVE_USER ?= root
BOOT_MODE ?= uefi
HOSTNAME = gentoo
TIMEZONE ?= UTC
LOCALE ?= en_US.UTF-8
KEYMAP ?= us
ADMIN_USER ?=
ADMIN_GROUPS ?= wheel
ADMIN_SHELL ?= /bin/bash
PRIVILEGE_TOOL ?= sudo
ADMIN_SUDO_NOPASSWD ?=
ADMIN_AUTHORIZED_KEYS_FILE ?=
ADMIN_PASSWORD_HASH_FILE ?=
ROOT_PASSWORD_HASH_FILE ?=
ENABLE_SSH ?= no
FIRST_BOOT_USER ?=
FIRST_BOOT_TIMEOUT ?= 180
TARGET_MOUNT ?= /mnt/gentoo
EFI_MOUNT ?= $(TARGET_MOUNT)/boot/efi
CODEX_INSTALL_METHOD ?= npm
I_UNDERSTAND_THIS_WIPES_DISK ?=
I_UNDERSTAND_BOOTLOADER_CHANGES ?=
PROFILE ?= openrc
FILESYSTEM ?= ext4
STAGE3_FLAVOR ?= standard
STAGE3_MIRROR ?= https://distfiles.gentoo.org/releases/amd64/autobuilds
STAGE3_CACHE_DIR ?= /tmp/gentoo-ai-installer/stage3
PORTAGE_GENTOO_MIRRORS ?= https://distfiles.gentoo.org
INSTALL_STATE_FILE ?= var/state/current-install.json
I_UNDERSTAND_DELETE_INSTALL_STATE ?=
I_UNDERSTAND_CLEANUP_DELETE ?=
CLEAN_SCOPE ?= state
CLEAN_RUN_ID ?=
MANUAL_STEP_SUMMARY ?=
MANUAL_STEP_REASON ?=
MANUAL_STEP_NEXT_ACTION ?= Run make install-resume-plan and relevant read-only checks before resuming automation.
REAL_HARDWARE_BACKUPS_CONFIRMED ?= no
REAL_HARDWARE_UEFI_CONFIRMED ?= no
REAL_HARDWARE_NETWORK_CONFIRMED ?= no
REAL_HARDWARE_POWER_CONFIRMED ?= no
REAL_HARDWARE_RECOVERY_MEDIA_CONFIRMED ?= no
REAL_HARDWARE_DESTRUCTIVE_PREVIEW_REVIEWED ?= no
REAL_HARDWARE_LIBVIRT_VALIDATED ?= no
REAL_HARDWARE_LIBVIRT_SKIP_REASON ?=
VM_TEST_MATRIX_LOG_DIR ?= logs/libvirt-matrix
VM_TEST_MATRIX_INSTALL_DISK ?= /dev/vda
VM_TEST_MATRIX_RUN_TARGET_PLANS ?= no
VM_E2E_RESET_DISK ?= no
VM_E2E_ADMIN_SUDO_NOPASSWD ?= yes
VM_E2E_MATRIX_LOG_DIR ?= logs/libvirt-e2e-matrix
VM_E2E_MATRIX_PARALLEL ?= 4

export LIBVIRT_URI
export VM_NET_MODE
export VM_NAME
export VM_TEST_IMAGE_NAME
export VM_ISO
export VM_DIR
export VM_DISK
export VM_DISK_SIZE
export VM_RAM
export VM_CPUS
export VM_NETWORK
export VM_SSH_HOST
export VM_SSH_HOST_PORT
export VM_SSH_GUEST_PORT
export VM_SSH_USER
export VM_BOOT_MODE
export VM_KERNEL_ARGS
export ANSIBLE_LIVE_HOST
export ANSIBLE_LIVE_PORT
export ANSIBLE_LIVE_USER
export BOOT_MODE
export HOSTNAME
export TIMEZONE
export LOCALE
export KEYMAP
export ADMIN_USER
export ADMIN_GROUPS
export ADMIN_SHELL
export PRIVILEGE_TOOL
export ADMIN_SUDO_NOPASSWD
export ADMIN_AUTHORIZED_KEYS_FILE
export ADMIN_PASSWORD_HASH_FILE
export ROOT_PASSWORD_HASH_FILE
export ENABLE_SSH
export FIRST_BOOT_USER
export FIRST_BOOT_TIMEOUT
export TARGET_MOUNT
export EFI_MOUNT
export CODEX_INSTALL_METHOD
export I_UNDERSTAND_THIS_WIPES_DISK
export I_UNDERSTAND_BOOTLOADER_CHANGES
export PROFILE
export FILESYSTEM
export STAGE3_FLAVOR
export STAGE3_MIRROR
export STAGE3_CACHE_DIR
export PORTAGE_GENTOO_MIRRORS
export INSTALL_DISK
export INSTALL_STATE_FILE
export I_UNDERSTAND_DELETE_INSTALL_STATE
export I_UNDERSTAND_CLEANUP_DELETE
export CLEAN_SCOPE
export CLEAN_RUN_ID
export MANUAL_STEP_SUMMARY
export MANUAL_STEP_REASON
export MANUAL_STEP_NEXT_ACTION
export REAL_HARDWARE_BACKUPS_CONFIRMED
export REAL_HARDWARE_UEFI_CONFIRMED
export REAL_HARDWARE_NETWORK_CONFIRMED
export REAL_HARDWARE_POWER_CONFIRMED
export REAL_HARDWARE_RECOVERY_MEDIA_CONFIRMED
export REAL_HARDWARE_DESTRUCTIVE_PREVIEW_REVIEWED
export REAL_HARDWARE_LIBVIRT_VALIDATED
export REAL_HARDWARE_LIBVIRT_SKIP_REASON
export VM_TEST_MATRIX_LOG_DIR
export VM_TEST_MATRIX_INSTALL_DISK
export VM_TEST_MATRIX_RUN_TARGET_PLANS
export VM_E2E_RESET_DISK
export VM_E2E_ADMIN_SUDO_NOPASSWD
export VM_E2E_MATRIX_LOG_DIR
export VM_E2E_MATRIX_PARALLEL

.PHONY: help \
	vm-list-cases vm-check vm-disk vm-define vm-start vm-start-installed vm-validate-first-boot vm-e2e-plan vm-e2e-install vm-e2e-matrix vm-test-matrix vm-test-matrix-plan vm-console vm-viewer vm-ip vm-bootstrap-ssh vm-ssh vm-rsync vm-ansible-ping vm-shutdown vm-destroy vm-clean \
	ansible-check config-check host-check real-hardware-check release-check secret-check handbook-trace ansible-live-ping ansible-live-preflight local-live-preflight local-detect-disks local-install-plan local-partition-plan detect-disks install-plan partition-plan mount-plan filesystem-plan destructive-preview partition-preview format-preview mount-preview bootloader-preview users-preview destructive-safety-check partition format mount-target stage3-install prepare-chroot configure-portage configure-system generate-fstab install-kernel install-system-packages install-base-packages configure-users install-bootloader final-checks install install-openrc install-systemd install-state install-resume-plan record-manual-step install-run-clean install-audit install-report cleanup-plan clean-state clean-logs clean-audit clean-stage3-cache reset-test-run \
	qemu-check qemu-disk qemu-boot qemu-clean

help:
	@printf '%s\n' \
		'gentoo-ai-installer targets:' \
		'  make vm-list-cases   List supported amd64 PROFILE/FILESYSTEM/STAGE3_FLAVOR VM cases and generated artifacts' \
		'  make vm-check        Verify libvirt tools, ISO, UEFI, network mode, and safe paths' \
		'  make vm-disk         Create the project-local qcow2 VM disk if missing' \
		'  make vm-define       Generate and define the libvirt domain' \
		'  make vm-start        Start the libvirt VM from the official Gentoo ISO' \
		'  make vm-start-installed Start the libvirt VM from the installed qcow2 disk' \
		'  make vm-validate-first-boot Boot installed VM and run read-only first-boot validation' \
		'  make vm-e2e-plan     Plan libvirt end-to-end install validation without VM mutation' \
		'  make vm-e2e-install  DESTRUCTIVE-IN-VM: run full disposable VM install validation' \
		'  make vm-e2e-matrix   DESTRUCTIVE-IN-VM: run full disposable install validation for all supported cases' \
		'  make vm-test-matrix-plan Plan OpenRC/systemd x ext4/Btrfs x standard/hardened/musl libvirt matrix' \
		'  make vm-test-matrix Alias for vm-test-matrix-plan' \
		'  make vm-console      Attach to virsh console for the VM' \
		'  make vm-viewer       Open graphical access with virt-viewer' \
		'  make vm-ip           Discover guest IP when managed networking supports it' \
		'  make vm-bootstrap-ssh Configure SSH authorized_keys and start sshd via serial console' \
		'  make vm-ssh          SSH to the live ISO after SSH is enabled in the guest' \
		'  make vm-rsync        Copy non-secret project files to the guest over SSH' \
		'  make vm-ansible-ping Validate Ansible connectivity to the live ISO over SSH' \
		'  make ansible-check   Verify Ansible tooling, syntax, and lint when available' \
		'  make config-check    Validate installer configuration variables without touching targets' \
		'  make host-check      Verify host/libvirt requirements for local VM validation' \
		'  make real-hardware-check Read-only readiness check before physical hardware install' \
		'  make release-check   Run release readiness checks and write local report' \
		'  make secret-check    Scan tracked and unignored files for high-risk secret patterns' \
		'  make handbook-trace  Regenerate Gentoo Handbook traceability report' \
		'  make ansible-live-ping Validate Ansible connectivity to a live ISO target over SSH' \
		'  make ansible-live-preflight Run read-only live ISO Ansible preflight over SSH' \
		'  make local-live-preflight Run read-only preflight locally inside the live ISO fallback mode' \
		'  make local-detect-disks Run read-only disk detection locally inside the live ISO fallback mode' \
		'  make local-install-plan Generate read-only local live ISO install plan' \
		'  make local-partition-plan Generate read-only local live ISO partition plan (requires INSTALL_DISK)' \
		'  make detect-disks    Run read-only Ansible disk detection against the live ISO target' \
		'  make install-plan    Generate read-only Ansible install plan (PROFILE=openrc|systemd FILESYSTEM=ext4|btrfs STAGE3_FLAVOR=standard|hardened|musl)' \
		'  make partition-plan  Generate read-only partition plan (requires INSTALL_DISK)' \
		'  make mount-plan      Generate read-only mount plan (requires INSTALL_DISK)' \
		'  make filesystem-plan Generate read-only filesystem format plan (requires INSTALL_DISK)' \
		'  make destructive-preview Generate read-only preview for PREVIEW_TARGET=partition|format|mount|bootloader|users' \
		'  make partition-preview Read-only preview of destructive partition operation' \
		'  make format-preview  Read-only preview of destructive filesystem operation' \
		'  make mount-preview   Read-only preview of target root/ESP mount-over operation' \
		'  make bootloader-preview Read-only preview of GRUB UEFI bootloader operation' \
		'  make users-preview   Read-only preview of target user/password/SSH access changes' \
		'  make destructive-safety-check Validate shared destructive disk gates without mutating disks' \
		'  make partition      DESTRUCTIVE: apply GPT ESP/root partition layout (requires confirmation)' \
		'  make format         DESTRUCTIVE: create ESP/root filesystems (requires confirmation)' \
		'  make mount-target   Mount formatted target root/ESP for stage3 extraction' \
		'  make stage3-install Download, verify, and extract official Gentoo stage3' \
		'  make prepare-chroot Mount pseudo-filesystems and prepare DNS for chroot tasks' \
		'  make configure-portage Configure minimal Portage baseline and sync official Gentoo repo' \
		'  make configure-system Configure target hostname, timezone, locale, and keymap' \
		'  make generate-fstab Generate UUID-based target /etc/fstab' \
		'  make install-kernel  Install gentoo-kernel-bin and validate /boot artifacts' \
		'  make install-system-packages Install console packages and enable target services' \
		'  make configure-users Configure target admin user, sudo policy, and optional SSH keys' \
		'  make install-bootloader HIGH-RISK: install GRUB for UEFI (requires confirmation)' \
		'  make final-checks    Run read-only reboot readiness checks before manual reboot' \
		'  make install         DESTRUCTIVE: run full basic console install for PROFILE' \
		'  make install-openrc  DESTRUCTIVE: run full OpenRC basic console install' \
		'  make install-systemd DESTRUCTIVE: run full systemd basic console install' \
		'  make install-state   Show current non-secret install state checkpoint summary' \
		'  make install-resume-plan Validate current target facts against saved install state' \
		'  make record-manual-step Record non-secret manual intervention note; requires MANUAL_STEP_SUMMARY and MANUAL_STEP_REASON' \
		'  make install-run-clean Delete current install state pointer after confirmation' \
		'  make install-audit   Generate a secret-safe audit bundle for the current run' \
		'  make install-report  Generate a human-readable secret-safe install summary' \
		'  make cleanup-plan    Show cleanup candidates for CLEAN_SCOPE without deleting' \
		'  make clean-state     Delete current install state pointer after DELETE confirmation' \
		'  make clean-logs      Delete non-audit logs for current or CLEAN_RUN_ID after confirmation' \
		'  make clean-audit     Delete audit bundle for current or CLEAN_RUN_ID after confirmation' \
		'  make clean-stage3-cache Delete approved STAGE3_CACHE_DIR after confirmation' \
		'  make reset-test-run  Delete current state and non-audit logs after confirmation' \
		'  make vm-shutdown     Request clean guest shutdown' \
		'  make vm-destroy      Stop the configured VM without deleting artifacts' \
		'  make vm-clean        Undefine VM and delete generated artifacts after confirmation' \
		'' \
		'Compatibility aliases:' \
		'  make qemu-check      Alias for vm-check' \
		'  make qemu-disk       Alias for vm-disk' \
		'  make qemu-boot       Alias for vm-start' \
		'  make qemu-clean      Alias for vm-clean' \
		'' \
		'VM variables:' \
		'  VM case defaults to amd64-$(PROFILE)-$(FILESYSTEM) using PROFILE=$(PROFILE), FILESYSTEM=$(FILESYSTEM), STAGE3_FLAVOR=$(STAGE3_FLAVOR)' \
		'  LIBVIRT_URI=$(LIBVIRT_URI)' \
		'  VM_NET_MODE=$(VM_NET_MODE)' \
		'  VM_NAME=$(VM_NAME) (base name; VM targets derive <base>[-VM_TEST_IMAGE_NAME]-amd64-PROFILE-FILESYSTEM[-STAGE3_FLAVOR])' \
		'  VM_TEST_IMAGE_NAME=$(VM_TEST_IMAGE_NAME) (optional manual test image label)' \
		'  VM_ISO=$(VM_ISO)' \
		'  VM_DIR=$(VM_DIR)' \
		'  VM_DISK=$(VM_DISK) (VM targets derive a case-specific disk when left at the default)' \
		'  VM_DISK_SIZE=$(VM_DISK_SIZE)' \
		'  VM_RAM=$(VM_RAM)' \
		'  VM_CPUS=$(VM_CPUS)' \
		'  VM_NETWORK=$(VM_NETWORK)' \
		'  VM_SSH_HOST=$(VM_SSH_HOST)' \
		'  VM_SSH_HOST_PORT=$(VM_SSH_HOST_PORT)' \
		'  VM_SSH_GUEST_PORT=$(VM_SSH_GUEST_PORT)' \
		'  VM_SSH_USER=$(VM_SSH_USER)' \
		'  VM_BOOT_MODE=$(VM_BOOT_MODE)' \
		'  VM_KERNEL_ARGS=$(VM_KERNEL_ARGS)' \
		'' \
		'Ansible live ISO target variables:' \
		'  ANSIBLE_LIVE_HOST=$(ANSIBLE_LIVE_HOST) (set for remote/network targets; empty uses local libvirt VM discovery)' \
		'  ANSIBLE_LIVE_PORT=$(ANSIBLE_LIVE_PORT)' \
		'  ANSIBLE_LIVE_USER=$(ANSIBLE_LIVE_USER)' \
		'  BOOT_MODE=$(BOOT_MODE)' \
		'  HOSTNAME=$(HOSTNAME)' \
		'  TIMEZONE=$(TIMEZONE)' \
		'  LOCALE=$(LOCALE)' \
		'  KEYMAP=$(KEYMAP)' \
		'  ADMIN_USER=$(ADMIN_USER)' \
		'  ADMIN_GROUPS=$(ADMIN_GROUPS)' \
		'  ADMIN_SHELL=$(ADMIN_SHELL)' \
		'  PRIVILEGE_TOOL=$(PRIVILEGE_TOOL)' \
		'  ADMIN_SUDO_NOPASSWD=$(if $(ADMIN_SUDO_NOPASSWD),$(ADMIN_SUDO_NOPASSWD),<unset; treated as no outside VM E2E>)' \
		'  ADMIN_AUTHORIZED_KEYS_FILE is optional and not printed' \
		'  ADMIN_PASSWORD_HASH_FILE is optional and not printed' \
		'  ROOT_PASSWORD_HASH_FILE is optional and not printed' \
		'  ENABLE_SSH=$(ENABLE_SSH)' \
		'  FIRST_BOOT_USER=$(FIRST_BOOT_USER)' \
		'  FIRST_BOOT_TIMEOUT=$(FIRST_BOOT_TIMEOUT)' \
		'  TARGET_MOUNT=$(TARGET_MOUNT)' \
		'  EFI_MOUNT=$(EFI_MOUNT)' \
		'  CODEX_INSTALL_METHOD=$(CODEX_INSTALL_METHOD)' \
		'  PROFILE=$(PROFILE)' \
		'  FILESYSTEM=$(FILESYSTEM)' \
		'  STAGE3_FLAVOR=$(STAGE3_FLAVOR)' \
		'  STAGE3_MIRROR=$(STAGE3_MIRROR)' \
		'  STAGE3_CACHE_DIR=$(STAGE3_CACHE_DIR)' \
		'  PORTAGE_GENTOO_MIRRORS=$(PORTAGE_GENTOO_MIRRORS)' \
		'  INSTALL_STATE_FILE=$(INSTALL_STATE_FILE)' \
		'  INSTALL_DISK has no default; pass INSTALL_DISK=/dev/vda only deliberately inside the VM' \
		'  I_UNDERSTAND_BOOTLOADER_CHANGES must be yes for make install-bootloader' \
		'  I_UNDERSTAND_DELETE_INSTALL_STATE must be DELETE for make install-run-clean' \
		'  I_UNDERSTAND_CLEANUP_DELETE must be DELETE for cleanup targets' \
		'  CLEAN_SCOPE=$(CLEAN_SCOPE)' \
		'  CLEAN_RUN_ID=$(CLEAN_RUN_ID)' \
		'  MANUAL_STEP_SUMMARY is required for make record-manual-step and not printed' \
		'  MANUAL_STEP_REASON is required for make record-manual-step and not printed' \
		'  REAL_HARDWARE_* variables default to no; see docs/real-hardware-readiness.md' \
		'  VM_TEST_MATRIX_LOG_DIR=$(VM_TEST_MATRIX_LOG_DIR)' \
		'  VM_TEST_MATRIX_INSTALL_DISK=$(VM_TEST_MATRIX_INSTALL_DISK)' \
		'  VM_TEST_MATRIX_RUN_TARGET_PLANS=$(VM_TEST_MATRIX_RUN_TARGET_PLANS)' \
		'  VM_E2E_RESET_DISK=$(VM_E2E_RESET_DISK)' \
		'  VM_E2E_ADMIN_SUDO_NOPASSWD=$(VM_E2E_ADMIN_SUDO_NOPASSWD)' \
		'  VM_E2E_MATRIX_LOG_DIR=$(VM_E2E_MATRIX_LOG_DIR)' \
		'  VM_E2E_MATRIX_PARALLEL=$(VM_E2E_MATRIX_PARALLEL)'

vm-check:
	@scripts/vm-check-libvirt.sh

vm-list-cases:
	@scripts/vm-list-cases.sh

vm-disk:
	@scripts/vm-create-disk.sh

vm-define:
	@scripts/vm-define-libvirt-domain.sh

vm-start:
	@scripts/vm-start.sh

vm-start-installed:
	@scripts/vm-start-installed.sh

vm-validate-first-boot:
	@scripts/vm-validate-first-boot.sh

vm-e2e-plan:
	@scripts/vm-e2e-plan.py

vm-e2e-install:
	@scripts/vm-e2e-install.sh

vm-e2e-matrix:
	@scripts/vm-e2e-matrix.py

vm-test-matrix: vm-test-matrix-plan

vm-test-matrix-plan:
	@scripts/vm-test-matrix-plan.py

vm-console:
	@scripts/vm-console.sh

vm-viewer:
	@scripts/vm-viewer.sh

vm-ip:
	@scripts/vm-ip.sh

vm-bootstrap-ssh:
	@scripts/vm-bootstrap-live-ssh.py

vm-ssh:
	@scripts/vm-ssh.sh

vm-rsync:
	@scripts/vm-rsync.sh

vm-ansible-ping:
	@scripts/vm-ansible-ping.sh

ansible-check:
	@scripts/ansible-check.sh

config-check:
	@scripts/config-check.sh

host-check:
	@scripts/host-check.sh

real-hardware-check:
	@CONFIG_REQUIRE_INSTALL_DISK=yes scripts/config-check.sh
	@scripts/real-hardware-check.py

release-check:
	@scripts/release-check.py

secret-check:
	@scripts/secret-check.sh

handbook-trace:
	@scripts/handbook-trace.py

ansible-live-ping:
	@scripts/ansible-live-ping.sh

ansible-live-preflight:
	@scripts/ansible-live-preflight.sh

local-live-preflight:
	@scripts/ansible-local-live-preflight.sh

local-detect-disks:
	@scripts/ansible-local-detect-disks.sh

local-install-plan:
	@scripts/ansible-local-install-plan.sh

local-partition-plan:
	@scripts/ansible-local-partition-plan.sh

detect-disks:
	@scripts/ansible-detect-disks.sh

install-plan:
	@scripts/ansible-install-plan.sh

partition-plan:
	@scripts/ansible-partition-plan.sh

mount-plan:
	@scripts/ansible-mount-plan.sh

filesystem-plan:
	@scripts/ansible-filesystem-plan.sh

destructive-preview:
	@scripts/ansible-destructive-preview.sh

partition-preview:
	@PREVIEW_TARGET=partition scripts/ansible-destructive-preview.sh

format-preview:
	@PREVIEW_TARGET=format scripts/ansible-destructive-preview.sh

mount-preview:
	@PREVIEW_TARGET=mount scripts/ansible-destructive-preview.sh

bootloader-preview:
	@PREVIEW_TARGET=bootloader scripts/ansible-destructive-preview.sh

users-preview:
	@PREVIEW_TARGET=users scripts/ansible-destructive-preview.sh

destructive-safety-check:
	@scripts/ansible-destructive-safety-check.sh

partition:
	@scripts/ansible-partition-apply.sh

format:
	@scripts/ansible-filesystem-apply.sh

mount-target:
	@scripts/ansible-mount-target.sh

stage3-install:
	@scripts/ansible-stage3-install.sh

prepare-chroot:
	@scripts/ansible-prepare-chroot.sh

configure-portage:
	@scripts/ansible-configure-portage.sh

configure-system:
	@scripts/ansible-configure-system.sh

generate-fstab:
	@scripts/ansible-generate-fstab.sh

install-kernel:
	@scripts/ansible-install-kernel.sh

install-system-packages:
	@scripts/ansible-install-system-packages.sh

install-base-packages: install-system-packages

configure-users:
	@scripts/ansible-configure-users.sh

install-bootloader:
	@scripts/ansible-install-bootloader.sh

final-checks:
	@scripts/ansible-final-checks.sh

install:
	@scripts/ansible-install-basic-console.sh

install-openrc:
	@PROFILE=openrc scripts/ansible-install-basic-console.sh

install-systemd:
	@PROFILE=systemd scripts/ansible-install-basic-console.sh

install-state:
	@scripts/install-state.py --state-file "$(INSTALL_STATE_FILE)" show

install-resume-plan:
	@scripts/ansible-install-resume-plan.sh

record-manual-step:
	@scripts/record-manual-step.py --state-file "$(INSTALL_STATE_FILE)" record

install-run-clean:
	@scripts/install-state.py --state-file "$(INSTALL_STATE_FILE)" clean --confirm "$(I_UNDERSTAND_DELETE_INSTALL_STATE)"

install-audit:
	@scripts/install-audit-bundle.py --state-file "$(INSTALL_STATE_FILE)" generate

install-report:
	@scripts/install-report.py --state-file "$(INSTALL_STATE_FILE)" generate

cleanup-plan:
	@if [[ "$(CLEAN_SCOPE)" == stage3-cache ]]; then \
		CLEAN_PLAN_ONLY=yes scripts/ansible-clean-stage3-cache.sh; \
	else \
		scripts/cleanup-reset.py --scope "$(CLEAN_SCOPE)" --state-file "$(INSTALL_STATE_FILE)" --run-id "$(CLEAN_RUN_ID)" --stage3-cache-dir "$(STAGE3_CACHE_DIR)" plan; \
	fi

clean-state:
	@scripts/cleanup-reset.py --scope state --state-file "$(INSTALL_STATE_FILE)" --run-id "$(CLEAN_RUN_ID)" --stage3-cache-dir "$(STAGE3_CACHE_DIR)" clean --confirm "$(I_UNDERSTAND_CLEANUP_DELETE)"

clean-logs:
	@scripts/cleanup-reset.py --scope logs --state-file "$(INSTALL_STATE_FILE)" --run-id "$(CLEAN_RUN_ID)" --stage3-cache-dir "$(STAGE3_CACHE_DIR)" clean --confirm "$(I_UNDERSTAND_CLEANUP_DELETE)"

clean-audit:
	@scripts/cleanup-reset.py --scope audit --state-file "$(INSTALL_STATE_FILE)" --run-id "$(CLEAN_RUN_ID)" --stage3-cache-dir "$(STAGE3_CACHE_DIR)" clean --confirm "$(I_UNDERSTAND_CLEANUP_DELETE)"

clean-stage3-cache:
	@scripts/ansible-clean-stage3-cache.sh

reset-test-run:
	@scripts/cleanup-reset.py --scope test-run --state-file "$(INSTALL_STATE_FILE)" --run-id "$(CLEAN_RUN_ID)" --stage3-cache-dir "$(STAGE3_CACHE_DIR)" clean --confirm "$(I_UNDERSTAND_CLEANUP_DELETE)"

vm-shutdown:
	@scripts/vm-shutdown.sh

vm-destroy:
	@scripts/vm-destroy.sh

vm-clean:
	@scripts/vm-clean.sh

qemu-check: vm-check
	@printf '%s\n' 'qemu-check is a compatibility alias; libvirt/virsh vm-check is the active workflow.'

qemu-disk: vm-disk
	@printf '%s\n' 'qemu-disk is a compatibility alias; libvirt/virsh vm-disk is the active workflow.'

qemu-boot: vm-start
	@printf '%s\n' 'qemu-boot is a compatibility alias; libvirt/virsh vm-start is the active workflow.'

qemu-clean: vm-clean
	@printf '%s\n' 'qemu-clean is a compatibility alias; libvirt/virsh vm-clean is the active workflow.'
