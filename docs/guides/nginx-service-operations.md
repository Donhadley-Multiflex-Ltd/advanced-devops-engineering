# Linux Service Operations Procedure: nginx

**Ticket:** DEVOPS-008-J  
**Suggested repository location:** `docs/guides/nginx-service-operations.md`  
**Scope:** nginx installed as a systemd service on Ubuntu/Debian Linux  
**Document status:** Ready for lab validation; no target-host execution evidence is attached.

## 1. Purpose

Provide a repeatable incident-response workflow for managing nginx, inspecting its processes and listening ports, diagnosing failures, and verifying recovery.

Follow this order: record impact, collect evidence, identify the failure, make the smallest justified change, verify recovery, and record the outcome. A successful restart alone does not prove recovery.

## 2. Prerequisites and environment checks

- Shell access to the affected Linux host and permission to operate its services.
- `sudo` access for restricted commands.
- Existing nginx installation managed by `nginx.service`.
- Available tools: `systemctl`, `journalctl`, `ps`, `pgrep`, `ss`, and `curl`.
- Confirmed incident ID, service owner, hostname, affected URL, expected response, and recent changes.

Run diagnostic commands on the affected Linux host, not in a local Windows or Git Bash session.

```bash
date -Is
hostname
cat /etc/os-release
command -v nginx
nginx -v
sudo systemctl cat nginx.service
sudo systemctl show nginx.service -p FragmentPath -p ExecStart -p ExecReload
```

Check the unit for custom binary paths, configuration arguments, and overrides. This procedure uses the package-default `sudo nginx -t`; if the service uses a different binary, `-c` configuration file, or `-p` prefix, use the matching binary and arguments for every configuration test or dump below.

Common paths are `/etc/nginx/nginx.conf`, `/var/log/nginx/access.log`, and `/var/log/nginx/error.log`. Verify them against the installed configuration. Logs may use different files or syslog. Containers, Kubernetes, and hosts without systemd require a different service-control procedure.

Before HTTP checks, replace these examples with the actual virtual host, a configured listener address, and a valid application path:

```bash
site_host='app.example.com'
listener_ip='127.0.0.1'
health_path='/'
```

Use only the applicable HTTP or HTTPS checks below. Port 443 is expected only when HTTPS is configured. Record the expected status and content for the selected path; `/health` is not assumed to exist.

## 3. Initial incident assessment and evidence

Record the first failure time, affected users, symptom, last successful request, recent deployment/configuration changes, and whether other hosts are affected. Capture the following before changing service state when feasible:

```bash
sudo systemctl status nginx.service --no-pager -l
sudo systemctl show nginx.service \
  -p ActiveState -p SubState -p MainPID -p Result -p ExecMainStatus
sudo journalctl -u nginx.service --since '30 minutes ago' \
  --no-pager -o short-iso
sudo nginx -t
sudo ps -C nginx -o pid,ppid,user,stat,%cpu,%mem,etime,args
sudo ss -ltnp '( sport = :80 or sport = :443 )'
```

`systemctl status` and `nginx -t` may return a nonzero exit status during a failure; keep their output as evidence. Adjust the journal time window and port numbers to match the incident.

If saving output locally, restrict access first:

```bash
umask 077
incident_dir="$HOME/nginx-incident-$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$incident_dir"
sudo systemctl status nginx.service --no-pager -l \
  > "$incident_dir/service-status.txt" 2>&1
sudo journalctl -u nginx.service --since '30 minutes ago' \
  --no-pager -o short-iso > "$incident_dir/service-journal.txt" 2>&1
sudo nginx -t > "$incident_dir/config-test.txt" 2>&1
```

Record commands, timestamps, and results in the incident ticket. Redact credentials, tokens, private addresses where required, and personal data before attaching evidence. Configuration dumps and access logs can contain sensitive information.

## 4. Service management

Choose the action that matches the observed state. Do not run this table as a sequence.

