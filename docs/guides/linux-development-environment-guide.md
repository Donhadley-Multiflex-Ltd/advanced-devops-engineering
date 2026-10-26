DEVOPS-006 — Provision Linux Development Environment

## Student Implementation Guide

**Epic:** Engineering Foundations & Linux  
**Sprint:** Sprint 1  
**Week:** Week 2  
**Issue Type:** Story  
**Priority:** Highest  
**Story Points:** 5  
**Component:** Linux Infrastructure  
**Labels:** `week-02`, `linux`, `infrastructure`, `server`, `provisioning`

---

## 1. Purpose

This guide provides the implementation steps for **DEVOPS-006: Provision Linux Development Environment**.

The objective is for each student to provision, validate, secure, and document a Linux environment that will be used throughout the Advanced DevOps Engineering project.

This environment will later support work involving:

- Bash and Python automation
- Docker
- Jenkins
- Kubernetes tooling
- Terraform and Ansible
- CI/CD
- Monitoring and troubleshooting

> **Training rule:** Each student should complete these activities on their **own Linux environment**. Do not use one shared server for all students. Shared servers create conflicts when students modify hostnames, packages, SSH settings, ports, users, permissions, and services.

---

## 2. Target Environment

Ubuntu Server LTS is the recommended baseline.

### Minimum Recommended Resources

| Resource | Minimum |
|---|---:|
| CPU | 2 vCPU |
| Memory | 2 GB for Week 2; 4 GB+ recommended for later modules |
| Storage | 20 GB |
| Network | Internet connectivity |
| Remote Access | SSH |
| User Access | Non-root user with `sudo` privileges |

The environment may be hosted on:

- A cloud virtual machine
- VirtualBox
- VMware
- Hyper-V
- WSL for selected local exercises
- Another instructor-approved Linux platform

> A full Linux VM is preferred over WSL for service-management and networking exercises because it more closely represents a production Linux server.

---

## 3. Completion Workflow

Students should work through the subtasks in this order:

```text
DEVOPS-006-A  Provision Linux Host
      ↓
DEVOPS-006-B  Configure Hostname and Base Identity
      ↓
DEVOPS-006-C  Update the Operating System
      ↓
DEVOPS-006-D  Verify Hardware Resources
      ↓
DEVOPS-006-E  Verify Network Connectivity and DNS
      ↓
DEVOPS-006-F  Enable and Verify SSH Access
      ↓
DEVOPS-006-G  Capture Operating System Information
      ↓
DEVOPS-006-H  Document the Linux Environment
```

Do not mark a subtask Done simply because a command executed. The required **validation and evidence** must also be completed.

---

# 4. DEVOPS-006-A — Provision the Linux Host

**Jira:** SCRUM-60  
**Objective:** Create or obtain the Linux host that will serve as the student's engineering environment.

## Steps

### Step 1 — Provision the Host

Create an Ubuntu Server LTS environment using the platform approved by the instructor.

If using a cloud VM, ensure that:

- The instance is running.
- A public or reachable private IP is available.
- SSH access is permitted.
- The VM is not exposed to unnecessary inbound ports.

If using VirtualBox, VMware, or Hyper-V, ensure that:

- The VM boots successfully.
- Network connectivity is configured.
- The student can log in locally.
- The VM has sufficient CPU, RAM, and disk.

### Step 2 — Log In

Log in using the account created during provisioning.

Verify the current user:

```bash
whoami
```

Verify the current working directory:

```bash
pwd
```

### Step 3 — Verify `sudo` Access

Run:

```bash
sudo whoami
```

Expected output:

```text
root
```

This confirms that the normal student account can perform approved administrative tasks without logging in directly as root.

### Step 4 — Check System Uptime

```bash
uptime
```

### Validation

The host must:

- Boot successfully.
- Allow the student to log in.
- Provide a non-root user.
- Allow approved `sudo` operations.
- Have sufficient resources for the exercise.

### Evidence

Capture or record:

```bash
whoami
hostname
uptime
```

Do **not** commit passwords, private SSH keys, cloud access keys, tokens, or other secrets to GitHub.

---

# 5. DEVOPS-006-B — Configure Hostname and Base Identity

