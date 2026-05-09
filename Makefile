SHELL := /usr/bin/env bash

QEMU_ISO ?= gentoo.iso
QEMU_DIR ?= var/qemu
QEMU_DISK ?= $(QEMU_DIR)/gentoo-test.qcow2
QEMU_DISK_SIZE ?= 40G
QEMU_RAM ?= 4096
QEMU_CPUS ?= 2
QEMU_BOOT_MODE ?= uefi
QEMU_OVMF_CODE ?=
QEMU_OVMF_VARS ?=

export QEMU_ISO
export QEMU_DIR
export QEMU_DISK
export QEMU_DISK_SIZE
export QEMU_RAM
export QEMU_CPUS
export QEMU_BOOT_MODE
export QEMU_OVMF_CODE
export QEMU_OVMF_VARS

.PHONY: help qemu-check qemu-disk qemu-boot qemu-clean

help:
	@printf '%s\n' \
		'gentoo-ai-installer targets:' \
		'  make qemu-check      Verify QEMU tools, ISO, boot mode, and safe paths' \
		'  make qemu-disk       Create the qcow2 test disk if missing' \
		'  make qemu-boot       Boot the official Gentoo live ISO in QEMU' \
		'  make qemu-clean      Delete generated QEMU artifacts after confirmation' \
		'' \
		'QEMU variables:' \
		'  QEMU_ISO=$(QEMU_ISO)' \
		'  QEMU_DIR=$(QEMU_DIR)' \
		'  QEMU_DISK=$(QEMU_DISK)' \
		'  QEMU_DISK_SIZE=$(QEMU_DISK_SIZE)' \
		'  QEMU_RAM=$(QEMU_RAM)' \
		'  QEMU_CPUS=$(QEMU_CPUS)' \
		'  QEMU_BOOT_MODE=$(QEMU_BOOT_MODE)'

qemu-check:
	@QEMU_CHECK_ONLY=1 scripts/qemu-boot-gentoo-iso.sh

qemu-disk:
	@scripts/qemu-create-disk.sh

qemu-boot: qemu-disk
	@scripts/qemu-boot-gentoo-iso.sh

