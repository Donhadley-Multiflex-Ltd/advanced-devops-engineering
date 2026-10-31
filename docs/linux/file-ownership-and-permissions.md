# Engineering File Ownership and Permissions

- Jira task: SCRUM-67
- Parent story: SCRUM-64
- Author: Alexander Njoku
- Validation date: 2026-10-31
- Environment: Personal Ubuntu 26.04.1 LTS training server

## Purpose

Configure and verify least-privilege access to engineering files
using chown, chmod, and shared group ownership.

## Accounts

| Account | Role |
| --- | --- |
| engineer | Owns the engineering directory and artifacts |
| engineer2 | Second devops group member used to test collaboration |
| ubuntu | Administrative account, outside devops, used without sudo to test denial |

The engineer and engineer2 accounts were created with password
authentication disabled. No sudo privileges were explicitly granted
to either account.

## Ownership and Permissions

| Path | Owner:Group | Mode | Purpose |
| --- | --- | --- | --- |
| /srv/engineering | engineer:devops | 2770 | Shared engineering workspace |
| /srv/engineering/team-notes.txt | engineer:devops | 660 | Group-readable and group-writable document |
| /srv/engineering/private | engineer:devops | 2700 | Owner-only directory with inherited setgid |
| /srv/engineering/private/config.txt | engineer:devops | 600 | Owner-only sample artifact |

The setgid bit on the shared directory makes new files and
subdirectories inherit the devops group. It does not automatically
grant group write permission.

The private directory prevents group members from accessing its
contents. Its uppercase S in the permission display means setgid is
enabled while group execute permission is absent.

The sample artifact contains training text only, not real secrets.

## Configuration Commands

```bash
sudo groupadd devops
sudo adduser --disabled-password --gecos "" --ingroup devops engineer
sudo adduser --disabled-password --gecos "" --ingroup devops engineer2

sudo mkdir -p /srv/engineering
sudo chown engineer:devops /srv/engineering
sudo chmod 2770 /srv/engineering

sudo -u engineer sh -c 'umask 007; printf "Engineering collaboration notes\n" > /srv/engineering/team-notes.txt'
sudo chmod 660 /srv/engineering/team-notes.txt

sudo -u engineer mkdir -m 700 /srv/engineering/private
sudo -u engineer sh -c 'umask 077; printf "Training example only - no real secrets\n" > /srv/engineering/private/config.txt'
sudo chmod 600 /srv/engineering/private/config.txt
```

These commands record the initial setup on this training server.
They are not an idempotent provisioning script.

## Verified Permission Output

```text
drwxrws--- 2770 engineer:devops /srv/engineering
-rw-rw---- 660 engineer:devops /srv/engineering/team-notes.txt
drwx--S--- 2700 engineer:devops /srv/engineering/private
-rw------- 600 engineer:devops /srv/engineering/private/config.txt
```

## Access Validation

### Owner can read the private artifact

```bash
sudo -u engineer cat /srv/engineering/private/config.txt
```

Actual output:

```text
Training example only - no real secrets
```

### Owner and second group member can collaborate

```bash
sudo -u engineer sh -c 'echo "Original owner: engineer" >> /srv/engineering/team-notes.txt'
sudo -u engineer2 sh -c 'echo "Group collaboration verified by engineer2" >> /srv/engineering/team-notes.txt'
sudo -u engineer2 cat /srv/engineering/team-notes.txt
```

Actual output:

```text
Engineering collaboration notes
Original owner: engineer
Group collaboration verified by engineer2
```

### Second group member cannot read the private artifact

```bash
sudo -u engineer2 cat /srv/engineering/private/config.txt
```

Actual output:

```text
cat: /srv/engineering/private/config.txt: Permission denied
```

### Unrelated user cannot read the shared document

Executed as ubuntu without sudo:

```bash
cat /srv/engineering/team-notes.txt
```

Actual output:

```text
cat: /srv/engineering/team-notes.txt: Permission denied
```

## Least-Privilege Findings

- Engineering collaboration is limited to the owner and devops group.
- Shared text files have no execute permissions.
- Private artifact access is limited to the owner.
- Unrelated users have no access to the engineering workspace.
- Administrative access through sudo can override these restrictions.
- Group write access to the shared directory permits group members
  to manage directory entries, including renaming or removing entries.
  This setup assumes trusted collaborators; it does not provide
  protection against malicious group members.

## Review Status

Configuration and the recorded access tests are complete.
GitHub review and Jira completion remain pending.
