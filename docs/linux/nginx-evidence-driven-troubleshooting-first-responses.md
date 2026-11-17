i# DEVOPS-009-J: Explain Why Common Destructive Actions Are Poor First Responses

## Purpose

Explain why rebooting a server, reinstalling nginx, and broadly changing permissions are poor initial responses to an nginx outage. Replace trial-and-error changes with timestamped evidence, testable hypotheses, targeted remediation, and verified recovery.

## Core principle

An outage is a symptom. Before changing the system, establish what is failing, capture the current state, and identify the smallest action supported by evidence. Changing several things at once makes it harder to determine what caused the failure or what restored service.

These actions are not equally destructive: a controlled reboot may preserve persistent data, and a package reinstall may retain local configuration. They are poor first responses because they can alter or erase useful evidence, affect unrelated workloads, and introduce new variables without testing a diagnosis.

Restoring availability and proving root cause are separate outcomes. If a reboot makes the service respond, document that recovery; do not claim the original cause is known without supporting evidence.

## Comparison

| Initial action | Evidence or state affected | Operational risk | Better first response |
| --- | --- | --- | --- |
| Reboot the server | PIDs, process relationships, sockets, memory pressure, and volatile runtime state disappear or change; volatile journal records may be lost. | Interrupts every workload on the host; may expose startup or mount problems. | Capture requests, service/process state, listeners, logs, and resource measurements. |
| Reinstall nginx | Package files, timestamps, and potentially service state change before the installation is examined. | May invoke package scripts, restart services, alter dependencies, or select a different version. | Test the actual nginx configuration and inspect logs, package ownership/version, and suspected file damage. |
| Apply broad permission changes | Original ownership, modes, and potentially ACL masks are overwritten across many objects. | Can expose secrets, permit unauthorized writes, or break path traversal/application access. | Identify the exact denied operation, affected path, service account, and intended access policy. |

## 1. Why rebooting is a poor first action

### It removes useful runtime evidence

A reboot destroys the running process tree and replaces the current socket and memory state. Investigators may lose the chance to identify the process holding nginx's port, the workload consuming memory, or a service that was repeatedly crashing.

Do not claim that a reboot always deletes all logs. Journals stored only under `/run` are volatile; persistent journal files, file-based nginx logs, and remote logging may survive. Availability of previous-boot evidence depends on the actual storage and retention settings. [1]

### It affects more than nginx

The whole host restarts, including unrelated applications, monitoring agents, scheduled jobs, and client connections. Services that were running before the incident may not return if their boot configuration, dependencies, or filesystems are faulty.

A reboot can also activate pending changes, so the post-boot system may differ from the system being investigated.

### It can hide rather than correct the cause

Restarting the host may temporarily release memory or reset a process, but a leak or conflicting service can return. A syntax error on disk generally remains. Apparent recovery alone does not establish which condition caused the outage.

**Example:** nginx cannot bind to port 80 because an unintended service owns it. After reboot, nginx starts first and appears recovered. The conflicting service and its configuration still exist; the next startup order may reproduce the incident.

### When a reboot can be justified

A controlled reboot may be appropriate for an unresponsive host, a confirmed kernel-level condition, a required system update, or an established incident recovery procedure. Preserve the evidence that is practical, record the reason and expected impact, arrange console access if needed, and verify all affected workloads afterward. Do not prolong a severe outage indefinitely just to gather more evidence.

## 2. Why reinstalling nginx is a poor first action

### It assumes the installation is the problem

An unavailable nginx endpoint may result from invalid configuration, a port conflict, denied access, disk exhaustion, a failed upstream, or a network fault. Replacing package files does not directly address those conditions.

### It changes the system before the fault is understood

Package operations may run maintainer scripts and change service state. Repository availability, package selection, dependency resolution, and candidate versions add variables to an incident that may have nothing to do with packaging.

Reinstallation can also overwrite the suspect package file before its original state or checksum has been captured.

### Reinstallation and purge have different effects

On Ubuntu/Debian, reinstalling a package is not a reliable way to reset locally modified configuration. A normal reinstall commonly retains it. `remove` and `purge` are distinct: removal normally leaves package configuration, while purge removes package-managed configuration. A purge is not a guarantee that every external/custom nginx file is removed. [2]

Therefore, both assumptions below are unsafe:

- "Reinstalling always fixes the configuration."
- "Reinstalling always deletes all nginx configuration."

**Example:** an nginx site file contains a missing semicolon. Reinstalling the package may retain that file and the same startup failure. Correcting the identified directive and validating it is the targeted response.

### When a reinstall can be justified

Use package repair when investigation identifies a missing or damaged package-owned file, an incomplete package transaction, or another installation fault. Capture the existing state, identify the package owning the affected file, compare against trusted package metadata, back up relevant configuration, and review the proposed package transaction/version before applying it.

A failed integrity check is evidence to investigate; expected local configuration changes are not automatically corruption. If compromise is suspected, ordinary reinstallation is insufficient to establish host trust: preserve evidence and follow the applicable incident response/rebuild process.

## 3. Why broadly changing permissions is a poor first action

### It replaces a diagnosis with excessive access

