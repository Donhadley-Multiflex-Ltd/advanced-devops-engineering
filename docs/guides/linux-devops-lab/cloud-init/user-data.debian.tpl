#cloud-config
# DEVOPS-006 base environment for Ubuntu Server LTS / Debian cloud images.
# Rendered by `make cloud-vm`, which fills in the hostname, username and SSH public key.
# Idempotent by design: only declarative modules (users, packages, write_files) plus
# runcmd steps that are safe to repeat. Public key only: never put secrets in this file.

# --- DEVOPS-006-B: hostname and base identity ---
hostname: __HOSTNAME__
preserve_hostname: false
manage_etc_hosts: true

# --- DEVOPS-006-A: non-root user with sudo, key-only login ---
users:
  - name: __USERNAME__
    groups: [sudo]
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL   # lab VM only; password is locked, key login only
    lock_passwd: true
    ssh_authorized_keys:
      - __SSH_PUBKEY__
disable_root: true
ssh_pwauth: false

# --- DEVOPS-006-C: update OS, install base tools, reboot only if required ---
package_update: true
package_upgrade: true
package_reboot_if_required: true
packages:
  - curl
  - wget
  - git
  - vim
  - jq
  - unzip
  - tree
  - net-tools
  - dnsutils
  - htop
  - openssh-server
  - qemu-guest-agent   # lets libvirt report IPs and shut the VM down cleanly

# --- DEVOPS-006-F: secure SSH (no root login, no passwords) ---
write_files:
  - path: /etc/ssh/sshd_config.d/10-hardening.conf
    owner: root:root
    permissions: "0644"
    defer: true   # write after packages are installed
    content: |
      PermitRootLogin no
      PasswordAuthentication no
      KbdInteractiveAuthentication no

runcmd:
  - [systemctl, enable, --now, ssh]
  - [systemctl, reload, ssh]
  - [systemctl, start, qemu-guest-agent]

final_message: "DEVOPS-006 base ready after $UPTIME seconds. Run: make validate NAME=__HOSTNAME__"