| Action | Command | When to use / interpretation |
| --- | --- | --- |
| Detailed status | `sudo systemctl status nginx.service --no-pager -l` | Inspect state, recent messages, and unit details. |
| Running state | `systemctl is-active nginx.service` | `active` confirms systemd state, not application health. |
| Boot configuration | `systemctl is-enabled nginx.service` | Checks enablement; does not prove the service is running. |
| Start | `sudo nginx -t && sudo systemctl start nginx.service` | Start an inactive service after validating its configuration. |
| Reload | `sudo nginx -t && sudo systemctl reload nginx.service` | Apply supported nginx configuration changes to a running service. |
| Restart | `sudo nginx -t && sudo systemctl restart nginx.service` | Stop and start when a reload is insufficient; may interrupt traffic. |
| Stop | `sudo systemctl stop nginx.service` | Intentional shutdown; removes service availability. |
| Enable at boot | `sudo systemctl enable nginx.service` | Set intended boot behavior; does not start nginx immediately. |
| Disable at boot | `sudo systemctl disable nginx.service` | Remove boot enablement; does not stop a running instance. |

The `&&` prevents the service action if the configuration test fails. Do not bypass a failed test. A passing test checks configuration syntax and referenced-file access, but does not establish upstream health or successful request handling.

Prefer reload for supported configuration changes. nginx starts replacement workers and lets existing workers finish their requests. Confirm fresh logs and HTTP responses afterward: a successful command return is insufficient evidence that the desired configuration is serving traffic.

Use `sudo systemctl daemon-reload` only after changing a systemd unit or drop-in. It does not reload nginx configuration. Confirm the intended unit changes, then apply the appropriate service action.

Do not launch a separate nginx instance manually or use `kill -9` as routine recovery. Keep service control under systemd to preserve consistent process ownership and state tracking.

## 5. Process inspection

```bash
sudo systemctl show nginx.service -p MainPID
sudo pgrep -a -x nginx
sudo ps -C nginx -o pid,ppid,user,stat,%cpu,%mem,etime,args
```

Inspect:

- **PID:** the process identifier; compare the master process with systemd's `MainPID`.
- **PPID:** parent process identifier; workers normally belong to the nginx master.
- **USER:** the master often runs as root; workers commonly use `www-data` on Ubuntu/Debian. Confirm the configured account rather than assuming it.
- **STAT:** process state. Investigate persistent zombie or uninterruptible states in context.
- **CPU, memory, elapsed time:** compare with normal load and the incident timeline.
- **Arguments:** distinguish master and worker processes, and check for unexpected instances or configuration arguments.

Normally there is one master and one or more workers; additional cache processes may be configured. Old workers may remain temporarily while draining connections after a reload. Worker count and a changed worker PID alone do not establish a failure.

For sustained resource symptoms, observe the host as well:

```bash
top
free -h
df -h
df -i
sudo journalctl -k --since '30 minutes ago' --no-pager
```

Press `q` to exit `top`. Check for memory pressure, out-of-memory kills, full filesystems, and exhausted inodes. Record evidence before restarting a resource-constrained service.

## 6. Port and request inspection

### 6.1 Confirm expected listeners and owners

```bash
sudo ss -ltnp '( sport = :80 or sport = :443 )'
```

`-l` selects listening sockets, `-t` selects TCP, `-n` keeps numeric addresses, and `-p` shows process ownership when permitted. Replace ports for custom listeners. To inspect every listening TCP socket, use `sudo ss -ltnp`.

Check the process owner and bind address. `127.0.0.1` is IPv4 loopback, `0.0.0.0` covers IPv4 interfaces, and `[::]` is an IPv6 wildcard whose IPv4 behavior depends on socket configuration. A listener proves a socket exists; it does not prove remote reachability.

If nginx cannot bind, identify the existing listener before deciding what to change. Do not terminate an unfamiliar process just to free the port.

### 6.2 Test the correct virtual host locally

HTTP example:

```bash
curl --noproxy '*' --connect-timeout 3 --max-time 10 \
  --resolve "${site_host}:80:${listener_ip}" \
  -sS -D - "http://${site_host}${health_path}"
```

HTTPS example, preserving the hostname for TLS verification and SNI:

```bash
curl --noproxy '*' --connect-timeout 3 --max-time 10 \
  --resolve "${site_host}:443:${listener_ip}" \
  -sS -D - "https://${site_host}${health_path}"
```