Examples of poor blanket fixes include recursive mode `777`, recursive mode `755` over a mixed tree, and recursively transferring ownership of all configuration or web content to the nginx worker account.

Mode `777` grants read/write/execute to owner, group, and other users. Directory execute permission means traversal/search; write permission can allow creating or removing directory entries, subject to other controls. Broad access can expose private material or allow code/configuration modification. [3]

Mode `755` is also not universally correct. It makes ordinary files executable and readable by others, while other blanket modes may remove directory traversal. nginx should receive only the access required for the specific object and operation.

### It overwrites the metadata needed for investigation and rollback

Recursive changes affect many unrelated paths. Without a prior ownership/mode/ACL snapshot, restoring the exact previous access policy may be difficult. They can also change ACL masks or special permission bits and violate application expectations.

### A permission-looking error can have another cause

A `403` alone does not prove an incorrect Unix mode. The cause may be an nginx access rule, missing index, a parent directory, an ACL, SELinux/AppArmor, or service sandboxing. Confirm the actual denied operation before changing access.

**Example:** the worker cannot read one public static file whose intended mode was accidentally changed from `0644` to `0000`. Confirm its intended policy and restore only that file. Making the whole web tree world-writable introduces a separate security problem.

### When permission changes can be justified

Permission repair is appropriate when evidence identifies the exact access mismatch. Record the current numeric mode, UID/GID, ACLs where applicable, and required service identity. Restore the intended least-privilege state on the affected path and retest access as that identity. A static-file permission repair usually takes effect on a new request without restarting nginx.

## 4. Evidence-driven troubleshooting workflow

### Step 1 — Record time, scope, and the reported symptom

Record the UTC start time, hostname, affected URL, client location, expected response, observed response, and recent relevant changes. Reproduce the failure before remediation.

### Step 2 — Preserve a timestamped baseline

The following examples assume Ubuntu/systemd and a normal `nginx.service` installation. Run them on the affected Linux server. Adjust paths, ports, and executable/configuration arguments to match the real service.

Initialize a small evidence log in the same interactive Bash session:

```bash
umask 077
EVIDENCE_DIR="$HOME/devops-evidence/DEVOPS-009-J/$(date -u +'%Y%m%dT%H%M%SZ')-$$"
mkdir -p "$EVIDENCE_DIR"
EVIDENCE_FILE="$EVIDENCE_DIR/baseline.log"
touch "$EVIDENCE_FILE"

record_check() {
  local observed_rc
  {
    printf '\n[%s] COMMAND:' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    printf ' %q' "$@"
    printf '\n'
    if "$@"; then
      observed_rc=0
    else
      observed_rc=$?
    fi
    printf '[%s] COMMAND_EXIT_CODE=%s\n' \
      "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$observed_rc"
  } 2>&1 | tee -a "$EVIDENCE_FILE"
}
```

This wrapper logs observations and continues after failed diagnostic checks. Read its printed `COMMAND_EXIT_CODE`; do not use its return status to gate remediation. Stop if evidence-file creation or logging fails. On a full filesystem, capture remotely or use a verified writable alternate location.

```bash
record_check hostname
record_check sudo systemctl status nginx.service --no-pager --full
record_check ps -C nginx -o pid,ppid,user,stat,etime,args
record_check sudo ss -ltnp '( sport = :80 or sport = :443 )'
record_check sudo nginx -t
record_check sudo journalctl -u nginx.service --since '15 minutes ago' \
  --utc --no-pager -o short-iso-precise -n 100
record_check df -h
record_check df -i
record_check free -h
```

If relevant, also capture nginx's configured error log, the kernel journal for suspected OOM, and the original package-file metadata. Missing permissions/tools mean the check is incomplete; they do not prove nginx is down.

`nginx -t` checks configuration syntax and access to referenced files. Use the same `-c`, `-p`, or other required startup arguments as the managed service. A successful test does not prove port availability, upstream health, or endpoint correctness. [4]

For a default HTTP lab, reproduce the request with bounded timeouts:

```bash
record_check curl --noproxy '*' --connect-timeout 3 --max-time 10 \
  --silent --show-error --dump-header - --output /dev/null \
  --write-out '\nhttp_code=%{http_code} total_seconds=%{time_total}\n' \
  http://127.0.0.1/
```

Repeat against the original failing endpoint and, when relevant, from an affected client. Use the correct virtual-host name, scheme, port, and health path; retain TLS verification. Because this command does not use `--fail`, an HTTP error can have curl exit code zero. Assess HTTP status and expected content separately.

### Step 3 — Form and test a specific hypothesis

| Hypothesis | Evidence to collect | What not to assume |
| --- | --- | --- |
| Invalid nginx configuration | Validation error identifying the actual file/directive; compare with the intended version. | Every failed start means the binary is damaged. |
| Port already occupied | Bind error plus a timestamped listener-to-PID/service mapping. | Every listener on port 80 is an unwanted process. |
| Required access denied | Relevant log entry, full path traversal, worker identity, ownership/mode/ACL/policy. | Every `403` should be fixed with chmod. |
| Resources exhausted | Failure message correlated with the affected filesystem, inode, memory, or service-limit measurements. | High utilization alone establishes the cause. |
| Package installation fault | Affected file ownership, package state, and trusted integrity/version comparison. | Any changed configuration file is corruption. |

