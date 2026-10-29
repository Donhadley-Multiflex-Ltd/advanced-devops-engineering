#cloud-config
# DEVOPS-006 base environment for RHEL (KVM guest image). UNTESTED here: see README caveats.
# Rendered by `make cloud-vm`, which fills in the hostname, username and SSH public key.
# RHEL needs an active subscription for dnf. Register the VM first (activation key from
# your environment, NEVER committed), or use Rocky/Alma, which need no subscription.

hostname: __HOSTNAME__
preserve_hostname: false
manage_etc_hosts: true

users:
  - name: __USERNAME__
    groups: [wheel]
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL   # lab VM only; password is locked, key login only
    lock_passwd: true
    ssh_authorized_keys:
      - __SSH_PUBKEY__
disable_root: true
ssh_pwauth: false

package_update: true
package_upgrade: true
package_reboot_if_required: true
packages:
  - curl
  - wget
  - git
  - vim-enhanced
  - jq
  - unzip
  - tree
  - net-tools
  - bind-utils        # dig (dnsutils on Debian/Ubuntu)
  - openssh-server
  - qemu-guest-agent
  

write_files:
  - path: /etc/ssh/sshd_config.d/10-hardening.conf
    owner: root:root
    permissions: "0644"
    defer: true
    content: |
      PermitRootLogin no
      PasswordAuthentication no
      KbdInteractiveAuthentication no

runcmd:
  - [systemctl, enable, --now, sshd]
  - [systemctl, reload, sshd]
  - [systemctl, enable, --now, qemu-guest-agent]

final_message: "DEVOPS-006 base ready after $UPTIME seconds. Run: make validate NAME=__HOSTNAME__"