Inspect the status, headers, and body against the expected result. `curl` without `--fail` may exit successfully even for HTTP 4xx or 5xx responses. An expected redirect is not an application health check; also test its intended destination. Do not use `-k` to declare TLS healthy.

### 6.3 Test the user-facing route

From a separate client on the affected network, set the same `site_host` and `health_path`, then request the real URL without `--resolve`:

```bash
curl --connect-timeout 5 --max-time 15 \
  -sS -D - "https://${site_host}${health_path}"
```

Use HTTP if that is the intended service. This check exercises the client route, including DNS and any proxy or load balancer. If local checks pass but client checks fail, investigate DNS, host firewall, cloud security groups, routing, and load-balancer health. Do not assume nginx needs another restart.

## 7. Logs and troubleshooting decisions

```bash
sudo journalctl -u nginx.service -b -n 100 --no-pager
sudo tail -n 100 /var/log/nginx/error.log
sudo tail -n 100 /var/log/nginx/access.log
```

Use the verified log paths. The journal commonly explains service startup failures; nginx error logs provide request/runtime errors; access logs show recorded requests and responses. Missing entries are not proof that requests never arrived: logging may be disabled, conditional, buffered, or routed elsewhere.

For live observation, run `sudo journalctl -u nginx.service -f` or `sudo tail -F /var/log/nginx/error.log`, reproduce one failing request, and press `Ctrl+C` to stop following logs.

If configuration inspection is necessary:

```bash
sudo nginx -T
```

This tests and prints the configuration files currently on disk. It does not prove those files match the running workers after an unsuccessful reload. Inspect locally and redact before sharing.

| Symptom | Checks | Next action |
| --- | --- | --- |
| Unit not found | Check `command -v nginx`, installed packages, and deployment method. | Confirm the correct host and unit; do not install or reinstall during triage without a justified change. |
| Service inactive or failed | Inspect status, journal, configuration test, and port ownership. | Correct the identified cause, then start and verify. |
| Syntax error / invalid directive | Run `sudo nginx -t`; use its file and line reference. | Correct the specific edit or restore a known-good version; retest before reload/start. |
| Address already in use | Inspect `ss` output and owner PID. | Resolve the unintended listener or configuration conflict with its owner. |
| Permission denied | Read the exact log path/error; inspect file ownership, directory traversal, and AppArmor/SELinux where applicable. | Fix the narrow permission or policy issue. Do not use `chmod -R 777` or disable security controls. |
| HTTP 403 or 404 | Check virtual host, request path, `root`/`alias`, index, access rules, permissions, and application routing. | Correct the proven routing/content/access issue; correlate with logs. |
| HTTP 502 or 504 | Read error logs; check configured upstream address, application state, socket permissions, and connectivity. | Diagnose the upstream. Test its actual protocol/endpoint; do not blindly increase timeouts. |
| TLS failure | Inspect curl output, certificate hostname/expiry/chain, configured certificate files, and listener. | Correct the certificate/configuration issue and retest with verification enabled. |
| Local success, remote failure | Compare DNS resolution, network policy, bind address, load balancer, and client path. | Escalate or correct the failing network layer with evidence. |
| High latency or resource exhaustion | Inspect processes, memory, disk/inodes, kernel messages, request volume, and upstream latency. | Address the demonstrated bottleneck; preserve evidence and monitor after mitigation. |
| Start request repeated too quickly | Fix the underlying failure first and confirm `nginx -t` passes. | Run `sudo systemctl reset-failed nginx.service`, then start once and verify. |

If required tools are missing or a command is unsupported, record the limitation and use the host's installed `man` pages. Do not treat missing diagnostic tools as proof that nginx is broken.

## 8. Controlled configuration change and rollback

Before editing the default configuration tree, capture its current state:

```bash
backup_dir="/var/backups/nginx-$(date -u +%Y%m%dT%H%M%SZ)"
sudo install -d -m 0700 "$backup_dir"
sudo cp -a /etc/nginx "$backup_dir/"
```

Record the backup path. Check for configuration includes or symlink targets outside `/etc/nginx` and preserve any files you will change there as well. An incident-time snapshot preserves evidence; it may already contain the fault. Identify a separately verified known-good version for recovery.