For a suspected access issue, set the exact path first:

```bash
AFFECTED_PATH=''
record_check sudo stat -c '%n mode=%a uid=%u gid=%g' \
  "${AFFECTED_PATH:?Set the exact path under investigation}"
record_check sudo namei -l "$AFFECTED_PATH"
```

For a suspected package issue on Ubuntu, identify the actual binary's package owner; adapt this path for another installation:

```bash
record_check dpkg-query -S /usr/sbin/nginx
record_check apt-cache policy nginx
```

The owning binary package may differ from the `nginx` metapackage. Verify that actual package using the local package verification tools. Package metadata alone does not establish corruption or recovery.

### Step 4 — Protect the state and apply a targeted correction

Back up affected files and metadata, identify a known-good version separately, record a rollback plan, and change only what the diagnosis supports. A backup of today's broken state supports reversal of your edit; it does not automatically provide a working configuration.

Use [DEVOPS-009-G: Restore service availability](nginx-restore-service-availability.md) for the selected remediation branch. Validate nginx configuration before applying it. Reload an already running service only when the configuration change requires it; start a stopped service after correcting its cause. A justified restart is narrower than rebooting the host but still changes runtime evidence.

nginx can apply supported configuration changes through a graceful reload. If it cannot apply the new configuration, it retains the old one; confirm the intended change actually took effect rather than treating an active service as proof. [5]

### Step 5 — Verify recovery and document what remains uncertain

Check service state, expected processes, listener ownership, the original failing request, application content/health, and fresh relevant logs. Repeat checks during a recorded observation window and verify from the affected client when needed.

If several changes were made together, document that attribution is uncertain. If an emergency reboot was required, record what evidence could not be captured and schedule the remaining root-cause investigation. Do not claim that a successful request proves the incident cannot recur.

## 5. Decision record template

| Item | Actual entry |
| --- | --- |
| Ticket / engineer / environment | `<details>` |
| Observation start/end (UTC) | `<actual timestamps>` |
| Original symptom and impact | `<URL, client scope, expected/observed behavior>` |
| Baseline evidence | `<log/screenshot references>` |
| Proposed hypothesis | `<specific suspected cause>` |
| Evidence supporting/rejecting it | `<observations and timestamps>` |
| Why a broad action was rejected | `<specific evidence-loss, scope, or security concern>` |
| Chosen action and justification | `<targeted correction or justified emergency recovery>` |
| Backup and rollback | `<actual references and reversal plan>` |
| Verification | `<request, process, listener, log, and resource results>` |
| Remaining uncertainty / prevention | `<follow-up or limitations>` |

This ticket can be completed through a reviewed guidance document. Do not perform a reboot, reinstall, or blanket permission change just to demonstrate that it is a poor response. If using a prior incident as an example, distinguish observed facts from illustrative scenarios.

## Acceptance criteria mapping

| Criterion | Covered by |
| --- | --- |
| Explain why rebooting is a poor first action | Section 1: runtime evidence loss, host-wide disruption, recurrence, and justified exceptions. |
| Explain why reinstalling nginx is a poor first action | Section 2: untested assumptions, package-operation side effects, and reinstall/remove/purge distinctions. |
| Explain why broadly changing permissions is a poor first action | Section 3: excessive access, metadata loss, alternative causes, and targeted repairs. |
| Frame the guidance as evidence-driven troubleshooting | Section 4: timestamped baseline, hypotheses, narrow changes, rollback, and recovery verification. |

## Review checklist

- [ ] All three actions are explained with concrete examples and narrower alternatives.
- [ ] The guidance distinguishes poor first responses from justified recovery actions.
- [ ] Reboot log persistence and reinstall behavior are described accurately.
- [ ] No blanket permission modes are presented as remediation commands.
- [ ] Diagnostic command examples match the intended Linux environment.
- [ ] Illustrative examples and unexecuted checks are not presented as incident evidence.
- [ ] Documentation links and Markdown rendering have been reviewed before merge.

## Related tickets

- **DEVOPS-009-A:** Baseline outage evidence.
- **DEVOPS-009-B:** Service and process inspection.
- **DEVOPS-009-G:** Apply the confirmed fix and verify availability.

## References

1. [systemd: journal storage options](https://www.freedesktop.org/software/systemd/man/latest/journald.conf.html#Storage=)
2. [Ubuntu: apt-get install, reinstall, remove, and purge](https://manpages.ubuntu.com/manpages/noble/man8/apt-get.8.html)
3. [Ubuntu: chmod permission semantics](https://manpages.ubuntu.com/manpages/noble/man1/chmod.1.html)
4. [nginx: configuration test parameters](https://nginx.org/en/docs/switches.html)
5. [nginx: changing configuration and graceful reload](https://nginx.org/en/docs/control.html)

For environment-specific command behavior, consult local `man` pages for `systemctl`, `ps`, `ss`, `stat`, `namei`, `dpkg`, `dpkg-query`, and `curl`.
