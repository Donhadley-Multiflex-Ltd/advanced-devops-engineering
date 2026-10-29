# KVM/libvirt VM lifecycle Makefile for Omarchy (Arch-based) host.
# ISOs: VM_ISO_Images. qcow2 disks: VM_STORAGE_DISK_QCOWs/{debian,rhel}. Run `make help`.
.DEFAULT_GOAL := help
.PHONY: help check setup pools view mem isos list-disks create-disk vm-create cloud-vm rebuild \
        validate ssh list start stop kill reboot console ip snap snap-list snap-revert delete net-up

# ---------- Paths (spaces handled by quoting in every recipe) ----------
ISO_DIR     := /run/media/boye/Extreme SSD/VM_ISO_Images
DISK_ROOT   := /run/media/boye/Extreme SSD/VM_STORAGE_DISK_QCOWs
DEBIAN_DIR  := $(DISK_ROOT)/debian
RHEL_DIR    := $(DISK_ROOT)/rhel

# ---------- Defaults (override: make vm-create NAME=x RAM=8192) ----------
OS          ?= debian
NAME        ?=
SIZE        ?= 20G
CPUS        ?= 2
# RHEL 10 needs x86-64-v3 CPU flags, so pass the host CPU through
CPU         ?= host-passthrough
ISO         ?=
NET         ?= default
UEFI        ?= 0
SNAP        ?= snap1
LIBVIRT_URI ?= qemu:///system

# Cloud-init (see README): base image lives anywhere under ISO_DIR
BASE_IMG    ?=
BASE_FMT    ?= qcow2
SSH_KEY     ?= $(HOME)/.ssh/id_ed25519.pub
CI_USER     ?= devops
BUILD_DIR   := build
CI_TPL_debian = cloud-init/user-data.debian.tpl
CI_TPL_ubuntu = cloud-init/user-data.debian.tpl
CI_TPL_rhel   = cloud-init/user-data.rhel.tpl
CI_TPL        = $(CI_TPL_$(OS))

# Lean RAM defaults for an 8 GB host (MiB). Override: RAM=3072
RAM_debian := 2048
RAM_rhel   := 2048
RAM_ubuntu := 2048
RAM        ?= $(RAM_$(OS))

OS_VARIANT_debian := debian12
# Prefer ubuntu26.04 if your osinfo-db knows it, else fall back to ubuntu24.04
OS_VARIANT_ubuntu = $(shell osinfo-query os short-id=ubuntu26.04 >/dev/null 2>&1 && echo ubuntu26.04 || echo ubuntu24.04)
# Prefer rhel10 if your osinfo-db knows it, else fall back to rhel9
OS_VARIANT_rhel   = $(shell osinfo-query os short-id=rhel10-unknown >/dev/null 2>&1 && echo rhel10-unknown || echo rhel9-unknown)
OS_VARIANT        ?= $(OS_VARIANT_$(OS))

# Derived: disk folder + full qcow2 path based on OS and NAME
DISK_DIR = $(DISK_ROOT)/$(OS)
DISK     = $(DISK_DIR)/$(NAME).qcow2
VIRSH   = virsh -c $(LIBVIRT_URI)

# ---------- Guards ----------
define need_name
	@test -n "$(NAME)" || { echo "NAME is required, e.g. make $@ NAME=deb01" >&2; exit 2; }
endef
define need_os
	@case "$(OS)" in debian|rhel|ubuntu) ;; *) echo "OS must be 'debian', 'rhel' or 'ubuntu' (got '$(OS)')" >&2; exit 2;; esac
endef

help: ## List available targets
	@grep -E '^[a-zA-Z_-]+:.*## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN{FS=":.*## "};{printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

# ---------- Host setup ----------
setup: ## One-time: install KVM stack, enable libvirtd, add user to groups
	sudo pacman -S --needed qemu-full libvirt virt-install virt-viewer virt-manager dnsmasq swtpm edk2-ovmf libosinfo
	sudo systemctl enable --now libvirtd.service
	sudo usermod -aG libvirt,kvm $(USER)
	@echo "Log out/in so the group change applies."

check: ## Sanity check: SSD mounted, libvirtd running, folders exist
	@test -d "$(ISO_DIR)" || { echo "SSD not mounted or ISO dir missing: $(ISO_DIR)" >&2; exit 1; }
	@test -d "$(DEBIAN_DIR)" || { echo "Missing disk dir: $(DEBIAN_DIR)" >&2; exit 1; }
	@test -d "$(RHEL_DIR)" || { echo "Missing disk dir: $(RHEL_DIR)" >&2; exit 1; }
	@systemctl is-active --quiet libvirtd || { echo "libvirtd not running: sudo systemctl enable --now libvirtd" >&2; exit 1; }
	@echo "OK: SSD mounted, libvirtd running, folders ready."