**Jira:** SCRUM-59  
**Objective:** Assign a clear and consistent hostname to the Linux host.

## Naming Standard

Recommended pattern:

```text
devops-studentXX
```

Examples:

```text
devops-student01
devops-student02
devops-student03
```

A named lab convention may also be used:

```text
devops-bernard-01
```

Avoid vague hostnames such as:

```text
ubuntu
server
vm1
test
```

These names do not scale well in real environments.

## Steps

### Step 1 — Check the Existing Hostname

```bash
hostname
```

and:

```bash
hostnamectl
```

### Step 2 — Change the Hostname

Example:

```bash
sudo hostnamectl set-hostname devops-student01
```

Replace `devops-student01` with the hostname allocated to you.

### Step 3 — Verify the Change

```bash
hostname
```

```bash
hostnamectl
```

### Step 4 — Review `/etc/hosts`

```bash
cat /etc/hosts
```

If the local hostname is explicitly referenced there, ensure the entry remains consistent with the new hostname.

Use an editor only when a change is required:

```bash
sudo nano /etc/hosts
```

or:

```bash
sudo vim /etc/hosts
```

### Validation

Confirm that:

```bash
hostname
```

returns the approved hostname.

### Evidence

Record:

- Previous hostname, if applicable
- New hostname
- `hostnamectl` output

---

# 6. DEVOPS-006-C — Update the Operating System

**Jira:** SCRUM-58  
**Objective:** Bring the operating system packages up to date before installing project tooling.

## Why This Matters

Starting from an outdated host creates unnecessary security and compatibility risk.

In production environments, updates should follow an approved patching process. For this training environment, students will update their own newly provisioned host.

## Steps

### Step 1 — Refresh Package Metadata

```bash
sudo apt update
```

Review the output. Do not ignore repository errors.

### Step 2 — Review Available Upgrades

```bash
apt list --upgradable
```

### Step 3 — Apply Package Upgrades

```bash
sudo apt upgrade -y
```

### Step 4 — Check Whether a Reboot Is Required

```bash
if [ -f /var/run/reboot-required ]; then
  cat /var/run/reboot-required
else
  echo "No reboot currently required"
fi
```

If a reboot is required and this is your isolated training VM:

```bash
sudo reboot
```

Reconnect after the machine starts.

### Step 5 — Install Base Utilities

```bash
sudo apt install -y \
  curl \
  wget \
  git \
  vim \
  jq \
  unzip \
  tree \
  net-tools \
  dnsutils \
  htop
```

### Step 6 — Verify the Tools

```bash
git --version
curl --version
wget --version
jq --version
tree --version
```

For interactive tools such as `vim` and `htop`, verify that the command starts successfully.

### Validation

Confirm:

- `sudo apt update` completes without repository errors.
- Required updates are installed.
- Required utilities are available.
- Any required reboot has been completed.

### Evidence

Record:

```bash
git --version
curl --version
jq --version
```

Do not paste hundreds of lines of package output into documentation. Capture concise, useful evidence.

---

# 7. DEVOPS-006-D — Verify Hardware Resources

**Jira:** SCRUM-56  
**Objective:** Confirm that the host has sufficient CPU, memory, and storage.

## Steps

### Step 1 — Check CPU

```bash
lscpu
```

Focus on:

- Architecture
- CPU count
- Model
- Virtualization information where applicable

A concise CPU count can also be obtained with:

```bash
nproc
```

### Step 2 — Check Memory

```bash
free -h
```

Understand the difference between:

- Total
- Used
- Free
- Buff/cache
- Available

### Step 3 — Check Filesystem Capacity

```bash
df -h
```

Focus on the root filesystem `/`.

### Step 4 — Inspect Block Devices

```bash
lsblk
```

### Step 5 — Check Disk Usage by Filesystem Type

Optional:

```bash
df -Th
```

### Minimum Validation

The training host should normally have at least:

```text
2 vCPU
2 GB RAM for Week 2
20 GB storage
```

More memory will be required as the course progresses.

### Evidence

Capture the relevant output from:

```bash
nproc
free -h
df -h /
lsblk
```

### Troubleshooting Check