1. Record the proposed change and expected result in the incident ticket.
2. Edit only the relevant file with `sudoedit` and record its original path.
3. Run `sudo nginx -t`. If it fails, fix or revert the edit before proceeding.
4. For a running service, run `sudo systemctl reload nginx.service`; use a justified restart only when necessary. For an inactive service, start it after the test passes.
5. Repeat service, process, listener, log, and request checks.
6. If behavior worsens, stop further changes and restore the affected files from the recorded known-good backup or version control. Preserve ownership, permissions, symlinks, and the intended include layout; remove only newly introduced files belonging to the failed change.
7. Test the restored configuration. Reload a running service or start an inactive one, then repeat the full verification.

Do not blindly overwrite the entire configuration tree or restore an unverified snapshot. If no known-good version exists, or recovery requires disruptive changes outside your responsibility, escalate with the collected evidence.

## 9. Recovery and incident closure

- [ ] Configuration validation passes using the service's actual binary/configuration.
- [ ] systemd reports the expected running state and the master/worker processes are present.
- [ ] Expected ports and bind addresses belong to the intended nginx instance.
- [ ] Local requests to the affected virtual host return the expected status and content.
- [ ] Requests from the affected client route succeed, including TLS where applicable.
- [ ] Relevant upstream/application checks succeed.
- [ ] Fresh logs and monitoring show no recurrence during the agreed observation period.
- [ ] Boot enablement matches the intended policy.
- [ ] The incident record contains evidence, change details, recovery time, and follow-up ownership.

Keep the incident open if only service status is healthy while user-facing requests still fail. Escalate when the cause is unclear, the failure recurs, or a network/upstream owner must act. Record unresolved root cause explicitly even if a mitigation restores availability.

### Incident record template

```text
Incident ID:
Operator / owner:
Host and environment:
Start time and timezone:
Affected URL / users / symptom:
Expected response:
Recent changes:
Service, process, port, and request findings:
Relevant log timestamps / messages:
Working diagnosis and supporting evidence:
Commands / configuration changes / timestamps:
Backup and known-good version:
Rollback performed and result:
Local and external verification results:
Observation period and monitoring result:
Recovery time:
Confirmed root cause or unresolved questions:
Escalation / follow-up owner:
```

## 10. Lab validation and acceptance evidence

Run disruptive exercises only on an isolated lab host. Do not mark the ticket validated until actual outputs are attached.

1. Record the healthy baseline: service state, master/workers, configured listeners, logs, and a successful request.
2. Stop nginx intentionally in the lab. Confirm the service/request failure, then validate configuration, start it, and prove recovery.
3. Back up a lab configuration file and introduce a syntax error. Confirm `nginx -t` fails and the guarded reload command does not run. Restore the file, test, and reload.
4. Capture listener ownership using `ss`; explain which address/port serves the selected virtual host.
5. Have another learner repeat the workflow using this document and complete the incident record.

| Ticket acceptance criterion | Procedure coverage | Evidence to attach after execution |
| --- | --- | --- |
| Service management steps | Sections 3, 4, 8 | Status, config test, selected action, and recovery result. |
| Process inspection steps | Section 5 | PID/PPID/user output with master and workers identified. |
| Port inspection steps | Section 6 | Listener owner/address/port and HTTP/TLS response evidence. |
| Troubleshooting steps | Sections 7, 8 | Failure symptom, logs, diagnosis, correction, and verification. |
| Repeatable incident workflow | Sections 2, 3, 9, 10 | Completed incident record and independent repeat of the lab workflow. |

## 11. References

- [nginx Beginner's Guide](https://nginx.org/en/docs/beginners_guide.html)
- [nginx command-line parameters](https://nginx.org/en/docs/switches.html)
- [Controlling nginx](https://nginx.org/en/docs/control.html)
- [NGINX logging configuration](https://docs.nginx.com/nginx/admin-guide/monitoring/logging/)
- Installed host documentation: `man systemctl`, `man journalctl`, `man ps`, `man pgrep`, `man ss`, and `man curl`.

Use the installed package's documentation for version-specific behavior.

