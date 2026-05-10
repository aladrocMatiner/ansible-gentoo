SHELL := /usr/bin/env bash

LIBVIRT_URI ?= qemu:///system
VM_NET_MODE ?= network
VM_NAME ?= gentoo-ai-installer
VM_ISO ?= gentoo.iso
VM_DIR ?= var/libvirt
VM_DISK ?= $(VM_DIR)/gentoo-ai-installer.qcow2
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
ENABLE_SSH ?= no
TARGET_MOUNT ?= /mnt/gentoo
EFI_MOUNT ?= $(TARGET_MOUNT)/boot/efi
CODEX_INSTALL_METHOD ?= npm
I_UNDERSTAND_THIS_WIPES_DISK ?=
PROFILE ?= openrc
FILESYSTEM ?= ext4
STAGE3_MIRROR ?= https://distfiles.gentoo.org/releases/amd64/autobuilds
STAGE3_CACHE_DIR ?= /tmp/gentoo-ai-installer/stage3
PORTAGE_GENTOO_MIRRORS ?= https://distfiles.gentoo.org

export LIBVIRT_URI
export VM_NET_MODE
export VM_NAME
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
export ENABLE_SSH
export TARGET_MOUNT
export EFI_MOUNT
export CODEX_INSTALL_METHOD
export I_UNDERSTAND_THIS_WIPES_DISK
export PROFILE
export FILESYSTEM
export STAGE3_MIRROR
export STAGE3_CACHE_DIR
export PORTAGE_GENTOO_MIRRORS
export INSTALL_DISK

.PHONY: help \
	vm-check vm-disk vm-define vm-start vm-console vm-viewer vm-ip vm-bootstrap-ssh vm-ssh vm-rsync vm-ansible-ping vm-shutdown vm-destroy vm-clean \
	ansible-check config-check secret-check ansible-live-ping ansible-live-preflight detect-disks install-plan partition-plan mount-plan filesystem-plan destructive-safety-check partition format mount-target stage3-install prepare-chroot configure-portage configure-system generate-fstab install-kernel install-system-packages install-base-packages \
	qemu-check qemu-disk qemu-boot qemu-clean

help:
	@printf '%s\n' \
		'gentoo-ai-installer targets:' \
		'  make vm-check        Verify libvirt tools, ISO, UEFI, network mode, and safe paths' \
		'  make vm-disk         Create the project-local qcow2 VM disk if missing' \
		'  make vm-define       Generate and define the libvirt domain' \
		'  make vm-start        Start the libvirt VM from the official Gentoo ISO' \
		'  make vm-console      Attach to virsh console for the VM' \
		'  make vm-viewer       Open graphical access with virt-viewer' \
		'  make vm-ip           Discover guest IP when managed networking supports it' \
		'  make vm-bootstrap-ssh Configure SSH authorized_keys and start sshd via serial console' \
		'  make vm-ssh          SSH to the live ISO after SSH is enabled in the guest' \
		'  make vm-rsync        Copy non-secret project files to the guest over SSH' \
		'  make vm-ansible-ping Validate Ansible connectivity to the live ISO over SSH' \
		'  make ansible-check   Verify Ansible tooling, syntax, and lint when available' \
		'  make config-check    Validate installer configuration variables without touching targets' \
		'  make secret-check    Scan tracked and unignored files for high-risk secret patterns' \
		'  make ansible-live-ping Validate Ansible connectivity to a live ISO target over SSH' \
		'  make ansible-live-preflight Run read-only live ISO Ansible preflight over SSH' \
		'  make detect-disks    Run read-only Ansible disk detection against the live ISO target' \
		'  make install-plan    Generate read-only Ansible install plan (PROFILE=openrc|systemd FILESYSTEM=ext4|btrfs)' \
		'  make partition-plan  Generate read-only partition plan (requires INSTALL_DISK)' \
		'  make mount-plan      Generate read-only mount plan (requires INSTALL_DISK)' \
		'  make filesystem-plan Generate read-only filesystem format plan (requires INSTALL_DISK)' \
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
		'  LIBVIRT_URI=$(LIBVIRT_URI)' \
		'  VM_NET_MODE=$(VM_NET_MODE)' \
		'  VM_NAME=$(VM_NAME)' \
		'  VM_ISO=$(VM_ISO)' \
		'  VM_DIR=$(VM_DIR)' \
		'  VM_DISK=$(VM_DISK)' \
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
		'  ENABLE_SSH=$(ENABLE_SSH)' \
		'  TARGET_MOUNT=$(TARGET_MOUNT)' \
		'  EFI_MOUNT=$(EFI_MOUNT)' \
		'  CODEX_INSTALL_METHOD=$(CODEX_INSTALL_METHOD)' \
		'  PROFILE=$(PROFILE)' \
		'  FILESYSTEM=$(FILESYSTEM)' \
		'  STAGE3_MIRROR=$(STAGE3_MIRROR)' \
		'  STAGE3_CACHE_DIR=$(STAGE3_CACHE_DIR)' \
		'  PORTAGE_GENTOO_MIRRORS=$(PORTAGE_GENTOO_MIRRORS)' \
		'  INSTALL_DISK has no default; pass INSTALL_DISK=/dev/vda only deliberately inside the VM'

vm-check:
	@scripts/vm-check-libvirt.sh

vm-disk:
	@scripts/vm-create-disk.sh

vm-define:
	@scripts/vm-define-libvirt-domain.sh

vm-start:
	@scripts/vm-start.sh

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

secret-check:
	@scripts/secret-check.sh

ansible-live-ping:
	@scripts/ansible-live-ping.sh

ansible-live-preflight:
	@scripts/ansible-live-preflight.sh

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