If the host does not meet the minimum requirement, do not continue blindly.

Document the issue and either:

- Resize the VM.
- Increase memory.
- Increase disk.
- Re-provision the environment.

---

# 8. DEVOPS-006-E — Verify Network Connectivity and DNS

**Jira:** SCRUM-57  
**Objective:** Verify that the host can communicate on the network, reach external services, and resolve DNS names.

## Steps

### Step 1 — Inspect Network Interfaces

```bash
ip addr
```

Identify:

- Active interface
- IPv4 address
- Loopback interface

A shorter view:

```bash
ip -br addr
```

### Step 2 — Inspect Routing

```bash
ip route
```

Identify the default route.

### Step 3 — Test Local TCP/IP

```bash
ping -c 4 127.0.0.1
```

### Step 4 — Test IP Connectivity

```bash
ping -c 4 8.8.8.8
```

> Some networks block ICMP. A failed ping alone does not prove that internet access is unavailable.

### Step 5 — Test HTTP/HTTPS Connectivity

```bash
curl -I https://github.com
```

A successful HTTP response proves useful connectivity even when ping is blocked.

### Step 6 — Verify DNS Resolution

```bash
dig github.com
```

Also test:

```bash
getent hosts github.com
```

### Step 7 — Inspect DNS Configuration

Depending on the environment:

```bash
resolvectl status
```

If `resolvectl` is not available:

```bash
cat /etc/resolv.conf
```

### Validation

The host should demonstrate:

- An assigned IP address
- A default route
- External connectivity
- Working DNS resolution
- HTTPS connectivity

### Evidence

Record concise results from:

```bash
ip -br addr
ip route
curl -I https://github.com
dig github.com
```

### Troubleshooting Logic

If IP connectivity works but:

```bash
dig github.com
```

fails, suspect DNS rather than general network connectivity.

Do not change DNS settings until evidence supports that diagnosis.

---

# 9. DEVOPS-006-F — Enable and Verify Secure SSH Access

**Jira:** SCRUM-61  
**Objective:** Ensure the Linux environment can be managed remotely using SSH.

## Steps

### Step 1 — Check Whether SSH Server Is Installed

```bash
dpkg -l | grep openssh-server
```

If it is not installed:

```bash
sudo apt install -y openssh-server
```

### Step 2 — Enable and Start SSH

```bash
sudo systemctl enable --now ssh
```

### Step 3 — Verify Service Health

```bash
sudo systemctl status ssh --no-pager
```

The service should report:

```text
active (running)
```

### Step 4 — Verify Listening Port

```bash
sudo ss -tulpn | grep ':22'
```

### Step 5 — Determine the Host IP

```bash
hostname -I
```

or:

```bash
ip -br addr
```

### Step 6 — Connect from the Student Workstation

From the workstation:

```bash
ssh <username>@<server-ip>
```

Example:

```bash
ssh devops@192.168.1.50
```

### Step 7 — Use SSH Key Authentication

If a key pair does not already exist on the workstation:

```bash
ssh-keygen -t ed25519
```

Copy the public key:

```bash
ssh-copy-id <username>@<server-ip>
```

Reconnect:

```bash
ssh <username>@<server-ip>
```

### Security Rules

- Never commit a private SSH key.
- Do not copy private keys between students.
- Do not enable root SSH login for convenience.
- Do not expose SSH to the public internet unless required and properly restricted.
- If using a cloud security group, restrict port 22 to an appropriate source where practical.

### Validation

Confirm:

- SSH service is enabled.
- SSH service is running.
- Port 22 is listening.
- Remote login works.
- Key-based authentication works where required.

### Evidence

Record:

```bash
systemctl is-enabled ssh
systemctl is-active ssh
```

Expected:

```text
enabled
active
```

---

# 10. DEVOPS-006-G — Capture Operating System and Host Information

**Jira:** SCRUM-62  
**Objective:** Collect a concise technical baseline of the environment.

## Steps

Run the following commands:

### Host Identity

```bash
hostnamectl
```

### Operating System

```bash
cat /etc/os-release
```

### Kernel

```bash
uname -a
```

For a cleaner kernel version:

