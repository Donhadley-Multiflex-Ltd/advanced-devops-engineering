# Numeric Linux Permissions

**Owner:** Peabsmart Academy  
**Ticket:** DEVOPS-007-E — Demonstrate and Explain Numeric Linux Permissions  
**Suggested repository path:** `docs/guides/numeric-linux-permissions.md`

## Purpose

Explain how to interpret numeric Linux permissions, demonstrate common modes, and justify permissions using least privilege for the owner, owning group, and others.

## Prerequisites

- An Ubuntu/Linux terminal, including Ubuntu on WSL.
- A normal user account with access to `chmod`, `ls`, and GNU `stat`.
- Run the demonstration in the same Bash session. No `sudo` is required.

## 1. Understand Permission Classes

The three digits in a basic numeric permission mode represent these classes, from left to right:

| Position | Class | Meaning |
|---|---|---|
| First | User/owner | The user who owns the file |
| Second | Group | The group that owns the file |
| Third | Others | Users who are neither the owner nor members of the owning group |

In symbolic commands, these classes are represented by `u`, `g`, and `o`.

Check ownership and permissions with:

```bash
ls -l example.txt
```

For example:

```text
-rw-r----- 1 learner devops 42 Nov 5 12:00 example.txt
```

Here, `learner` is the owner and `devops` is the owning group. The initial `-` means the object is a regular file. A directory has an initial `d`. Names, size, and timestamp vary.

## 2. Calculate Each Permission Digit

Numeric permissions use octal (base 8). Each permission has a value:

| Permission | Symbol | Value | Meaning for a regular file |
|---|---|---:|---|
| Read | `r` | 4 | Read the contents |
| Write | `w` | 2 | Modify the contents |
| Execute | `x` | 1 | Attempt to run the file as a program |
| No permission | `-` | 0 | That permission is absent |

Add the required values for each class:

| Digit | Calculation | Symbolic permissions |
|---:|---|---|
| 0 | None | `---` |
| 1 | 1 | `--x` |
| 2 | 2 | `-w-` |
| 3 | 2 + 1 | `-wx` |
| 4 | 4 | `r--` |
| 5 | 4 + 1 | `r-x` |
| 6 | 4 + 2 | `rw-` |
| 7 | 4 + 2 + 1 | `rwx` |

For example, read and write gives `4 + 2 = 6`.

## 3. Interpret `640`

| Class | Digit | Calculation | Permissions | Allowed access |
|---|---:|---|---|---|
| Owner | 6 | 4 + 2 | `rw-` | Read and modify |
| Group | 4 | 4 | `r--` | Read only |
| Others | 0 | None | `---` | No access granted by these bits |

For a regular file, `640` appears as:

```text
-rw-r-----
```

No class receives execute permission.

## 4. Demonstrate Numeric Permissions

### Create a disposable test file

```bash
permission_lab_dir=$(mktemp -d /tmp/devops-007-e.XXXXXX)

printf 'Peabsmart Academy permission demonstration\n' \
  > "$permission_lab_dir/example.txt"

chmod 640 "$permission_lab_dir/example.txt"
```

Use this test file rather than changing permissions on system files or live application files.

### Inspect permissions and ownership

```bash
ls -l "$permission_lab_dir/example.txt"

stat -c 'Mode: %a | Permissions: %A | Owner: %U | Group: %G' \
  "$permission_lab_dir/example.txt"
```

The `stat` output should start with:

```text
Mode: 640 | Permissions: -rw-r-----
```

The owner and group fields show the actual names on your machine.

### Demonstrate the owner's access

```bash
# Read the file.
cat "$permission_lab_dir/example.txt"

# Append content as its owner.
printf 'The owner can append content.\n' \
  >> "$permission_lab_dir/example.txt"

# Verify the appended content.
cat "$permission_lab_dir/example.txt"

# Check whether this account has execute access.
if [ -x "$permission_lab_dir/example.txt" ]; then
  echo "Execute permission is present"
else
  echo "Execute permission is absent"
fi
```

Expected results:

- Reading succeeds.
- Appending succeeds.
- The final command prints `Execute permission is absent`.

These commands test access as the current user. They do not test access using separate group-member or other-user accounts. The mode inspection establishes the group and others permission bits.