pools: check ## Register debian + rhel qcow2 disk folders as libvirt storage pools
	@for p in debian rhel; do \
	  $(VIRSH) pool-info $$p >/dev/null 2>&1 || $(VIRSH) pool-define-as $$p dir --target "$(DISK_ROOT)/$$p"; \
	  $(VIRSH) pool-start $$p 2>/dev/null || true; \
	  $(VIRSH) pool-autostart $$p; \
	done
	$(VIRSH) pool-list --all

net-up: ## Start + autostart the default libvirt NAT network
	$(VIRSH) net-start default 2>/dev/null || true
	$(VIRSH) net-autostart default

# ---------- Inventory ----------
isos: check ## List ISO files in VM_ISO_Images
	@find "$(ISO_DIR)" -maxdepth 2 -iname '*.iso' -printf '%P\n' | sort

list-disks: check ## List qcow2 disks (all OS folders)
	@ls -lh "$(DISK_ROOT)"/*/*.qcow2 2>/dev/null || echo "No disks yet."

mem: ## Host RAM + per-VM memory use (run before starting another VM)
	@free -h | head -2
	@echo "--- running VMs ---"
	@$(VIRSH) list --name | grep . | while read v; do \
	  printf "%-20s " "$$v"; $(VIRSH) dominfo "$$v" | awk '/Used memory/{print $$3/1024 " MiB"}'; \
	done || echo "none running"

list: ## Show all VMs (running + stopped)
	$(VIRSH) list --all

# ---------- Create ----------
create-disk: check ## Create qcow2: make create-disk OS=debian NAME=deb01 SIZE=20G
	$(need_os)
	$(need_name)
	@test ! -e "$(DISK)" || { echo "Already exists: $(DISK)" >&2; exit 1; }
	@mkdir -p "$(DISK_DIR)"
	qemu-img create -f qcow2 -o preallocation=off "$(DISK)" $(SIZE)

vm-create: check ## Create disk + VM + boot installer: NAME= OS= ISO=file.iso [RAM= CPUS= SIZE= UEFI=1]
	$(need_os)
	$(need_name)
	@test -n "$(ISO)" || { echo "ISO is required (filename inside $(ISO_DIR)). See: make isos" >&2; exit 2; }
	@mkdir -p "$(DISK_DIR)"
	@test -e "$(DISK)" || qemu-img create -f qcow2 "$(DISK)" $(SIZE)
	@ISO_PATH="$$(find "$(ISO_DIR)" -maxdepth 2 -type f -name "$(ISO)" -print -quit)"; \
	  [ -n "$$ISO_PATH" ] || { echo "ISO not found: $(ISO)" >&2; exit 1; }; \
	  virt-install --connect $(LIBVIRT_URI) \
	    --name "$(NAME)" \
	    --memory $(RAM) --vcpus $(CPUS) --cpu $(CPU) \
	    --disk path="$(DISK)",format=qcow2,bus=virtio \
	    --cdrom "$$ISO_PATH" \
	    --os-variant $(OS_VARIANT) \
	    --network network=$(NET),model=virtio \
	    --graphics spice \
	    $(if $(filter 1,$(UEFI)),--boot uefi,) \
	    --noautoconsole
	@echo "Installer running. Open it with: virt-manager  (or make console NAME=$(NAME))"

# ---------- Cloud-init (idempotent, reproducible) ----------
cloud-vm: check ## Cloud VM + cloud-init: NAME= OS= BASE_IMG=file [SSH_KEY= CI_USER= SIZE= RAM= UEFI=1]
	$(need_os)
	$(need_name)
	@test -n "$(BASE_IMG)" || { echo "BASE_IMG is required (cloud image filename under $(ISO_DIR))" >&2; exit 2; }
	@test -f "$(SSH_KEY)" || { echo "SSH public key not found: $(SSH_KEY)  (create: ssh-keygen -t ed25519)" >&2; exit 2; }
	@test -f "$(CI_TPL)" || { echo "Missing template: $(CI_TPL)" >&2; exit 2; }
	@if $(VIRSH) dominfo "$(NAME)" >/dev/null 2>&1; then echo "VM '$(NAME)' already exists. Rebuild with: make rebuild NAME=$(NAME) OS=$(OS) BASE_IMG=$(BASE_IMG)" >&2; exit 1; fi
	@test ! -e "$(DISK)" || { echo "Disk already exists: $(DISK)" >&2; exit 1; }
	@BASE_PATH="$$(find "$(ISO_DIR)" -maxdepth 3 -type f -name "$(BASE_IMG)" -print -quit)"; \
	  [ -n "$$BASE_PATH" ] || { echo "Base image not found: $(BASE_IMG)" >&2; exit 1; }; \
	  mkdir -p "$(DISK_DIR)" "$(BUILD_DIR)"; \
	  KEY="$$(awk '{print $$1" "$$2}' "$(SSH_KEY)")"; \
	  sed -e 's|__HOSTNAME__|$(NAME)|g' -e 's|__USERNAME__|$(CI_USER)|g' -e "s|__SSH_PUBKEY__|$$KEY|g" \
	    "$(CI_TPL)" > "$(BUILD_DIR)/$(NAME).user-data"; \
	  qemu-img create -f qcow2 -F $(BASE_FMT) -b "$$BASE_PATH" "$(DISK)" $(SIZE); \
	  virt-install --connect $(LIBVIRT_URI) \
	    --name "$(NAME)" \
	    --memory $(RAM) --vcpus $(CPUS) --cpu $(CPU) \
	    --disk path="$(DISK)",format=qcow2,bus=virtio \
	    --import \
	    --os-variant $(OS_VARIANT) \
	    --network network=$(NET),model=virtio \
	    --graphics spice \
	    --cloud-init user-data="$(BUILD_DIR)/$(NAME).user-data" \
	    $(if $(filter 1,$(UEFI)),--boot uefi,) \
	    --noautoconsole
	@echo "First boot runs cloud-init (updates + tools, a few minutes). Then: make validate NAME=$(NAME)"

rebuild: ## Destroy + recreate a cloud VM from the untouched base image (asks first)
	@$(MAKE) --no-print-directory delete
	@$(MAKE) --no-print-directory cloud-vm

ssh: ## SSH into VM as CI_USER: make ssh NAME=deb01
	$(need_name)
	@IP="$$($(VIRSH) domifaddr "$(NAME)" | awk '/ipv4/{split($$4,a,"/"); print a[1]; exit}')"; \
	  [ -n "$$IP" ] || { echo "No IP yet. Is $(NAME) running and finished booting?" >&2; exit 1; }; \
	  ssh -o StrictHostKeyChecking=accept-new $(CI_USER)@$$IP

validate: ## Run scripts/validate.sh inside the VM over SSH: make validate NAME=deb01
	$(need_name)
	@IP="$$($(VIRSH) domifaddr "$(NAME)" | awk '/ipv4/{split($$4,a,"/"); print a[1]; exit}')"; \
	  [ -n "$$IP" ] || { echo "No IP yet. Is $(NAME) running and finished booting?" >&2; exit 1; }; \
	  ssh -o StrictHostKeyChecking=accept-new $(CI_USER)@$$IP 'bash -s' < scripts/validate.sh

# ---------- Lifecycle ----------
start: ## Start VM: make start NAME=deb01
	$(need_name)
	$(VIRSH) start "$(NAME)"

stop: ## Graceful shutdown: make stop NAME=deb01
	$(need_name)
	$(VIRSH) shutdown "$(NAME)"

kill: ## Force power-off: make kill NAME=deb01
	$(need_name)
	$(VIRSH) destroy "$(NAME)"

reboot: ## Reboot VM: make reboot NAME=deb01
	$(need_name)
	$(VIRSH) reboot "$(NAME)"

view: ## Open graphical console (virt-viewer): make view NAME=deb01
	$(need_name)
	virt-viewer -c $(LIBVIRT_URI) "$(NAME)"

console: ## Serial console (Ctrl+] to exit): make console NAME=deb01
	$(need_name)
	$(VIRSH) console "$(NAME)"

ip: ## Show VM IP address: make ip NAME=deb01
	$(need_name)
	$(VIRSH) domifaddr "$(NAME)"

# ---------- Snapshots ----------
snap: ## Take snapshot: make snap NAME=deb01 SNAP=clean-install
	$(need_name)
	$(VIRSH) snapshot-create-as "$(NAME)" "$(SNAP)"

snap-list: ## List snapshots: make snap-list NAME=deb01
	$(need_name)
	$(VIRSH) snapshot-list "$(NAME)"

snap-revert: ## Revert snapshot: make snap-revert NAME=deb01 SNAP=clean-install
	$(need_name)
	$(VIRSH) snapshot-revert "$(NAME)" "$(SNAP)"

# ---------- Destroy ----------
delete: ## Remove VM + its qcow2 (asks first): make delete NAME=deb01 OS=debian
	$(need_os)
	$(need_name)
	@read -p "Delete VM '$(NAME)' AND $(DISK)? [y/N] " a; [ "$$a" = "y" ] || { echo "Aborted."; exit 1; }
	-$(VIRSH) destroy "$(NAME)" 2>/dev/null
	-$(VIRSH) undefine "$(NAME)" --nvram --snapshots-metadata 2>/dev/null || $(VIRSH) undefine "$(NAME)"
	rm -f "$(DISK)"