```bash
uname -r
```

### CPU

```bash
lscpu
```

### Memory

```bash
free -h
```

### Filesystem

```bash
df -h
```

### Block Devices

```bash
lsblk
```

### Network

```bash
ip -br addr
```

```bash
ip route
```

### SSH

```bash
systemctl is-active ssh
```

### Installed Base Tools

```bash
git --version
curl --version
jq --version
```

## Evidence Standard

Do not dump all command output into one unreadable text file.

Extract the information that another engineer actually needs to understand the environment.

Recommended baseline fields:

| Field | Example |
|---|---|
| Hostname | `devops-student01` |
| OS | Ubuntu Server LTS |
| Kernel | Linux kernel version |
| CPU | 2 vCPU |
| Memory | 2 GB / 4 GB |
| Root Disk | 20 GB |
| IP Address | Private/lab IP |
| Default Route | Gateway |
| DNS | Working |
| SSH | Active |
| Git | Installed |
| curl | Installed |
| jq | Installed |

> Avoid publishing public IP addresses or other sensitive infrastructure details in a public repository unless there is a legitimate training requirement.

---

# 11. DEVOPS-006-H — Document the Linux Environment

**Jira:** SCRUM-63  
**Objective:** Create a clear environment record in the project repository.

## Required File

Create:

```text
docs/linux/environment.md
```

Create the directory if it does not exist:

```bash
mkdir -p docs/linux
```

Create the file:

```bash
touch docs/linux/environment.md
```

## Required Documentation Structure

Use the following structure:

```markdown
# Linux Development Environment

## Purpose

Describe what the environment is used for.

## Host Information

- Hostname:
- Operating System:
- Kernel:
- CPU:
- Memory:
- Disk:

## Network

- Primary Interface:
- IP Address:
- Default Route:
- DNS Status:
- Internet Connectivity:

## Remote Access

- SSH Status:
- SSH Port:
- Authentication Method:

## Installed Base Tools

| Tool | Version | Purpose |
|---|---|---|
| Git | | Source control |
| curl | | HTTP testing |
| wget | | File retrieval |
| jq | | JSON processing |
| vim | | Text editing |
| tree | | Directory visualization |
| htop | | Process/resource monitoring |

## Validation

Describe the checks performed to confirm that the environment is operational.

## Known Limitations

Document any relevant limitations.

## Security Notes

Confirm that no passwords, private keys, tokens, or secrets are stored in this file.
```

## Documentation Quality Standard

The document should allow another engineer to answer:

1. What is this server?
2. What operating system is running?
3. Does it meet the resource requirement?
4. Is networking operational?
5. Is DNS working?
6. Is SSH operational?
7. Which base tools are installed?
8. Are there known limitations?

### Validation

Preview the Markdown before submitting it.

Ensure:

- Headings are consistent.
- Tables render correctly.
- Commands are readable.
- No secrets are present.
- Information is concise and accurate.

---

# 12. Git and GitHub Submission Workflow

All student work should be traceable to the Jira story.

## Step 1 — Synchronize Local `main`

```bash
git checkout main
git pull origin main
```

## Step 2 — Create a Feature Branch

Recommended:

```bash
git checkout -b feature/DEVOPS-006-linux-environment
```

If your course uses Jira issue keys in branch names, follow the instructor's established convention.

## Step 3 — Add the Documentation

```bash
git add docs/linux/environment.md
```

Review what will be committed:

```bash
git status
git diff --staged
```

## Step 4 — Commit

```bash
git commit -m "DEVOPS-006: document Linux engineering environment"
```

## Step 5 — Push

```bash
git push -u origin feature/DEVOPS-006-linux-environment
```

## Step 6 — Create a Pull Request

Recommended PR title:

```text
DEVOPS-006: Provision Linux development environment
```

The PR should include:

- Jira reference
- Summary of completed work
- Validation performed
- Relevant evidence
- Known limitations
- Confirmation that no secrets were committed

## Step 7 — Peer Review

The reviewer should verify:

- Documentation accuracy
- Required validation evidence
- No secrets
- Naming standards
- Acceptance criteria
- Markdown quality

## Step 8 — Merge

