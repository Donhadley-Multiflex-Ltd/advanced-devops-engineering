# Linux Operations Runbook

**DEVOPS-010-A: Create the Runbook Structure and Troubleshooting Introduction**

**DEVOPS-010-C: Document High CPU Troubleshooting Steps — Section 13**

**DEVOPS-010-D: Document High Memory Troubleshooting Steps — Section 14**

| Document control | Value |
| --- | --- |
| Purpose | Shared Linux troubleshooting structure, introductory guidance, and High CPU/Memory investigation |
| Version | 0.3 |
| Status | Draft for team review; environment-specific details require completion before operational adoption |
| Created | 2026-11-17 |
| Owner | `<Linux operations team or named owner>` |
| Reviewer | `<technical reviewer>` |
| Repository path | `runbooks/linux/linux-operations-runbook.md` |
| Related Jira tickets | DEVOPS-010-A, DEVOPS-010-C, and DEVOPS-010-D — `<add actual Jira URLs>` |

## Contents

1. [Purpose and troubleshooting introduction](#1-purpose-and-troubleshooting-introduction)
2. [Scope and supported environments](#2-scope-and-supported-environments)
3. [How to use this runbook](#3-how-to-use-this-runbook)
4. [Baseline evidence before changes](#4-baseline-evidence-before-changes)
5. [Shared troubleshooting workflow](#5-shared-troubleshooting-workflow)
6. [Reusable procedure template](#6-reusable-procedure-template)
7. [Troubleshooting procedure index](#7-troubleshooting-procedure-index)
8. [When and how to escalate](#8-when-and-how-to-escalate)
9. [Incident record and handover](#9-incident-record-and-handover)
10. [Recovery verification and closure](#10-recovery-verification-and-closure)
11. [Runbook ownership and maintenance](#11-runbook-ownership-and-maintenance)
12. [Acceptance criteria mapping](#12-acceptance-criteria-mapping)
13. [High CPU troubleshooting](#13-high-cpu-troubleshooting)
14. [High Memory troubleshooting](#14-high-memory-troubleshooting)

## 1. Purpose and troubleshooting introduction

This runbook gives the team a consistent way to investigate Linux operational problems, record decisions, and verify recovery. It combines shared working principles with a reusable structure for service-specific procedures.

Troubleshooting starts with an observed failure, not a guessed fix. Confirm the symptom, establish its impact, gather baseline evidence, form a specific hypothesis, and test it. Apply the smallest justified correction, then repeat the original check to establish whether service was restored.

Keep facts, hypotheses, actions, and results separate. For example, "nginx is inactive" is an observation; "a configuration error prevented startup" is a hypothesis until supported by validation or logs. A successful restart establishes recovery only to the extent verified; it does not automatically establish root cause.

Use UTC timestamps throughout the incident record so engineers can correlate commands, monitoring, logs, and handovers. Preserve original log timestamps and record any different timezone. State uncertainty explicitly and escalate when the next safe action is unclear.

## 2. Scope and supported environments

### In scope

| Area | Covered operational questions |
| --- | --- |
| Services | Is the expected service running, failed, or repeatedly restarting? |
| Processes | Which processes belong to the service, and what state are they in? |
| Logs | Which events correlate with the reported failure and recent changes? |
| Configuration | Does the actual service configuration match the intended, valid state? |
| Local networking | Is the expected address/port listening, and can the affected endpoint be reached? |
| Files and permissions | Can the required service identity access the exact required paths? |
| Resources | Is the failure linked to disk capacity, inodes, memory, CPU, or a service limit? |
| Recovery | What targeted action, rollback, verification, and handover are required? |

### Environment boundaries

The initial command examples assume Ubuntu Linux, Bash, and systemd-managed services. The workflow can be adapted to other Linux distributions, but commands, paths, package tools, and access policies must be reviewed for that environment first.

| Environment detail | Complete for each service or procedure |
| --- | --- |
| Distribution/version | `<actual Linux distribution and version>` |
| Host/service/environment | `<hostname, service, lab/development/staging/production>` |
| Deployment model | `<VM, physical host, container, or orchestrated workload>` |
| Validated command environment | `<where and when the procedure was actually tested>` |
| Required access | `<read-only access, specific sudo actions, or other permissions>` |
| Service owner and escalation route | `<team and current contact/rota link>` |

**Validation status:** No target environment has been validated by creating this document. Windows Git Bash can manage repository files; Linux diagnostics must run on the actual target host or appropriate management platform.

### Outside the generic runbook's authority

Database recovery, application code changes, cloud account/network changes, Kubernetes control-plane operations, storage repair, and security incident response require their relevant specialist procedure and owner. This runbook supports initial evidence gathering and handover for those areas; it does not authorize specialist recovery actions.

## 3. How to use this runbook

1. **Identify the incident.** Open or reference the Jira work item. Record the report, impact, start time, and current incident owner.
2. **Confirm the target.** Check the host, environment, service, and access before running commands. Avoid acting in the wrong SSH session or cloud account.
3. **Check applicability.** Read the selected procedure's scope, prerequisites, expected results, stop conditions, and rollback steps before executing it.
4. **Capture the baseline.** Preserve enough evidence to describe the original failure before changing state.
5. **Follow the decision points.** Execute applicable checks individually. Compare actual results with expected results; do not paste an entire runbook into the shell.
6. **Record each action.** Include UTC time, command/action, result, interpretation, and next decision. Mark skipped or non-applicable checks with a reason.
7. **Apply and verify a justified correction.** Use the service's established incident/change authority. Review impact and rollback before a disruptive action.
8. **Escalate when required.** Use Section 8 rather than repeatedly attempting unsupported fixes.
9. **Close with evidence and improve the guide.** Record the recovery result, remaining uncertainty, and follow-up work; propose documentation improvements through a PR.

Replace placeholders such as `<service>` and `<hostname>` with confirmed values. Do not copy literal placeholders into operational commands. Missing tools, denied access, or an incompatible environment are limitations to record, not evidence that the service itself has failed.

## 4. Baseline evidence before changes

Before a restart, configuration edit, permission change, cleanup, or package operation, record the original symptom and a small diagnostic baseline. Capture the failing request, service/process state, relevant recent logs, listener ownership, recent changes, and any resource or access measurements related to the symptom.

For a basic Ubuntu/systemd check, run on the target host:

```bash
date -u +'%Y-%m-%dT%H:%M:%SZ'
hostname
whoami
uname -r

# Example only: replace nginx.service with the confirmed target unit.
date -u +'%Y-%m-%dT%H:%M:%SZ'
systemctl status nginx.service --no-pager --full
service_check_rc=$?
printf 'systemctl_exit_code=%s\n' "$service_check_rc"
date -u +'%Y-%m-%dT%H:%M:%SZ'
```

These commands show identity, time, and an example service state; they do not provide a complete diagnosis or prove application health. An inactive unit may produce a nonzero exit code. Add the selected procedure's relevant checks and capture their actual output in the incident's approved evidence location.

Keep raw output where practical, with screenshots as supplementary evidence. Record command exit codes immediately after the command, before another command overwrites them. Protect sensitive information and review/redact evidence before committing it to Git or attaching it to Jira. Do not dump credentials or entire configuration trees into a public record.

Gather evidence proportionate to the incident. For severe impact, escalate immediately and gather the practical minimum alongside recovery coordination. Document inaccessible or unavailable evidence instead of delaying necessary recovery indefinitely.

## 5. Shared troubleshooting workflow

| Phase | Required outcome | Decision before proceeding |
| --- | --- | --- |
| Confirm | Reproducible symptom and affected scope | Is the target correct, and is immediate escalation needed? |
| Observe | Timestamped baseline and relevant recent changes | What facts are known, and what remains unknown? |
| Hypothesize | Specific suspected cause and supporting evidence | Which check can distinguish this cause from alternatives? |
| Test | Evidence supporting or rejecting the hypothesis | Is a targeted correction justified? |
| Remediate | Smallest justified change with a rollback plan | Is the action within scope and operational authority? |
| Verify | Original failure retested and service behavior checked | Is availability restored for the affected clients? |
| Close or hand over | Findings, evidence, owner, and next action recorded | Is unresolved risk assigned to someone? |

Change one relevant variable at a time where practical. Avoid defaulting to host reboots, package reinstalls, broad permission changes, or repeated restarts before evidence supports them. When several emergency actions are necessary, record their order and acknowledge any uncertainty about which action restored service.

## 6. Reusable procedure template

Copy the following structure into a new Markdown file for each operational scenario. Keep the section order consistent so another engineer can find the same information quickly. This ticket defines the structure; it does not require every future procedure to be implemented now.

````markdown
# <Service or scenario> Troubleshooting Procedure

## Document control

- Owner: <team/person>
- Reviewer: <reviewer>
- Last reviewed: <YYYY-MM-DD>
- Tested environment/date: <actual validation details, or not yet validated>
- Related Jira/change: <actual links>

## Purpose and symptoms

<Problem this procedure addresses; expected and observed behavior.>

## Scope and exclusions

<Supported hosts, operating systems, deployment model, and boundaries.>

## Prerequisites and impact

<Tools, access, dependencies, operational authority, and potential disruption.>

## Baseline evidence

<UTC timestamp, host/environment, original symptom, relevant command output,
exit codes, monitoring/log links, and recent changes.>

## Diagnostic steps and decisions

| Step | Command or action | Expected result | Interpretation / next action |
| --- | --- | --- | --- |
| 1 | <check> | <expected observation> | <branch or stop condition> |

<Explain each command and identify side effects. Include actual UTC timestamps
in the incident record; examples must not be presented as executed results.>

## Confirmed cause and targeted remediation

<Evidence supporting the diagnosis, exact proposed change, backup, validation,
execution order, and expected result. State when a cause remains unconfirmed.>

## Recovery verification

<Repeat the original failing check; verify service, application, client path,
fresh logs, and a stated observation window appropriate to this service.>

## Rollback

<Trigger, known-good reference, exact reversal steps, dependencies, and
post-rollback verification. Identify irreversible actions.>

## Stop conditions and escalation

<Specific triggers, who to contact, where to hand over evidence, and what
safe diagnostics may continue while waiting.>

## Results and follow-up

<UTC timeline, final state, evidence links, remaining uncertainty, owner,
and prevention/follow-up ticket.>

## References and change history

<Authoritative documentation, related procedures, and reviewed changes.>
````

## 7. Troubleshooting procedure index

Add reviewed procedures as they become available. A planned entry is not an instruction to improvise recovery.

| Scenario | Procedure reference | Adoption status |
| --- | --- | --- |
| nginx service/process inspection | `docs/linux/nginx-service-state-and-process-inspection.md` | Existing training document; confirm repository location and review status |
| nginx targeted recovery | `docs/linux/nginx-restore-service-availability.md` | Existing training document; confirm environment suitability |
| Poor first responses | `docs/linux/nginx-evidence-driven-troubleshooting-first-responses.md` | Existing training guidance; confirm review status |
| High CPU | [Section 13](#13-high-cpu-troubleshooting) | Documented for DEVOPS-010-C; validate against the target environment |
| High Memory | [Section 14](#14-high-memory-troubleshooting) | Documented for DEVOPS-010-D; validate against the target environment |
| Generic service startup failure | `<add reviewed procedure path>` | Planned |
| Resource exhaustion | `<add reviewed procedure path>` | Planned |
| Endpoint/network failure | `<add reviewed procedure path>` | Planned |
| File access/permission failure | `<add reviewed procedure path>` | Planned |

The existing training references are suggested locations, not a claim that those files have been merged, reviewed, or validated in production.

## 8. When and how to escalate

### Escalation triggers

| Trigger | When | Escalate to |
| --- | --- | --- |
| Critical service outage, widening impact, or recovery deadline at risk | Immediately; continue safe evidence gathering in parallel | Incident lead/on-call and service owner |
| Suspected compromise, secret exposure, or unauthorized changes | Immediately | Security response contact and incident lead |
| Possible data loss/corruption or failing storage | Immediately; pause actions that could worsen the condition | Storage/database owner and incident lead |
| Proposed action affects shared infrastructure, many services, or exceeds your access/authority | Before that action | Responsible platform/service owner and applicable change authority |
| Procedure does not match the environment, cause is unclear, or next action is unsafe | As soon as identified | Senior engineer or specialist owner |
| Targeted fix fails, symptoms recur, or rollback fails | At that decision point; do not loop through blind retries | Senior engineer/service owner and incident lead |
| No useful progress within the service's troubleshooting timebox | At the documented threshold, or earlier if impact worsens | On-call escalation route; trainer/mentor for a lab |

**Timebox:** Use the service's documented incident threshold and recovery objective. For this training project, a proposed default is 15 minutes without a new useful finding before asking the trainer for help. This is a lab convention for team review, not a production SLA. If the production threshold is unknown, escalate early rather than assuming the lab timebox applies.

### Contact routing — complete before operational adoption

| Role | Primary route | Backup route |
| --- | --- | --- |
| Incident lead / duty engineer | `<current rota or incident channel>` | `<backup route>` |
| Linux/platform owner | `<team contact>` | `<backup contact>` |
| Application/service owner | `<service contact>` | `<backup contact>` |
| Security response | `<security incident route>` | `<backup route>` |
| Training mentor | `<trainer contact/channel>` | `<backup mentor>` |

If the primary contact does not respond within the team's escalation policy, use the backup route. During a live incident, use the organization's established incident process if these placeholders are incomplete; do not wait for the document to be edited.

### Escalation handover

Provide the incident/Jira reference, impact, affected host/service/environment, UTC timeline, known facts, current hypothesis, relevant evidence, changes already made, rollback state, current availability, and the specific decision or help needed. Name the current incident owner and confirm who has accepted the next action.

Continue non-disruptive diagnostics within your authority while waiting. Coordinate further changes so two responders do not modify the same system independently.

## 9. Incident record and handover

Use one shared incident record. GitHub holds reviewed procedure changes and supporting code; Jira holds the ticket, incident progress, evidence references, and ownership.

| Incident field | Actual entry |
| --- | --- |
| Jira/incident reference | `<actual link>` |
| Incident owner and current responder | `<names/roles>` |
| Host, service, environment | `<confirmed values>` |
| Started / detected (UTC) | `<actual timestamps; distinguish estimated onset>` |
| Impact and expected behavior | `<affected users/services and expected response>` |
| Baseline / recent changes | `<evidence and relevant changes>` |
| Facts and hypotheses | `<label each separately>` |
| Confirmed cause, if established | `<evidence or unconfirmed>` |
| Changes and rollback state | `<actual actions and outcomes>` |
| Escalation and receiving owner | `<time, route, acknowledgement, next action>` |
| Verification / current state | `<actual results and limitations>` |
| Next update / follow-up owner | `<agreed time and person>` |

| UTC timestamp | Responder | Command/action | Result/evidence | Interpretation / next step |
| --- | --- | --- | --- | --- |
| `<actual time>` | `<name>` | `<exact action>` | `<observed result/link>` | `<decision>` |

## 10. Recovery verification and closure

Verify the original symptom is resolved for the affected client path. Service activity alone does not prove application health. Check expected responses/content, relevant dependencies, fresh error logs, and resource behavior as required by the selected procedure.

Record the observation window and actual outcomes. If the service is recovered but root cause is unconfirmed, state both and assign follow-up investigation. If only some clients recover, record partial recovery and keep the remaining impact assigned.

Before closure, record final state, recovery time, evidence links, any workaround, residual risk, and a named owner for preventive actions. Update the runbook through a reviewed PR when a useful procedure is missing or inaccurate.

## 11. Runbook ownership and maintenance

The named document owner maintains scope, contacts, and the procedure index. Procedure owners validate commands in a representative environment and record the validation date, version, and limitations.

Review after a relevant incident, material platform change, or discovery of an incorrect instruction. Agree a periodic review cadence with the team rather than leaving contact routes and environment details indefinitely stale.

Keep changes in GitHub and reference their Jira work items. Review applicability, decision points, side effects, recovery checks, and rollback before adopting a procedure. Do not label an untested command or proposed template as production-validated.

| Date | Version | Change |
| --- | --- | --- |
| 2026-11-17 | 0.1 | Created reusable structure, scope, introduction, usage guidance, baseline note, and escalation model for DEVOPS-010-A |
| 2026-11-17 | 0.2 | Added High CPU investigation using top, sorted ps output, repeated sampling, process ownership, and recent-change correlation for DEVOPS-010-C |
| 2026-11-17 | 0.3 | Added High Memory investigation using free, memory-sorted ps, cache/available/swap interpretation, trends, and pressure evidence for DEVOPS-010-D |

## 12. Acceptance criteria mapping

| Ticket requirement | Coverage |
| --- | --- |
| Reusable Linux operations runbook structure | Contents, consistent workflow, Section 6 copyable procedure template, and Section 7 index |
| Defined scope | Section 2 in-scope areas, supported environment assumptions, and specialist boundaries |
| Guidance on use | Section 3 step-by-step usage and Section 5 shared decisions |
| When to escalate | Section 8 explicit triggers, timing, routing, and handover requirements |
| Brief baseline evidence note | Section 4 minimum capture guidance and timestamped example |
| Consistent team approach | Shared section order, incident timeline, ownership, review, and closure conventions |

### DEVOPS-010-C acceptance criteria

| Ticket requirement | Coverage |
| --- | --- |
| Add a High CPU section | Section 13 |
| Include top | Section 13.3 interactive inspection and Section 13.5 batch sampling |
| Include ps aux --sort=-%cpu | Section 13.4 exact command and interpretation |
| Identify the consuming process | Sections 13.3–13.4: PID, owner, command, service, and optional thread inspection |
| Determine temporary or persistent load | Section 13.5: repeated intervals, monitoring baseline, and explicit limits on the conclusion |
| Determine whether the application recently changed | Section 13.6: release/configuration/dependency timeline and deployed-version evidence |

### DEVOPS-010-D acceptance criteria

| Ticket requirement | Coverage |
| --- | --- |
| Add a High Memory section | Section 14 |
| Include free -h | Section 14.2 timestamped baseline and Section 14.5 repeated capture |
| Include ps aux --sort=-%mem | Section 14.4 exact command and process interpretation |
| Interpret used and available memory | Section 14.3 definitions, version caveat, and examples |
| Interpret cache | Section 14.3 reclaimable cache, overlap, and limits |
| Interpret swap usage | Sections 14.3 and 14.5: allocated swap versus interval swap activity |

**Review boundary:** The foundation and High CPU/Memory procedures require team contacts, operational thresholds, and environment validation before operational adoption. The existence of this document does not demonstrate that a server incident has been investigated or resolved.

## 13. High CPU troubleshooting

### 13.1 Purpose, symptoms, and scope

Identify which process or workload is consuming CPU, establish whether the increase is temporary or persistent, and investigate recent application changes. Possible symptoms include a CPU alert, slow responses, longer job queues, or reduced throughput. High CPU can also represent useful work; establish user impact and expected workload behavior before treating it as a fault.

This procedure covers investigation on Ubuntu/Linux with Bash and procps `top`/`ps`. It does not authorize killing processes, changing priorities, restarting services, rolling back a deployment, or generating stress-test load. Capture evidence first; use a confirmed diagnosis and the service's remediation procedure for changes.

For containers, compare measurements with the workload's allocated CPU and throttling metrics as well as host capacity. Host CPU availability can coexist with a workload-specific CPU limit. Escalate to the platform owner for the correct container/cgroup interpretation. [CPU-3]

### 13.2 Step 1 — Record the baseline and context

Confirm the host, environment, affected application, alert time, normal CPU range, and client impact. Record the CPU threshold and duration used by the actual monitoring alert; do not invent a universal threshold.

Create an evidence directory in the same Bash session:

```bash
umask 077
CPU_EVIDENCE_DIR="$HOME/devops-evidence/DEVOPS-010-C/$(date -u +'%Y%m%dT%H%M%SZ')-$$"
mkdir -p "$CPU_EVIDENCE_DIR"
CPU_EVIDENCE_FILE="$CPU_EVIDENCE_DIR/high-cpu.log"
touch "$CPU_EVIDENCE_FILE"

{
  date -u +'%Y-%m-%dT%H:%M:%SZ'
  hostname
  uptime
  nproc
  date -u +'%Y-%m-%dT%H:%M:%SZ'
} 2>&1 | tee -a "$CPU_EVIDENCE_FILE"
```

Stop relying on the evidence log if directory creation or `tee` reports an error. Use an alternate writable location or remote terminal capture where necessary.

`nproc` provides execution-context CPU information; record any service/container quota separately. Load average is not a CPU percentage and can include tasks waiting on uninterruptible I/O. Compare it with CPU activity, capacity, and service performance rather than declaring CPU saturation from load alone.

### 13.3 Step 2 — Inspect live activity with top

Timestamp the session, then open `top` directly in the terminal:

```bash
date -u +'%Y-%m-%dT%H:%M:%SZ'
top
date -u +'%Y-%m-%dT%H:%M:%SZ'
```

While `top` is running:

| Key / field | Use |
| --- | --- |
| Shift+P (`P`) | Sort processes by CPU usage. |
| `1` | Toggle individual logical CPU summaries. |
| `c` | Toggle command-name/command-line display. |
| PID, USER, %CPU, COMMAND | Identify the consumer and its account. |
| CPU summary | Compare user/system activity, idle time, I/O wait, and VM steal time. |
| `q` | Exit without changing processes. |

Observe several refreshes and record the recurring top PIDs and their CPU usage. Treat the initial frame cautiously; later refreshes provide interval observations. In the usual per-CPU task display, one busy logical CPU is about 100%; a multithreaded process can exceed 100%. Display normalization can change with `top`'s Irix/Solaris mode. Record the mode when comparing values. [CPU-1]

Distinguish a busy process from high I/O wait or VM steal; those observations suggest different investigations. A process at 100% does not by itself prove every CPU on the host is saturated. Capture a timestamped screenshot or use the batch capture below for shareable evidence.

### 13.4 Step 3 — Rank and identify processes with ps

Run the exact CPU-sorted snapshot requested by this ticket:

```bash
{
  date -u +'%Y-%m-%dT%H:%M:%SZ'
  ps aux --sort=-%cpu
  cpu_ps_rc=$?
  printf 'ps_exit_code=%s\n' "$cpu_ps_rc"
  date -u +'%Y-%m-%dT%H:%M:%SZ'
} 2>&1 | tee -a "$CPU_EVIDENCE_FILE"
```

Review the first process rows after the header. Record PID, user, `%CPU`, start time, CPU time, and command. **procps `ps` reports CPU usage averaged over process lifetime**, rather than the current `top` refresh interval. An old busy process may remain high in this ranking, while a new spike in a long-lived process may look modest. Use this snapshot to identify candidates and repeated `top` samples to assess current activity. [CPU-2]

Set the actual PID from your observations before collecting details:

```bash
CPU_PID=''

{
  date -u +'%Y-%m-%dT%H:%M:%SZ'
  ps -p "${CPU_PID:?Set the observed numeric PID}" \
    -o pid,ppid,user,lstart,etime,pcpu,pmem,nlwp,args
  cpu_detail_rc=$?
  printf 'ps_detail_exit_code=%s\n' "$cpu_detail_rc"
  date -u +'%Y-%m-%dT%H:%M:%SZ'
} 2>&1 | tee -a "$CPU_EVIDENCE_FILE"

# For a systemd host, inspect which unit owns that PID if available.
date -u +'%Y-%m-%dT%H:%M:%SZ'
sudo systemctl status "${CPU_PID:?Set the observed numeric PID}" --no-pager --full
```

Check the parent PID, service, owner, start time, and expected business function. A command name alone does not establish the workload's purpose. If the process exits or the PID changes, record that result and identify the new consumer; PIDs can be reused.

For a multithreaded application, optionally inspect its threads:

```bash
date -u +'%Y-%m-%dT%H:%M:%SZ'
top -H -p "${CPU_PID:?Set the observed numeric PID}"
```

Press `P` to sort and `q` to leave. Record whether one thread or several remain busy. Do not sum thread percentages and the parent process total as separate usage. Avoid the kill or priority-changing controls during evidence collection.

### 13.5 Step 4 — Determine whether the load is temporary or persistent

A single snapshot cannot establish persistence. Capture a bounded interval and compare with historical monitoring and the normal workload schedule.

The following batch capture requests 13 frames at five-second refresh intervals, covering roughly one minute. It uses UTC and the C locale for consistent output, and sorts by CPU:

```bash
{
  date -u +'%Y-%m-%dT%H:%M:%SZ'
  env TZ=UTC LC_ALL=C top -b -d 5 -n 13 -o '+%CPU'
  cpu_top_rc=$?
  printf 'top_exit_code=%s\n' "$cpu_top_rc"
  date -u +'%Y-%m-%dT%H:%M:%SZ'
} 2>&1 | tee -a "$CPU_EVIDENCE_DIR/top-intervals.log"
```

Inspect frames after the first. Record the observation start/end, recurring process or workload, approximate interval CPU range, host idle behavior, and application latency/errors. The highest PID may change when workers are short-lived; track the parent/service workload too. A missing process in one later snapshot does not prove the whole workload recovered.

| Observation | Interpretation and next check |
| --- | --- |
| Short burst followed by return to baseline, matching a known startup/job/traffic event | Consistent with temporary load during this window. Confirm the job/event and impact; do not assume it was harmless. |
| Same process/workload stays unusually busy across samples and longer monitoring windows | Persistent within the observed period. Investigate its work, requests, logs, recent changes, and service limits. |
| Bursts repeat on a schedule | Recurring load. Correlate scheduled jobs, timers, queue processing, or periodic traffic. |
| High load average with substantial CPU idle and I/O wait | Investigate storage/dependency waiting; CPU saturation is not established. |
| Current CPU has fallen but alerts/latency continue | Capture the timeline and investigate remaining symptoms; do not close based only on CPU dropping. |

One minute is an initial sample, not a universal persistence threshold. Extend or repeat the observation using the service's alert duration and normal job length. Review available five-, fifteen-minute, or longer monitoring history as appropriate. If history is unavailable, state that the classification is limited to the captured window. Escalate immediately for serious impact rather than waiting for a sampling window to finish.

### 13.6 Step 5 — Check whether the application recently changed

Compare the first observed increase with the actual deployed change timeline. Ask the service owner and inspect GitHub delivery records and Jira change references as applicable.

| Potential change | Evidence to record |
| --- | --- |
| New application release | Deployment time, environment, release/version, deployed commit SHA or image digest, and delivery-run URL. |
| Configuration or feature flag | Exact setting, change time, intended effect, and change record; redact values that are secrets. |
| Dependency/runtime/package update | Previous/current version and when the running service began using it. |
| Restart, rollout, or scaling change | Process start/rollout time, instance count, CPU allocation, and limits. |
| New schedule, batch size, or queue backlog | Job/timer definition, run time, job ID, backlog, and normal execution duration. |
| Changed traffic or input | Request volume, endpoint/input mix, and affected versus unaffected instances. |

After mapping the PID to a service, optionally capture recent unit logs. Set the actual unit first:

```bash
CPU_UNIT=''

{
  date -u +'%Y-%m-%dT%H:%M:%SZ'
  sudo journalctl -u "${CPU_UNIT:?Set the identified service unit}" \
    --since '30 minutes ago' --utc --no-pager -o short-iso-precise -n 100
  cpu_journal_rc=$?
  printf 'journal_exit_code=%s\n' "$cpu_journal_rc"
  date -u +'%Y-%m-%dT%H:%M:%SZ'
} 2>&1 | tee -a "$CPU_EVIDENCE_FILE"
```

Use a time range covering the actual incident; the last 100 entries may not contain its onset. Application/container logs may be elsewhere. For scheduled work on a systemd host, `systemctl list-timers --all --no-pager` can help identify timer schedules; also check the relevant application's job scheduler or cron records.

Repository `git log` describes source history, not proof of what is running. Verify the deployed version through deployment records or a trusted application version endpoint. A CPU increase after a release is a correlation to investigate, not proof of a code regression. Compare pre/post behavior, equivalent traffic, and unaffected instances before recommending a rollback. Process start time can support the timeline but does not by itself identify the release.

Record the recent-change finding as **confirmed change**, **no change found in the reviewed records**, or **unknown because records/access are missing**. Do not turn an unverified "no" into a fact.

### 13.7 Step 6 — Decide the next action and escalate

- Expected work that completes and returns to baseline: document the event and impact; continue the appropriate monitoring window.
- Persistent application work, a suspected hot loop, or a release-correlated change: hand evidence to the application owner for targeted profiling and diagnosis.
- Host contention, high steal, or workload CPU throttling: involve the platform owner with host/workload scope and measurements.
- Serious latency/errors, unclear ownership, missing access, or no useful progress: use the escalation triggers in Section 8.

Do not kill the top CPU process merely because it ranks first. Do not reboot, change CPU limits, or roll back a release based solely on one screenshot. Those actions require an understood impact, the appropriate operational authority, and a recovery/rollback plan.

This ticket documents investigation. No remediation rollback is needed for the diagnostic checks themselves; they generate output/evidence but do not intentionally change service configuration. Optional profiling or remedial actions require their own documented side effects and procedure.

### 13.8 Findings and completion record

| Field | Actual finding |
| --- | --- |
| Host / application / client impact | `<confirmed details>` |
| UTC onset / capture start and end | `<timestamps; mark estimated onset>` |
| Monitoring threshold and normal baseline | `<actual values or unavailable>` |
| CPU capacity / workload limits | `<observed context>` |
| Main consuming PID(s), parent, user, command, and unit | `<actual process/workload identity>` |
| top interval observations | `<range, frames/window, user/system/idle/wait/steal notes>` |
| ps snapshot | `<observations; remember lifetime averaging>` |
| Temporary/persistent/recurring/undetermined | `<classification, evidence, and limits>` |
| Recent application change finding | `<confirmed / none found / unknown; record sources>` |
| Current hypothesis and next check | `<evidence-based statement>` |
| Escalation / next owner | `<role/person, time, agreed action>` |
| Evidence | `<protected log links or reviewed screenshots>` |

Completion checks for an actual investigation:

- [ ] Used `top` and recorded repeated observations.
- [ ] Captured `ps aux --sort=-%cpu` and interpreted lifetime CPU correctly.
- [ ] Identified the consuming process or workload and its owner, or documented the unresolved limitation.
- [ ] Assessed temporary versus persistent/recurring behavior over a stated window.
- [ ] Reviewed recent application changes and recorded the sources and uncertainty.
- [ ] Recorded impact, evidence, and the next action or escalation.

For this documentation ticket, review the procedure against these requirements; do not mark an actual server investigation complete without its evidence. Command lines and logs can contain sensitive arguments or data; keep raw captures protected and share reviewed/redacted copies.

### 13.9 References

- **[CPU-1]** [Ubuntu procps top manual: interval CPU, threads, sorting, and display modes](https://manpages.ubuntu.com/manpages/noble/man1/top.1.html)
- **[CPU-2]** [Ubuntu procps ps manual: process selection, sorting, and lifetime CPU](https://manpages.ubuntu.com/manpages/noble/man1/ps.1.html)
- **[CPU-3]** [Linux kernel cgroup v2 CPU controller](https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html#cpu)
- Local references for the inspected environment: `man top`, `man ps`, `man uptime`, `man nproc`, `man systemctl`, and `man journalctl`.

## 14. High Memory troubleshooting

### 14.1 Purpose, scope, and starting questions

Investigate high memory usage by checking system headroom, identifying large resident processes, and correlating trends with workload and application changes. Determine whether the host or workload is under pressure rather than treating every occupied byte as a fault.

Possible symptoms include a memory alert, slow requests, allocation failures, heavy swapping, or an out-of-memory (OOM) termination. Start by recording the affected host/application, actual impact, onset, alert threshold/duration, normal baseline, and recent changes.

These examples assume Ubuntu/Linux, Bash, and procps `free`, `ps`, and `vmstat`. Run on the target server; Windows Git Bash does not report the remote server's memory. Collect observations without intentionally changing memory settings or service state. No stress-test workload is required for this documentation ticket.

For containers or systemd services with memory limits, identify the workload's limit and accounting separately. Host-level free memory can coexist with a workload-specific OOM. Use platform metrics and the correct cgroup's usage, limit, and event counters; do not assume `free` represents container headroom. [MEM-4]

### 14.2 Step 1 — Capture a timestamped baseline with free -h

Initialize the evidence location in the same Bash session:

```bash
umask 077
MEM_EVIDENCE_DIR="$HOME/devops-evidence/DEVOPS-010-D/$(date -u +'%Y%m%dT%H%M%SZ')-$$"
mkdir -p "$MEM_EVIDENCE_DIR"
MEM_EVIDENCE_FILE="$MEM_EVIDENCE_DIR/high-memory.log"
touch "$MEM_EVIDENCE_FILE"

{
  date -u +'%Y-%m-%dT%H:%M:%SZ'
  hostname
  uptime
  free --version
  free -h
  mem_free_rc=$?
  printf 'free_exit_code=%s\n' "$mem_free_rc"
  date -u +'%Y-%m-%dT%H:%M:%SZ'
} 2>&1 | tee -a "$MEM_EVIDENCE_FILE"
```

Record both the `Mem:` and `Swap:` rows, including total, used, free, buff/cache, and available where shown. `-h` uses human-readable units; rounding may prevent displayed columns from adding up exactly. Keep units with the measurements. Stop relying on this log if file creation or `tee` fails, and use a verified alternate evidence route.

### 14.3 Step 2 — Interpret used, available, cache, and swap

| Field | Interpretation |
| --- | --- |
| Mem total | Usable physical memory reported by the kernel. |
| Mem used | Version-dependent used/unavailable accounting. The referenced Ubuntu procps 4 manual uses `total - available`; older versions can calculate it differently. Check the installed `man free`. It is not a sum of application heaps. |
| Mem free | RAM currently unused; excludes memory occupied by caches. Low free alone does not prove a shortage. |
| Mem available | Estimate of headroom for new applications without swapping, accounting for reclaimable memory and kernel reserves. Prefer it to free alone when assessing host headroom. |
| buff/cache | Buffers plus page cache and reclaimable slab accounting. Cache supports performance; it is not automatically wasted RAM. |
| shared | Mostly tmpfs/shared-memory accounting; it can overlap other categories. Do not add it as an independent memory allocation. |
| Swap total/used/free | Configured swap capacity, its current occupancy, and unused capacity. Swap occupancy does not show the current paging rate. |

See the local version and the referenced definitions before comparing `used` values across hosts or tool upgrades. [MEM-1]

The kernel can reclaim some cache under pressure, but not every cached/shared/dirty byte is immediately reusable. `available` is an estimate, not a guarantee that a particular large allocation will succeed. Do not calculate headroom by adding `available` to `buff/cache`; reclaimable cache is already considered in the estimate. If an application is limited by a cgroup, also check that limit. [MEM-2]

Swap can retain inactive pages after earlier pressure has subsided. Nonzero swap usage with stable available memory and little current paging may reflect history. Sustained swap-in/out with low headroom and degraded response is more concerning. No configured swap is a deployment characteristic to record, not proof of a fault by itself.

**Illustrative examples — these are not measurements from your server:**

| Observation | Reasonable interpretation | Required follow-up |
| --- | --- | --- |
| Only 0.5 GiB free on a 16 GiB host, but about 10 GiB available and substantial cache | Low unused RAM with considerable estimated headroom; shortage is not established. | Check trends, workload limits, and client performance. |
| Available memory remains around 0.3 GiB on that host, swap traffic is sustained, and requests slow down | Evidence consistent with memory pressure. | Identify consumers, compare workload/limits, and inspect OOM/application evidence. |
| 1 GiB of swap remains used while available memory is stable and interval paging is near zero | Swap occupancy alone does not establish current pressure. | Review history and continue an appropriate observation window. |

### 14.4 Step 3 — Identify resident consumers with ps

Capture the exact command required by this ticket:

```bash
{
  date -u +'%Y-%m-%dT%H:%M:%SZ'
  ps aux --sort=-%mem
  mem_ps_rc=$?
  printf 'ps_exit_code=%s\n' "$mem_ps_rc"
  date -u +'%Y-%m-%dT%H:%M:%SZ'
} 2>&1 | tee -a "$MEM_EVIDENCE_FILE"
```

Review the first process rows after the header and record PID, user, `%MEM`, RSS, VSZ, start time, and command.

| Process field | How to use it |
| --- | --- |
| %MEM | Resident set size as a percentage of reported physical RAM; not necessarily percentage of a container's limit. |
| RSS | Resident, non-swapped process memory in the tool's kilobyte units. Use it to identify large resident consumers. |
| VSZ | Virtual address space size; it is not physical RAM consumption and should not alone be called a leak. |
| PID / USER / COMMAND | Identify the consumer, ownership, and expected application role. |

Shared pages can appear in several processes' RSS, so summing RSS can double-count memory. Kernel memory and other accounting also prevent that sum from matching `free` exactly. If accurate shared attribution is needed, ask the application/platform owner for suitable proportional-set-size or workload accounting tools. Large RSS alone does not prove a memory leak. [MEM-3]

Inspect an actual observed PID, after setting it below:

```bash
MEM_PID=''

{
  date -u +'%Y-%m-%dT%H:%M:%SZ'
  ps -p "${MEM_PID:?Set the observed numeric PID}" \
    -o pid,ppid,user,lstart,etime,pmem,rss,vsz,args
  mem_detail_rc=$?
  printf 'ps_detail_exit_code=%s\n' "$mem_detail_rc"
  date -u +'%Y-%m-%dT%H:%M:%SZ'
} 2>&1 | tee -a "$MEM_EVIDENCE_FILE"

# Optional on a systemd host: identify the unit containing that PID.
date -u +'%Y-%m-%dT%H:%M:%SZ'
sudo systemctl status "${MEM_PID:?Set the observed numeric PID}" --no-pager --full
```

Correlate parent/service ownership and process start time. If the process has exited or the PID changes, record that and identify the current workload; do not silently substitute another process. Multiple small workers can matter collectively even when no single PID dominates.

### 14.5 Step 4 — Observe trends and distinguish swap occupancy from activity

Capture repeated measurements before deciding that an increase is persistent. This example records six observations separated by five-second sleeps, spanning roughly 25 seconds plus command time:

```bash
{
  for mem_sample in {1..6}; do
    printf '\nMemory sample %s\n' "$mem_sample"
    date -u +'%Y-%m-%dT%H:%M:%SZ'
    free -h
    mem_sample_rc=$?
    printf 'free_exit_code=%s\n' "$mem_sample_rc"
    if (( mem_sample < 6 )); then
      sleep 5
    fi
  done
  date -u +'%Y-%m-%dT%H:%M:%SZ'
} 2>&1 | tee -a "$MEM_EVIDENCE_DIR/memory-samples.log"
```

Repeat the process snapshot at meaningful points in the same window. Compare available RAM, cache, swap occupancy, and application RSS with normal workload behavior. Extend the window using the actual alert duration, batch-job length, and historical monitoring; a short sample cannot prove long-term stability or a leak.

For interval swap activity, if `vmstat` is available:

```bash
{
  date -u +'%Y-%m-%dT%H:%M:%SZ'
  env TZ=UTC LC_ALL=C vmstat -w -t 5 7
  mem_vmstat_rc=$?
  printf 'vmstat_exit_code=%s\n' "$mem_vmstat_rc"
  date -u +'%Y-%m-%dT%H:%M:%SZ'
} 2>&1 | tee -a "$MEM_EVIDENCE_DIR/vmstat-intervals.log"
```

This requests seven reports about five seconds apart, covering roughly 30 seconds. The first report's rate fields are averages since boot; use subsequent rows for current interval rates. `swpd` is swap occupancy, `si` is swap-in rate, and `so` is swap-out rate. Check the installed manual for displayed units. Correlate repeated activity with available RAM, disk behavior, and application latency; one nonzero interval alone does not establish harmful thrashing. [MEM-5]

If `vmstat` or relevant history is unavailable, record that limitation rather than assuming there is no paging. Even with no swap traffic, allocation failures or cgroup OOM can still occur.

### 14.6 Step 5 — Investigate application changes, limits, and OOM evidence

Check whether the increase matches a deployment, runtime/configuration change, new batch size, queue backlog, traffic growth, worker-count change, or cache warm-up. Record the actual deployed version and change time from delivery records; source commits alone do not prove what is running.

Ask the application owner whether the observed heap/cache/pool size and growth pattern are expected. Continued growth under comparable workload is a reason for profiling, not proof by itself of a leak. Some runtimes retain allocated memory even after work completes.

Where relevant, capture recent kernel events and the identified unit's memory accounting:

```bash
{
  date -u +'%Y-%m-%dT%H:%M:%SZ'
  sudo journalctl -k --since '30 minutes ago' \
    --utc --no-pager -o short-iso-precise -n 200
  mem_kernel_rc=$?
  printf 'kernel_journal_exit_code=%s\n' "$mem_kernel_rc"
  date -u +'%Y-%m-%dT%H:%M:%SZ'
} 2>&1 | tee -a "$MEM_EVIDENCE_DIR/kernel-events.log"

MEM_UNIT=''
date -u +'%Y-%m-%dT%H:%M:%SZ'
systemctl show "${MEM_UNIT:?Set the identified service unit}" \
  --property=MemoryCurrent,MemoryHigh,MemoryMax,ControlGroup
```

Use a log range that covers the actual incident. Look for allocation/OOM messages and correlate their timestamps and victim with the service symptoms. A killed process need not be the original cause of pressure. Missing retained log entries or missing access do not prove no OOM occurred.

For limited workloads, inspect the correct platform/cgroup usage, memory limit, and OOM counters. `MemoryMax` or container `memory.max` differs from total host RAM, and event counters are cumulative; compare changes over the incident window. A host-level `free -h` snapshot cannot exclude a workload-specific limit failure. [MEM-4]

### 14.7 Step 6 — Interpret the evidence and select the next investigation

| Combined evidence | Next action |
| --- | --- |
| Large cache, useful available memory, stable performance | Record current headroom and monitor; no shortage established from free RAM alone. |
| Falling available memory with growing application RSS | Correlate workload/release/runtime behavior and involve the application owner. |
| Low available memory, sustained paging, and latency/errors | Escalate pressure evidence to service/platform owners for targeted recovery. |
| Host has headroom but the workload hits its memory limit or records OOM | Investigate the specific service/container limit and allocation behavior. |
| Swap remains occupied but interval paging is low and performance is normal | Record history/trends; do not claim current thrashing from occupancy alone. |
| No process explains the usage | Investigate shared memory, kernel/slab, cache, and workload accounting with the platform owner. |

Do not drop caches, disable swap, kill the largest process, or reboot merely to reduce a number. Those actions can worsen performance, cause allocation failures, or erase useful state. If a corrective change is justified, document its impact, operational authority, rollback, and verification in the relevant remediation procedure.

Use Section 8's escalation triggers for service impact, repeated OOM, rapid loss of headroom, unknown ownership, missing access, or unclear next actions. Do not wait for an observation window to finish during a serious outage.

The checks here intentionally collect evidence without changing service configuration. They require no service rollback; optional profiling and actual remediation need their own documented procedure. Verify the application behavior as well as memory after any later correction, and retain a suitable observation window.

### 14.8 Findings and completion record

| Field | Actual finding |
| --- | --- |
| Host / workload / impact | `<confirmed details>` |
| UTC onset and observation window | `<actual times; mark estimates>` |
| Installed free version and baseline | `<version, normal behavior, alert threshold/duration>` |
| Total / used / available / free RAM | `<values with units and interpretation>` |
| Cache and shared-memory context | `<measurements and why they matter>` |
| Swap occupancy and current activity | `<used/total plus interval si/so or unavailable>` |
| Main PID(s), account, command, service | `<observed identity and ownership>` |
| RSS / VSZ and trend | `<snapshots, units, and limits on attribution>` |
| Workload memory limit and OOM evidence | `<platform/service scope and event timeline>` |
| Recent changes / workload growth | `<records reviewed; confirmed/none found/unknown>` |
| Assessment | `<no pressure established / suspected pressure / pressure supported; reasons>` |
| Next owner / escalation / action | `<name/role, time, and agreed step>` |
| Evidence references | `<protected logs or reviewed screenshots>` |

For an actual investigation:

- [ ] Captured `free -h` with a UTC timestamp and units.
- [ ] Interpreted used and available memory using the installed tool's accounting.
- [ ] Assessed cache without treating it all as wasted memory or double-counting available RAM.
- [ ] Distinguished swap occupancy from current swap activity, or documented missing evidence.
- [ ] Captured `ps aux --sort=-%mem` and identified candidate consumers.
- [ ] Reviewed trends, application changes, service limits, and OOM evidence as applicable.
- [ ] Recorded impact, uncertainties, and next action/escalation.

This ticket supplies documentation, not a completed incident investigation. Keep raw evidence protected; command arguments and logs may contain sensitive information. Share reviewed/redacted copies through the team's normal incident/PR process.

### 14.9 References

- **[MEM-1]** [Ubuntu procps free manual](https://manpages.ubuntu.com/manpages/noble/man1/free.1.html)
- **[MEM-2]** [Linux kernel proc filesystem: memory accounting and MemAvailable](https://www.kernel.org/doc/html/latest/filesystems/proc.html)
- **[MEM-3]** [Ubuntu procps ps manual: memory fields and process snapshots](https://manpages.ubuntu.com/manpages/noble/man1/ps.1.html)
- **[MEM-4]** [Linux kernel cgroup v2 memory controller and event accounting](https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html#memory)
- **[MEM-5]** [Ubuntu procps vmstat manual: interval rates and swap activity](https://manpages.ubuntu.com/manpages/noble/man8/vmstat.8.html)
- Local references: `man free`, `man ps`, `man vmstat`, `man systemctl`, and `man journalctl` for the inspected environment.

## 15. Disk Space Problems

### 15.1 Purpose, scope, and safety rule

Identify the affected filesystem, locate its largest space consumers, and establish what is growing before choosing a recovery action. Typical symptoms include a disk alert, a failed write with "No space left on device", failed log writes, or an application unable to create files.

**Do not blindly delete files because they are large.** Confirm their purpose, owner, active use, retention requirements, and recovery implications. Database files, container volumes, backups, and active logs may be essential. This procedure provides diagnostic commands; deletion, truncation, pruning, and capacity changes require the appropriate service/storage procedure.

Examples assume Ubuntu/Linux, Bash, and GNU `df`, `du`, `sort`, and `head`. Execute them on the affected server. Record the host, environment, affected application/path, UTC onset, user impact, and recent changes. If the actual full filesystem is elsewhere, investigate that path rather than assuming `/var` is responsible.

Recursive scans generate filesystem I/O and may take time on large or busy trees. Start with the relevant scope, avoid repeated broad scans, and coordinate with the owner if diagnostics could worsen an incident.

### 15.2 Step 1 — Identify the full filesystem with df -h

Capture the initial state in the terminal before assuming a local evidence file can be created:

```bash
date -u +'%Y-%m-%dT%H:%M:%SZ'
hostname
df -h
df -h /var
df -i /var
date -u +'%Y-%m-%dT%H:%M:%SZ'
```

| Column/check | Interpretation |
| --- | --- |
| Filesystem / Mounted on | Identify the device or filesystem and its mount point. |
| Size / Used / Avail | Capacity, consumption, and space available to ordinary users. |
| Use% | Filesystem usage ratio; compare with actual alert thresholds and growth. |
| df -h /var | Shows the filesystem containing `/var`, which may be the root filesystem or a separate mount. |
| df -i /var | Checks inode usage; exhausted inodes can prevent new files even when data-block capacity remains. |

`df` measures filesystem usage, not the size of an individual directory. Use the affected application's actual write path to select the filesystem. Human-readable values are rounded; keep the units with measurements. [DISK-1]

If logs or application data sit on a nested mount, check that exact path too. An apparently large directory on another filesystem may not explain the full one. Where available, `findmnt -T /var` helps identify mount context; inspect other affected paths similarly.

After verifying that the evidence destination is writable and has capacity, initialize the capture location. Replace the destination with a verified alternate mount or use remote terminal capture if the default location is full:

```bash
umask 077
DISK_EVIDENCE_DIR="$HOME/devops-evidence/DEVOPS-010-E/$(date -u +'%Y%m%dT%H%M%SZ')-$$"
mkdir -p "$DISK_EVIDENCE_DIR"
DISK_EVIDENCE_FILE="$DISK_EVIDENCE_DIR/disk-space.log"
touch "$DISK_EVIDENCE_FILE"
```

Stop relying on local logging if creation or `tee` fails. Do not write large scan outputs or configuration backups onto the already exhausted filesystem.

### 15.3 Step 2 — Locate large directories with du -sh /var/*

Run the required summary command:

```bash
{
  date -u +'%Y-%m-%dT%H:%M:%SZ'
  du -sh /var/*
  disk_du_rc=$?
  printf 'du_exit_code=%s\n' "$disk_du_rc"
  date -u +'%Y-%m-%dT%H:%M:%SZ'
} 2>&1 | tee -a "$DISK_EVIDENCE_FILE"
```

`-s` produces one total for each expanded argument; `-h` uses human-readable sizes. Compare entries such as `/var/log`, `/var/lib`, `/var/cache`, and `/var/tmp`, then investigate the largest relevant one. These are allocated-space estimates, not a guarantee that deleting an entry will free that entire amount. [DISK-2]

Permission errors make the measurement incomplete. Keep those errors in the evidence; with authorized access, rerun the same scope as `sudo du -sh /var/*`. Do not suppress errors to make a partial scan look successful.

The shell's `/var/*` pattern normally omits dot-prefixed entries directly beneath `/var`, and this command can traverse nested filesystems. To include hidden children in a directory-level scan while staying on its starting filesystem, use:

```bash
date -u +'%Y-%m-%dT%H:%M:%SZ'
sudo du -xhd1 /var
```

Drill down only into the confirmed large directory. For example, if `/var/log` is the consumer:

```bash
date -u +'%Y-%m-%dT%H:%M:%SZ'
sudo du -xhd1 /var/log
```

Repeat at the relevant child path until the responsible application directory is identified. `-d1` limits displayed depth, not how far `du` must walk to calculate totals. `-x` avoids descending onto different filesystems; it is not a universal boundary for every bind mount or storage abstraction. Check the mount layout when interpreting results.

### 15.4 Step 3 — Rank large entries with du, sort, and head

Use the requested ranking pipeline when the scan scope and temporary-space capacity are appropriate:

```bash
{
  date -u +'%Y-%m-%dT%H:%M:%SZ'
  du -ah /var | sort -rh | head
  disk_pipeline_rc=("${PIPESTATUS[@]}")
  printf 'du_exit_code=%s sort_exit_code=%s head_exit_code=%s\n' \
    "${disk_pipeline_rc[0]}" "${disk_pipeline_rc[1]}" "${disk_pipeline_rc[2]}"
  date -u +'%Y-%m-%dT%H:%M:%SZ'
} 2>&1 | tee -a "$DISK_EVIDENCE_FILE"
```

| Pipeline part | Purpose |
| --- | --- |
| du -ah /var | Lists allocated sizes for files and directory totals under `/var`. |
| sort -rh | Orders human-readable sizes from largest to smallest. |
| head | Shows the first ten output lines by default. |

The result contains **both files and directories**. `/var` or a parent directory can appear above the file causing growth; these totals overlap, so do not add every displayed line together. Follow the large branch down to the relevant files. [DISK-2] [DISK-3] [DISK-4]

**This is not a scan of only ten files.** `du` traverses the tree and `sort` processes its output before the largest entries can be selected. On a large tree, `sort` may need temporary disk space. Prefer the top-down investigation first. If sorting needs an alternate temporary directory, choose one on a verified filesystem with headroom and configure `sort -T <verified-directory>` before the scan; do not choose an arbitrary path on the full filesystem.

Read the per-command exit codes and errors. `head` succeeding does not prove `du` had access to everything or `sort` completed correctly. A `sort` broken-pipe/SIGPIPE result can occur after `head` closes its input; distinguish that from traversal, temporary-space, or read errors. If permissions are insufficient, rerun with authorized `sudo` on `du`; keep the sort/head stages unprivileged unless there is a specific reason otherwise.

For a smaller, filesystem-bounded investigation, adapt the pipeline to the confirmed directory, for example `sudo du -axh /var/log | sort -rh | head`. Review the same permission, overlap, and resource caveats.

### 15.5 Step 4 — Confirm the consumer and explain discrepancies

Record the full path, allocated size, owning application, last modification context, and whether the object is active. For a specific observed path, inspect metadata without changing it:

```bash
DISK_PATH=''
date -u +'%Y-%m-%dT%H:%M:%SZ'
sudo stat -- "${DISK_PATH:?Set the actual large file or directory path}"
df -h "$DISK_PATH"
```

An OS owner account is not necessarily the business/service owner. Correlate the path with application configuration, service logs, container/storage inventory, or the responsible team. Repeat a focused measurement after a suitable interval to determine whether it is still growing; size alone does not identify the cause.

| Finding | Investigation |
| --- | --- |
| Large /var/log subtree | Identify the producing service, growth rate, rotation/retention, and whether verbose logging or repeated errors began recently. |
| Large /var/lib subtree | Determine whether it contains database data, images, layers, or persistent volumes; use the owning product's accounting tools. |
| Large /var/cache subtree | Confirm the cache owner, whether data is regenerable, and its supported retention/cleanup policy. |
| Many small files with full inode usage | Locate the producing directory/job; large-file rankings alone will not explain inode exhaustion. |
| df shows more usage than reachable du totals | Check inaccessible paths, deleted-open files, mount scope, filesystem accounting, snapshots, or reserved space with the storage owner. |
| Write fails despite apparent headroom | Check the exact write path, applicable quota/limit, inode state, read-only condition, and application error; do not assume block exhaustion. |

If deleted-open files are suspected and `lsof` is installed:

```bash
date -u +'%Y-%m-%dT%H:%M:%SZ'
sudo lsof +L1
```

`+L1` lists open files with no remaining directory link. Such files can keep allocated space until their open references are released, so they may appear in `df` usage without a reachable pathname for `du`. Record the device/filesystem, PID, command, file identity, and size. Multiple descriptors can reference the same file; do not blindly sum rows. [DISK-5]

Coordinate any log reopen or controlled service action with the owner; do not kill the PID to reclaim space without understanding its role. If `lsof` is unavailable or permission-limited, record the limitation and escalate. Do not reboot solely to clear the discrepancy.

### 15.6 Step 5 — Plan safe remediation rather than blind deletion

Before changing a consumer, establish:

1. What the file/directory is and which service needs it.
2. Whether it is actively written, open, or referenced by a managed storage system.
3. Which retention, backup, audit, and recovery requirements apply.
4. The targeted supported action, its expected benefit, and its impact.
5. The known-good state or recovery plan, including anything irreversible.

Examples of appropriate **conditional plans**, not instructions to execute automatically:

| Confirmed cause | Plan with the owner |
| --- | --- |
| Unbounded application logging | Correct the writer/verbosity and use reviewed log rotation/retention while preserving incident evidence. |
| Expendable package/application cache | Use the owner's supported cleanup method after checking regeneration/offline requirements. |
| Container image or volume growth | Use the container platform's inventory and supported cleanup; distinguish unused images from required persistent data. |
| Legitimate data growth | Review retention, archive strategy, or capacity expansion. |
| Deleted-open log | Use the service's supported reopen/rotation procedure; consider a controlled restart only when justified. |

Do not manually remove database internals, `/var/lib` contents, active logs, or container volumes to reduce a usage number. Moving data elsewhere on the same filesystem generally does not recover its capacity. A backup made on that filesystem consumes additional space. Some deletion/cleanup actions cannot be undone without an independent retained copy.

### 15.7 Step 6 — Verify the outcome and escalate

After any separately authorized corrective action, repeat `df -h` for the affected path and `df -i` where relevant. Recheck the targeted consumer/growth rate, fresh application errors, and the original failing write or service request using its normal validation procedure. Do not create arbitrary large test files on an already full filesystem.

Record before/after available capacity, inode usage, action/time, and a suitable observation window. A brief reduction is incomplete recovery if the original writer immediately fills the filesystem again.

Use Section 8 escalation guidance for production impact, rapidly falling headroom, unknown data ownership, database/persistent storage, permission limitations, filesystem errors, or any action whose impact/recovery is unclear. A percentage alone is not a universal emergency threshold; use the service's alert policy, available capacity, growth rate, and actual impact.

These diagnostic checks do not intentionally change application configuration or delete application data. They require no service rollback themselves. Actual cleanup, log rotation, service actions, and capacity changes need their own recovery plan and validation.

### 15.8 Findings and completion record

| Field | Actual finding |
| --- | --- |
| Host / service / environment / impact | `<confirmed details>` |
| UTC onset and observation window | `<actual timestamps; mark estimates>` |
| Affected write path and filesystem/mount | `<exact path/device/context>` |
| df baseline / inode baseline | `<size, used, available, use%, inode values>` |
| Largest relevant directories/files | `<paths, allocated sizes, ownership>` |
| Scan scope and limitations | `<mount boundaries, hidden entries, permission errors, command exit codes>` |
| Deleted-open files / discrepancy | `<evidence or unresolved limitation>` |
| Growth and recent changes | `<focused repeated measurements and supporting records>` |
| Targeted plan and recovery implications | `<owner, action, retained evidence, irreversible steps>` |
| After-action verification, if performed | `<actual measurements and original symptom result>` |
| Escalation / next owner / follow-up | `<name/role, time, agreed next step>` |
| Evidence | `<protected captures or reviewed screenshots>` |

For an actual investigation:

- [ ] Used `df -h` to identify the affected filesystem.
- [ ] Checked inodes when relevant to the reported failure.
- [ ] Used `du -sh /var/*` and recorded permission/mount limitations.
- [ ] Used or assessed the suitability of `du -ah /var | sort -rh | head`; recorded any narrower equivalent and reason.
- [ ] Located the largest relevant consumers without double-counting parent totals.
- [ ] Confirmed ownership and purpose before proposing any deletion.
- [ ] Recorded growth, uncertainty, safe next action, and escalation where needed.

This documentation ticket includes command examples, not proof that a production disk was scanned or repaired. Keep raw paths/output protected and share reviewed evidence through the normal incident process.

### 15.9 References

- **[DISK-1]** [Ubuntu/GNU df manual](https://manpages.ubuntu.com/manpages/noble/man1/df.1.html)
- **[DISK-2]** [Ubuntu/GNU du manual](https://manpages.ubuntu.com/manpages/noble/man1/du.1.html)
- **[DISK-3]** [Ubuntu/GNU sort manual](https://manpages.ubuntu.com/manpages/noble/man1/sort.1.html)
- **[DISK-4]** [Ubuntu/GNU head manual](https://manpages.ubuntu.com/manpages/noble/man1/head.1.html)
- **[DISK-5]** [Ubuntu lsof manual: unlinked open files](https://manpages.ubuntu.com/manpages/noble/man8/lsof.8.html)
- Local references for the inspected environment: `man df`, `man du`, `man sort`, `man head`, `man stat`, `man findmnt`, and `man lsof` where installed.

## 16. DNS Problems

### 16.1 Purpose, symptoms, and scope

Investigate endpoints that fail to resolve, return unexpected addresses, or remain unreachable after resolution. Establish what the affected client actually resolves, which resolver answered, and whether the next failure is in DNS, transport, TLS, or the application.

Examples assume Ubuntu/Linux with Bash, BIND `dig`/`nslookup`, `getent`, and `curl`. `resolvectl` examples apply where systemd-resolved is in use. Record missing tooling as a limitation and follow the team's tooling process; do not assume a missing command means DNS is broken.

Run checks from the affected host, container, or equivalent client/network context. A laptop on another network or a host outside the application's container may use a different resolver. Record VPN state, network/interface, and deployment context. This investigation does not change DNS records, resolver configuration, caches, or service state.

### 16.2 Step 1 — Capture client context and resolver configuration

Record the exact failing hostname, URL/scheme/port, error text, UTC onset, client scope, and recent DNS/network/deployment changes. Obtain the expected DNS view and record/target from the service or DNS owner; do not infer the expected answer from memory.

Use a hostname without a scheme, port, path, or final dot in the variable below. Replace the illustrative name before use:

```bash
DNS_NAME='app.example.com'
umask 077
DNS_EVIDENCE_DIR="$HOME/devops-evidence/DEVOPS-010-G/$(date -u +'%Y%m%dT%H%M%SZ')-$$"
mkdir -p "$DNS_EVIDENCE_DIR"
DNS_EVIDENCE_FILE="$DNS_EVIDENCE_DIR/dns-investigation.log"
touch "$DNS_EVIDENCE_FILE"

dns_check() {
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
  } 2>&1 | tee -a "$DNS_EVIDENCE_FILE"
}

dns_check hostname
dns_check cat /etc/resolv.conf
dns_check readlink -f /etc/resolv.conf
dns_check cat /etc/nsswitch.conf
dns_check cat /etc/hosts

# If systemd-resolved is used:
dns_check resolvectl status
```

The wrapper logs command results and continues after diagnostic failures; its own return status is not a remediation gate. Stop relying on local capture if file creation or logging fails. Protect raw output, including internal names/addresses, and share reviewed evidence.

Inspect nameservers, search domains, and resolver options. A loopback entry such as `127.0.0.53` can be a legitimate local stub; it is not automatically a bad DNS server. Where available, `resolvectl status` shows upstream/per-link DNS and routing domains, including VPN-related choices. Do not overwrite a managed `/etc/resolv.conf` as an initial fix. [DNS-3]

### 16.3 Step 2 — Query DNS records with dig

Keep the full response initially so status, resolver, TTL, flags, and timings remain available:

```bash
dns_check dig +time=2 +tries=1 "${DNS_NAME}." A
dns_check dig +time=2 +tries=1 "${DNS_NAME}." AAAA
dns_check dig +time=2 +tries=1 "${DNS_NAME}." CNAME
```

The final dot makes the query name explicitly absolute. `A` requests IPv4, `AAAA` requests IPv6, and `CNAME` checks an alias. Inspect any alias chain and its final address records; absence of a CNAME is normal for a directly addressed name. Preserve the server and response metadata rather than relying only on `+short`. [DNS-1]

| Observation | Interpretation / next check |
| --- | --- |
| NOERROR with expected address/alias data | The queried resolver answered that record lookup; endpoint reachability remains unproven. |
| NXDOMAIN | The name is reported nonexistent in this DNS view. Check spelling, exact FQDN, intended zone/view, and record creation/delegation. |
| NOERROR with no relevant answer | The requested record type may be absent; inspect the response and alias chain. An absent AAAA alone does not mean the name has no A record. |
| SERVFAIL | Resolution/validation failed. DNSSEC, upstream, delegation, or authoritative problems are possible; escalate with the response. |
| REFUSED | The server declined the query; investigate resolver policy/access and whether this is the intended resolver. |
| Timeout / no reachable server | Check resolver service/path, VPN/routes, and DNS transport access. This is different from a negative DNS answer. |
| Unexpected address or alias | Compare with the intended environment and DNS view before declaring the response wrong. |

Read the DNS response status as well as the shell exit code. `dig` can exit zero after receiving a negative DNS response; command completion alone does not mean the name resolved to a usable address. [DNS-1]

### 16.4 Step 3 — Cross-check with nslookup

```bash
dns_check nslookup -type=A "${DNS_NAME}."
dns_check nslookup -type=AAAA "${DNS_NAME}."
```

Record the answering server, address/alias results, and any error. A "Non-authoritative answer" commonly means a recursive resolver answered; that label alone does not indicate a fault. `nslookup` provides another DNS query tool, but two tools using the same resolver are not two independent sources of truth. [DNS-2]

### 16.5 Step 4 — Compare the system lookup path and approved resolvers

DNS tools query DNS servers. An application's lookup may also use hosts files, NSS, a local stub, its own cache, or a custom resolver. Check the system path:

```bash
dns_check getent ahosts "$DNS_NAME"

# Where systemd-resolved is used:
dns_check resolvectl query "$DNS_NAME"
```

`getent` follows the host's NSS configuration for the selected database. Repeated address rows can represent different socket types. An application's browser/runtime/container may still use another lookup mechanism or cache, so record that context rather than assuming the host lookup is identical. [DNS-3] [DNS-4]

If a resolver comparison is warranted, set the IP address of an approved resolver serving the intended DNS view:

```bash
DNS_RESOLVER=''
dns_check dig "@${DNS_RESOLVER:?Set an approved resolver IP address}" \
  +time=2 +tries=1 "${DNS_NAME}." A
dns_check nslookup -type=A "${DNS_NAME}." \
  "${DNS_RESOLVER:?Set an approved resolver IP address}"
```

If transport behavior is suspect, compare a TCP query to the same resolver:

```bash
dns_check dig "@${DNS_RESOLVER:?Set an approved resolver IP address}" \
  +tcp +time=2 +tries=1 "${DNS_NAME}." A
```

A successful TCP query with failing UDP suggests a transport/path-specific investigation; it does not by itself prove a particular firewall rule is wrong. Both paths matter for DNS operation.

Use another approved resolver or authoritative-source evidence only when its view is relevant. Public resolvers may legitimately lack private records; querying them with internal names can disclose those names. Split DNS, geolocation, load balancing, and changing record sets can produce legitimate differences. Compare expected targets/record sets, not merely whether two replies contain identical ordered IP lists.

For stale-looking answers, record response time, resolver, record/alias TTLs, recent change time, and expected previous TTL. Negative responses can also be cached. A current TTL is not a universal "propagation time" or proof of when a record changed. Preserve evidence before any owner-directed cache action; do not blindly flush caches, disable DNSSEC, or switch resolvers.

### 16.6 Step 5 — Separate DNS from HTTPS connectivity

Once the answers are understood, test the original endpoint with its normal scheme, hostname, port, and path. The following examples perform a bounded, direct HTTPS GET to `/`; replace the path if the incident concerns another endpoint:

```bash
dns_check curl --noproxy '*' --connect-timeout 3 --max-time 10 \
  --silent --show-error --dump-header - --output /dev/null \
  --write-out '\nremote_ip=%{remote_ip} http_code=%{http_code} name_lookup_seconds=%{time_namelookup}\n' \
  "https://${DNS_NAME}/"
```

These are direct-path diagnostics. If the environment requires a proxy, follow the intended proxy path and record where name resolution occurs; direct access being blocked does not establish a DNS failure. Avoid attributing a proxy's lookup result to the client's local resolver.

For a controlled comparison, obtain a verified expected IPv4 address from the service owner or deployment record, then override resolution for this curl request only:

```bash
DNS_EXPECTED_IPV4=''
dns_check curl --noproxy '*' --connect-timeout 3 --max-time 10 \
  --resolve "${DNS_NAME}:443:${DNS_EXPECTED_IPV4:?Set the verified expected IPv4 address}" \
  --silent --show-error --dump-header - --output /dev/null \
  --write-out '\nremote_ip=%{remote_ip} http_code=%{http_code}\n' \
  "https://${DNS_NAME}/"
```

`--resolve` substitutes the address for the specified hostname/port while retaining the URL hostname for HTTP and TLS. Certificate validation stays enabled. A bare-IP HTTPS test can fail because the hostname or virtual host differs; do not disable certificate checks to declare success. [DNS-5]

| Comparison | Evidence-based conclusion |
| --- | --- |
| Normal lookup fails, but the verified-address override produces the expected response | Supports a name-resolution/path difference as a lead; compare resolver/application/proxy behavior before assigning root cause. |
| Expected DNS answers exist, but the connection times out or is refused | Investigate route, firewall, listener, proxy, or endpoint state; DNS success does not prove reachability. |
| Connection succeeds but TLS fails | Investigate certificate, hostname/SNI, trust, and time as applicable. |
| HTTP response is unexpected | Investigate the virtual host/application/backend and expected response, alongside the actual destination IP. |
| Behavior differs by address family | Compare A/AAAA answers and IPv4/IPv6 reachability; a valid AAAA can coexist with a broken IPv6 path. |

The examples do not use `--fail`, so an HTTP error may still have curl exit code zero. Compare actual status/content with the agreed endpoint expectation. A successful request to one load-balanced address does not validate every address or backend.

### 16.7 Step 6 — Confirm findings and escalate

Repeat the relevant lookup and request from the originally affected client context and record UTC time. Compare with a known-working client where useful, preserving differences in network, resolver, VPN, address family, application cache, and deployed environment.

Escalate DNS-record/view/validation problems to the DNS owner, resolver reachability or VPN routing to the network/platform owner, and post-resolution TLS/application failures to their responsible owners. Use Section 8 immediately for significant outage impact or an unclear next safe action.

Provide the exact FQDN and query types, client context, resolver IP, full response/status/TTL evidence, expected record source, recent changes, and normal-versus-controlled request results. Separate a confirmed record problem from a suspected cache or connectivity cause.

No resolver configuration rollback is needed for these checks: `--resolve` affects only its curl invocation. Actual DNS-record changes, resolver edits, or cache actions require an owner-directed recovery plan and verification from affected clients.

### 16.8 Findings and completion record

| Field | Actual finding |
| --- | --- |
| Host / application / network / impact | `<affected client, container/VPN/proxy context>` |
| UTC onset and observation time | `<actual times; mark estimates>` |
| Hostname and original URL/port/path | `<exact values>` |
| Expected DNS view and record source | `<owner/zone/deployment evidence>` |
| Configured stub / upstream / approved comparison resolver | `<actual addresses and relevant interface>` |
| dig A / AAAA / CNAME | `<status, answers, aliases, TTLs, answering server, exit code>` |
| nslookup results | `<query type, server, answer/error>` |
| System/application lookup | `<getent/resolvectl/app observations and differences>` |
| Normal endpoint / controlled override | `<actual destination, HTTP/TLS/connection result>` |
| Change/cache context | `<record change time, TTL context, view, uncertainty>` |
| Conclusion and next owner | `<confirmed facts, hypothesis, action/escalation>` |
| Evidence links | `<protected captures or reviewed/redacted screenshots>` |

For an actual investigation:

- [ ] Queried the exact name with `dig` and preserved full response metadata.
- [ ] Cross-checked relevant records with `nslookup`.
- [ ] Compared answers with an owner-confirmed expected DNS view/record.
- [ ] Checked the affected client's system/application resolver context.
- [ ] Distinguished resolution failure from connection, TLS, and HTTP failures.
- [ ] Recorded uncertainty, timestamps, evidence, and escalation/next action.

This ticket documents a procedure; placeholder queries and example addresses are not executed incident evidence. Do not mark name resolution or service recovery confirmed until actual observations support it.

### 16.9 References

- **[DNS-1]** [Ubuntu/BIND dig manual](https://manpages.ubuntu.com/manpages/noble/man1/dig.1.html)
- **[DNS-2]** [Ubuntu/BIND nslookup manual](https://manpages.ubuntu.com/manpages/noble/man1/nslookup.1.html)
- **[DNS-3]** [systemd resolvectl manual](https://www.freedesktop.org/software/systemd/man/latest/resolvectl.html)
- **[DNS-4]** [Ubuntu getent manual: NSS lookups](https://manpages.ubuntu.com/manpages/noble/man1/getent.1.html)
- **[DNS-5]** [curl manual: resolution overrides and connection behavior](https://curl.se/docs/manpage.html#--resolve)
- [ISC BIND manual pages](https://bind9.readthedocs.io/en/latest/manpages.html)
- Local references for the inspected environment: `man dig`, `man nslookup`, `man resolvectl`, `man getent`, `man nsswitch.conf`, `man resolv.conf`, and `man curl`.

