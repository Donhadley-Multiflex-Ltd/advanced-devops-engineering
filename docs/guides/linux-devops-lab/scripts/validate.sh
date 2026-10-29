#!/usr/bin/env bash
# DEVOPS-006 validation + baseline report. Read-only: safe to run any number of times.
# Run inside the VM:   bash scripts/validate.sh
# Or from the host:    make validate NAME=<vm>
set -u

PASS=0; FAIL=0; WARN=0
ok()   { printf '  [PASS] %s\n' "$1"; PASS=$((PASS + 1)); }
bad()  { printf '  [FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
warn() { printf '  [WARN] %s\n' "$1"; WARN=$((WARN + 1)); }
check() { local d=$1; shift; if "$@" >/dev/null 2>&1; then ok "$d"; else bad "$d"; fi; }
section() { printf '\n== %s ==\n' "$1"; }

if systemctl cat ssh.service >/dev/null 2>&1; then SSH_UNIT=ssh; else SSH_UNIT=sshd; fi

section "A/B  Host and identity"
[ "$(id -u)" -ne 0 ] && ok "running as non-root user ($(whoami))" || warn "running as root"
check "passwordless sudo works" sudo -n true
case "$(hostname)" in
  ubuntu|server|vm1|test|localhost|debian|rhel) bad "vague hostname: $(hostname)" ;;
  *) ok "hostname: $(hostname)" ;;
esac

section "C  Packages and base tools"
for t in curl wget git vim jq unzip tree netstat dig; do
  check "tool present: $t" command -v "$t"
done
command -v htop >/dev/null 2>&1 && ok "tool present: htop" || warn "htop missing (EPEL-only on RHEL)"
if command -v apt-get >/dev/null 2>&1; then
  pending=$(apt-get -s upgrade 2>/dev/null | grep -c '^Inst')
  [ "$pending" -eq 0 ] && ok "no pending apt upgrades" || warn "$pending packages can be upgraded"
elif command -v dnf >/dev/null 2>&1; then
  dnf -q check-update >/dev/null 2>&1; rc=$?
  [ "$rc" -eq 0 ] && ok "no pending dnf updates" || warn "dnf reports updates or an error (exit $rc)"
fi
[ -f /var/run/reboot-required ] && warn "reboot required" || ok "no reboot required"

section "D  Resources (guide minimum: 2 vCPU, 2 GB RAM, 20 GB disk)"
cpus=$(nproc); mem_mb=$(awk '/MemTotal/{print int($2/1024)}' /proc/meminfo)
disk_kb=$(df -k --output=size / | tail -1 | tr -d ' ')
[ "$cpus" -ge 2 ]         && ok "vCPU: $cpus"        || bad "vCPU: $cpus (need 2)"
[ "$mem_mb" -ge 1800 ]    && ok "memory: ${mem_mb} MiB" || bad "memory: ${mem_mb} MiB (need ~2 GB)"
[ "$disk_kb" -ge 18000000 ] && ok "root disk: $((disk_kb / 1024 / 1024)) GiB" || bad "root disk: $((disk_kb / 1024 / 1024)) GiB (need 20 GB)"

section "E  Network and DNS"
check "default route present" bash -c "ip route | grep -q '^default'"
ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1 && ok "ICMP to 8.8.8.8" || warn "ping failed (ICMP may be blocked)"
check "HTTPS to github.com" curl -sSI -m 10 https://github.com
check "DNS: getent hosts github.com" getent hosts github.com

section "F  SSH"
check "ssh enabled ($SSH_UNIT)" systemctl is-enabled "$SSH_UNIT"
check "ssh active ($SSH_UNIT)"  systemctl is-active "$SSH_UNIT"
check "port 22 listening" bash -c "ss -tln | grep -q ':22 '"
if sudo -n true 2>/dev/null; then
  sudo sshd -T 2>/dev/null | grep -qi '^permitrootlogin no' && ok "root SSH login disabled" || bad "root SSH login not disabled"
  sudo sshd -T 2>/dev/null | grep -qi '^passwordauthentication no' && ok "SSH password login disabled" || warn "SSH password login enabled"
fi

section "G  Baseline (paste into docs/linux/environment.md)"
printf '%s\n' "| Field | Value |" "|---|---|"
printf '| Hostname | %s |\n' "$(hostname)"
printf '| OS | %s |\n' "$(. /etc/os-release && echo "$PRETTY_NAME")"
printf '| Kernel | %s |\n' "$(uname -r)"
printf '| CPU | %s vCPU |\n' "$cpus"
printf '| Memory | %s MiB |\n' "$mem_mb"
printf '| Root disk | %s GiB |\n' "$((disk_kb / 1024 / 1024))"
printf '| IP | %s |\n' "$(ip -br -4 addr | awk '$1!="lo"{print $3; exit}')"
printf '| Default route | %s |\n' "$(ip route | awk '/^default/{print $3; exit}')"
printf '| SSH | %s |\n' "$(systemctl is-active "$SSH_UNIT" 2>/dev/null)"
printf '| Git | %s |\n' "$(git --version 2>/dev/null)"
printf '| curl | %s |\n' "$(curl --version 2>/dev/null | head -1 | cut -d' ' -f1-2)"
printf '| jq | %s |\n' "$(jq --version 2>/dev/null)"

printf '\nSummary: %d passed, %d warnings, %d failed\n' "$PASS" "$WARN" "$FAIL"
[ "$FAIL" -eq 0 ]