Merge only after required review and checks pass.

---

# 13. Final Acceptance Checklist

Before moving DEVOPS-006 to Done, verify all items.

## Host

- [ ] Personal Linux host provisioned
- [ ] Non-root user can log in
- [ ] `sudo` access works
- [ ] Hostname follows naming standard

## Operating System

- [ ] Package metadata updated
- [ ] Available package upgrades applied
- [ ] Required base tools installed

## Resources

- [ ] CPU verified
- [ ] Memory verified
- [ ] Disk verified
- [ ] Block devices inspected

## Network

- [ ] IP address identified
- [ ] Default route verified
- [ ] External connectivity tested
- [ ] DNS resolution verified
- [ ] HTTPS connectivity verified

## SSH

- [ ] `openssh-server` installed
- [ ] SSH service enabled
- [ ] SSH service active
- [ ] Port 22 verified
- [ ] Remote login tested
- [ ] Key-based login tested where required

## Documentation

- [ ] `docs/linux/environment.md` created
- [ ] Environment details documented
- [ ] Validation results documented
- [ ] No secrets included

## GitHub

- [ ] Feature branch created
- [ ] Jira/story reference used
- [ ] Commit created
- [ ] Branch pushed
- [ ] Pull Request opened
- [ ] Peer review completed
- [ ] Pull Request merged

## Jira

- [ ] DEVOPS-006-A completed
- [ ] DEVOPS-006-B completed
- [ ] DEVOPS-006-C completed
- [ ] DEVOPS-006-D completed
- [ ] DEVOPS-006-E completed
- [ ] DEVOPS-006-F completed
- [ ] DEVOPS-006-G completed
- [ ] DEVOPS-006-H completed
- [ ] Parent Story acceptance criteria satisfied

---

# 14. Common Mistakes to Avoid

## Using Root for Everything

Do not routinely log in as `root`.

Use a normal user and elevate only when required:

```bash
sudo <command>
```

## Blindly Copying Commands

Students must understand what a command changes before running it.

## Publishing Secrets

Never commit:

- Passwords
- Private SSH keys
- API tokens
- Cloud credentials
- Personal access tokens

## Assuming Ping Equals Internet Access

ICMP may be blocked.

Use multiple tests:

```bash
ping
curl
dig
```

## Ignoring Package Errors

If:

```bash
sudo apt update
```

returns repository errors, investigate them before continuing.

## Using `chmod 777` as a Fix

Do not weaken permissions to bypass an access problem.

Understand the ownership and permission requirement first.

## Marking Work Done Without Validation

Installation is not validation.

Example:

```bash
sudo apt install openssh-server
```

does not prove that SSH is running or reachable.

You must check:

```bash
systemctl is-active ssh
ss -tulpn | grep ':22'
```

and actually test the connection.

---

# 15. Student Knowledge Check

At completion, each student should be able to explain:

1. Why each student uses an individual Linux environment.
2. Why Ubuntu Server LTS is suitable for a training baseline.
3. What `hostnamectl` is used for.
4. The difference between `apt update` and `apt upgrade`.
5. How to inspect CPU, memory, and disk.
6. How to identify an IP address and default route.
7. How to distinguish network connectivity from DNS resolution.
8. What SSH is used for.
9. Why key-based SSH authentication is preferred.
10. Why normal users should use `sudo` instead of routinely operating as root.
11. Why environment information belongs in version-controlled documentation.
12. Why secrets must never be committed to Git.
13. What evidence is required before a Jira ticket can be marked Done.

---

# 16. Expected Outcome

At the end of DEVOPS-006, every student should have:

```text
Individual Linux Environment
          │
          ├── Standard Hostname
          ├── Updated OS
          ├── Required Utilities
          ├── Verified CPU / Memory / Disk
          ├── Working Network
          ├── Working DNS
          ├── Secure SSH Access
          └── Documented Baseline
                    │
                    ▼
              GitHub Pull Request
                    │
                    ▼
                 Review
                    │
                    ▼
               Jira Done
```

The environment is now ready for the remaining Week 2 Linux administration exercises and later Bash, Python, Docker, CI/CD, Kubernetes, and infrastructure automation work.
"""
