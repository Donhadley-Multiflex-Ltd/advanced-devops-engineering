# Troubleshooting Guide

## Service Failure

When a service fails, check its current status and review recent logs to identify the cause.

### Check Service Health

```bash
systemctl status SERVICE
```

Review the output for:

- `active (running)` or `failed` state
- Recent restart attempts
- Exit codes
- Service-related error messages

### Review Recent Logs

```bash
journalctl -u SERVICE
```

Look for:

- Error messages
- Warning messages
- Service startup failures
- Unexpected restarts or crashes
- Dependency failures

### Common Indicators

| Check        | What to Look For                                                   |
| ------------ | ------------------------------------------------------------------ |
| Failed State | Service reported as `failed` or `inactive`                         |
| Restarts     | Frequent restart attempts or restart loops                         |
| Errors       | Exceptions, missing files, permission issues, configuration errors |

---

## SSH Problems

Use the following checks when troubleshooting SSH connectivity issues.

### Check SSH Service Status

```bash
sudo systemctl status ssh
```

Verify that:

- The SSH service is running
- No startup errors are reported
- The service is enabled if required

### Check Port 22 Listening Status

```bash
ss -tulpn | grep :22
```

Confirm that:

- SSH is listening on port 22
- The `sshd` process is bound to the expected interface

### Check Firewall Rules

Review firewall configuration to ensure SSH traffic is allowed.

Examples:

```bash
sudo ufw status
```

```bash
sudo iptables -L
```

Verify that port 22 is permitted.

### Check User Access

Confirm that:

- The user account exists
- The account is not locked
- The user has permission to connect via SSH

Example:

```bash
id USERNAME
```

### Check Public Key Configuration

Ensure the user's public key is present in:

```text
~/.ssh/authorized_keys
```

Verify that:

- The correct public key is configured
- The key has not been corrupted or modified

### Check File Permissions

Validate SSH-related permissions.

Example:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

Recommended permissions:

| Path                     | Permission |
| ------------------------ | ---------- |
| `~/.ssh`                 | `700`      |
| `~/.ssh/authorized_keys` | `600`      |

---

## Networking Problems

Use these commands to investigate network connectivity and service reachability issues.

### Check Network Interfaces

```bash
ip addr
```

Verify:

- IP addresses are assigned correctly
- Interfaces are up and operational

### Check Routing Configuration

```bash
ip route
```

Verify:

- Default gateway is present
- Routes point to the correct networks

### Check Listening Ports

```bash
ss -tulpn
```

Confirm:

- Required services are listening
- Ports are bound to expected interfaces

### Check Local Connectivity

```bash
ping HOSTNAME_OR_IP
```

Use this to verify:

- Basic network connectivity
- Reachability of gateways and remote hosts

### Check Service Reachability

```bash
curl http://HOSTNAME_OR_IP
```

or

```bash
curl https://HOSTNAME_OR_IP
```

Verify:

- The service responds successfully
- Expected HTTP status codes are returned
- DNS resolution is working correctly

### Common Checks

| Area                 | What to Verify                             |
| -------------------- | ------------------------------------------ |
| Interfaces           | Interface is up and has a valid IP address |
| Routes               | Correct default gateway and routes exist   |
| Ports                | Required ports are listening               |
| Connectivity         | `ping` succeeds                            |
| Service Reachability | `curl` returns a valid response            |