The temporary directory created by `mktemp -d` is private to its owner. Even if the file grants group read permission, another account also needs traversal permission on every parent directory to reach it.

### Compare common modes

```bash
for mode in 600 640 644 700 750 755; do
  chmod "$mode" "$permission_lab_dir/example.txt"
  stat -c '%a %A' "$permission_lab_dir/example.txt"
done

# Restore the selected mode.
chmod 640 "$permission_lab_dir/example.txt"
```

Expected comparison output:

```text
600 -rw-------
640 -rw-r-----
644 -rw-r--r--
700 -rwx------
750 -rwxr-x---
755 -rwxr-xr-x
```

Giving a file execute permission does not make its contents a valid program.

## 5. Choose Permissions Using Least Privilege

Assume a configuration file has these requirements:

- Its owner maintains it.
- A trusted owning group needs to read it.
- Other users have no reason to access it.
- The file does not need to run as a program.

Choose `640`:

| Class | Required work | Chosen access | Least-privilege justification |
|---|---|---|---|
| User/owner | Read and maintain configuration | `6` / `rw-` | Allows maintenance; omits unnecessary execution |
| Group | Read configuration | `4` / `r--` | Allows reading; prevents direct modification and execution through these bits |
| Others | None | `0` / `---` | Grants no unnecessary access |

Least privilege depends on actual requirements. If the group does not need access, choose `600` instead. If the group does need access, verify both the owning group and its membership; `640` alone does not ensure that the right people receive access. A file containing secrets should only be readable by accounts that require those secrets.

### Common choices

| Mode | Owner | Group | Others | Typical use |
|---|---|---|---|---|
| `600` | Read/write | None | None | Private file |
| `640` | Read/write | Read | None | Configuration shared with a trusted group |
| `644` | Read/write | Read | Read | File that other local users may read |
| `700` | Read/write/execute | None | None | Private directory or owner-only executable |
| `750` | Read/write/execute | Read/execute | None | Directory or executable shared with a trusted group |
| `755` | Read/write/execute | Read/execute | Read/execute | Directory or executable accessible to other users |

Do not use `777` as a general fix for access errors. It grants read, write, and execute permission to every class, which usually exceeds the access required.

## 6. Distinguish Files from Directories

The same permission letters have different effects on directories:

| Permission | Meaning for a directory |
|---|---|
| `r` | List entry names |
| `w` | Create, delete, or rename entries, normally requiring `x` too |
| `x` | Traverse/search the directory and access named entries, subject to their own permissions |

A directory with `640` has no traversal permission for any class and is generally unsuitable for normal use. A directory shared with a trusted group might use `750`, while its configuration files use `640`.

File write permission controls modification of contents. Deleting or renaming a file depends primarily on the containing directory's permissions, with additional restrictions such as the sticky bit where applicable.

## 7. Understand the Scope of the Mode Bits

For ordinary access checks without extended ACLs, Linux selects the applicable class: owner first, otherwise matching group, otherwise others. The classes are not cumulative. An owner denied a permission does not fall back to a more permissive group or others entry.

Actual access also depends on parent-directory traversal permissions, ACLs, and other system controls. Privileged processes may bypass normal discretionary permission checks. This guide covers the basic three-digit modes; special bits such as setuid, setgid, and sticky are outside this ticket's scope.

## 8. Record Evidence

After running the demonstration on your Linux machine, add the actual command output to the ticket or pull request. The output examples above are expected results, not proof that the commands ran on your machine.

Capture:

- The `stat` output confirming `640` and `-rw-r-----`, including ownership.
- Successful owner read and append operations.
- The message showing execute permission is absent.
- The comparison output for the common modes.

## Acceptance Criteria Mapping

| Acceptance criterion | Documentation evidence |
|---|---|
| Document how to interpret numeric modes | Sections 1 and 2 explain classes, values, and calculations |
| Include a common example such as `640` | Sections 3 and 4 explain and demonstrate `640` |
| Explain least privilege for the user | Section 5 justifies owner read/write access |
| Explain least privilege for the group | Section 5 justifies group read-only access |
| Explain least privilege for others | Section 5 justifies granting others no access |

## Optional Lab Cleanup

Once you have captured your evidence, remove only the file and directory created by this lab:

```bash
rm -- "$permission_lab_dir/example.txt"
rmdir -- "$permission_lab_dir"
unset permission_lab_dir
```

