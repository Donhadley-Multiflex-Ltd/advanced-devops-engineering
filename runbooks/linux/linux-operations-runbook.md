# Linux Operations Runbook

**DEVOPS-010-A: Create the Runbook Structure and Troubleshooting Introduction**

| Document control | Value |
| --- | --- |
| Purpose | Shared structure and introductory guidance for Linux operations troubleshooting |
| Version | 0.1 |
| Status | Draft for team review; environment-specific details require completion before operational adoption |
| Created | 2026-11-17 |
| Owner | `<Linux operations team or named owner>` |
| Reviewer | `<technical reviewer>` |
| Repository path | `docs/linux/linux-operations-runbook.md` |
| Related Jira ticket | DEVOPS-010-A — `<add actual Jira URL>` |

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

## 12. Acceptance criteria mapping

| Ticket requirement | Coverage |
| --- | --- |
| Reusable Linux operations runbook structure | Contents, consistent workflow, Section 6 copyable procedure template, and Section 7 index |
| Defined scope | Section 2 in-scope areas, supported environment assumptions, and specialist boundaries |
| Guidance on use | Section 3 step-by-step usage and Section 5 shared decisions |
| When to escalate | Section 8 explicit triggers, timing, routing, and handover requirements |
| Brief baseline evidence note | Section 4 minimum capture guidance and timestamped example |
| Consistent team approach | Shared section order, incident timeline, ownership, review, and closure conventions |

**Review boundary:** This ticket creates the runbook foundation. Team contacts, operational thresholds, and service-specific procedures must be completed and reviewed for the intended environment before operational adoption. The existence of this document does not demonstrate that a server incident has been investigated or resolved.

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