qemu-clean:
	@bash -euo pipefail -c '\
		qemu_dir="$${QEMU_DIR}"; \
		qemu_disk="$${QEMU_DISK}"; \
		normalize_relative_dir() { \
			local path="$$1"; \
			while [[ "$$path" == ./* ]]; do path="$${path#./}"; done; \
			while [[ "$$path" == *"/./"* ]]; do path="$${path//\/.\//\/}"; done; \
			while [[ "$$path" == *"//"* ]]; do path="$${path//\/\//\/}"; done; \
			while [[ "$$path" != "/" && "$$path" == */. ]]; do path="$${path%/.}"; done; \
			while [[ "$$path" != "." && "$$path" == */ ]]; do path="$${path%/}"; done; \
			if [[ -z "$$path" || "$$path" == "/" ]]; then path="."; fi; \
			printf "%s\n" "$$path"; \
		}; \
		normalize_project_path() { \
			local path="$$1"; \
			if [[ "$$path" = /* ]]; then \
				:; \
			else \
				path="$$PWD/$$path"; \
			fi; \
			while [[ "$$path" == *"/./"* ]]; do path="$${path//\/.\//\/}"; done; \
			while [[ "$$path" == *"//"* ]]; do path="$${path//\/\//\/}"; done; \
			while [[ "$$path" != "/" && "$$path" == */. ]]; do path="$${path%/.}"; done; \
			while [[ "$$path" != "/" && "$$path" == */ ]]; do path="$${path%/}"; done; \
			printf "%s\n" "$$path"; \
		}; \
		reject_symlink_components() { \
			local path="$$1"; \
			local current=""; \
			local component; \
			IFS=/ read -ra components <<< "$$path"; \
			for component in "$${components[@]}"; do \
				[[ -n "$$component" && "$$component" != "." ]] || continue; \
				if [[ -z "$$current" ]]; then current="$$component"; else current="$$current/$$component"; fi; \
				if [[ -L "$$current" ]]; then \
					printf "Refusing symlink path component: %s\n" "$$current" >&2; exit 1; \
				fi; \
			done; \
		}; \
		assert_qcow2_image() { \
			local disk="$$1"; \
			local line; \
			while IFS= read -r line; do \
				if [[ "$$line" == "file format: qcow2" ]]; then return 0; fi; \
			done < <(qemu-img info -- "$$disk" 2>/dev/null); \
			printf "Refusing non-qcow2 QEMU_DISK during cleanup: %s\n" "$$disk" >&2; exit 1; \
		}; \
		validate_qemu_disk() { \
			local disk="$$1"; \
			local disk_parent; \
			local abs_dir; \
			local abs_disk; \
			case "$$disk" in ""|/*|*".."*|"/dev"|"/dev/"*|*"*"*|*"?"*|*"["*|*","*) \
				printf "Refusing unsafe QEMU_DISK: %s\n" "$$disk" >&2; exit 1 ;; \
			esac; \
			case "$$disk" in *.qcow2) ;; *) printf "Refusing non-qcow2 QEMU_DISK: %s\n" "$$disk" >&2; exit 1 ;; esac; \
			disk_parent=$$(dirname -- "$$disk"); \
			reject_symlink_components "$$disk_parent"; \
			if [[ -L "$$disk" ]]; then \
				printf "Refusing symlink QEMU_DISK: %s\n" "$$disk" >&2; exit 1; \
			fi; \
			abs_dir=$$(normalize_project_path "$$qemu_dir"); \
			abs_disk=$$(normalize_project_path "$$disk"); \
			case "$$abs_disk" in "$$abs_dir"/*) ;; \
				*) printf "Refusing QEMU_DISK outside QEMU_DIR: %s\n" "$$disk" >&2; exit 1 ;; \
			esac; \
		}; \
		case "$$qemu_dir" in ""|"."|"/"|/*|*".."*|"/dev"|"/dev/"*|*"*"*|*"?"*|*"["*|*","*) \
			printf "Refusing unsafe QEMU_DIR: %s\n" "$$qemu_dir" >&2; exit 1 ;; \
		esac; \
		qemu_dir=$$(normalize_relative_dir "$$qemu_dir"); \
		case "$$qemu_dir" in ""|"."|"/") \
			printf "Refusing project-root QEMU_DIR: %s\n" "$${QEMU_DIR}" >&2; exit 1 ;; \
		esac; \
		if [[ -L "$$qemu_dir" ]]; then \
			printf "Refusing symlink QEMU_DIR: %s\n" "$$qemu_dir" >&2; exit 1; \
		fi; \
		reject_symlink_components "$$qemu_dir"; \
		validate_qemu_disk "$$qemu_disk"; \
		if [[ ! -d "$$qemu_dir" ]]; then \
			printf "No QEMU directory to clean: %s\n" "$$qemu_dir"; exit 0; \
		fi; \
		files=(); \
		if [[ -f "$$qemu_disk" ]]; then assert_qcow2_image "$$qemu_disk"; files+=("$$qemu_disk"); fi; \
		ovmf_vars="$$qemu_dir/gentoo-test-OVMF_VARS.fd"; \
		if [[ -L "$$ovmf_vars" ]]; then \
			printf "Refusing symlink per-VM OVMF vars file: %s\n" "$$ovmf_vars" >&2; exit 1; \
		fi; \
		if [[ -e "$$ovmf_vars" && ! -f "$$ovmf_vars" ]]; then \
			printf "Refusing non-regular per-VM OVMF vars path: %s\n" "$$ovmf_vars" >&2; exit 1; \
		fi; \
		if [[ -f "$$ovmf_vars" ]]; then files+=("$$ovmf_vars"); fi; \
		if (( $${#files[@]} == 0 )); then \
			printf "No generated QEMU disk or firmware variable files found under %s\n" "$$qemu_dir"; exit 0; \
		fi; \
		printf "qemu-clean will delete only these files under %s:\n" "$$qemu_dir"; \
		printf "  %s\n" "$${files[@]}"; \
		printf "Type DELETE to remove these files: "; \
		read -r confirmation; \
		if [[ "$$confirmation" != "DELETE" ]]; then \
			printf "qemu-clean cancelled.\n"; exit 1; \
		fi; \
		rm -f -- "$${files[@]}"; \
		printf "Removed %s generated QEMU artifact(s).\n" "$${#files[@]}"; \
	'
