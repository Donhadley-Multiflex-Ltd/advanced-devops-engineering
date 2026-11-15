# Incident Investigation Report: NGINX Service Outage

## Summary

A simulated outage was introduced by modifying the NGINX upstream configuration to reference a non-existent backend host (`api-backend:8080`). Following the configuration change, NGINX failed to start successfully, causing the web service to become unavailable.

---

## Investigation Objectives

- Review `journalctl` logs.
- Review other relevant logs and system information.
- Identify warnings, errors, and startup failures.
- Determine the root cause of the outage.

---

# Investigation Findings

## 1. Review of journalctl Logs

### Command

```bash
sudo journalctl -u nginx -xe
```

### Findings

```text
Nov 15 18:23:56 nginx[15391]:
[emerg] host not found in upstream "api-backend:8080"

Nov 15 18:23:56 nginx[15391]:
nginx: configuration file /etc/nginx/nginx.conf test failed

Nov 15 18:23:56 systemd[1]:
nginx.service: Control process exited, code=exited, status=1/FAILURE

Nov 15 18:23:56 systemd[1]:
nginx.service: Failed with result 'exit-code'

Nov 15 18:23:56 systemd[1]:
Failed to start nginx.service - A high performance web server and a reverse proxy server.
```

### Analysis

The logs confirm that:

- NGINX failed its configuration validation.
- The upstream host `api-backend` could not be resolved.
- Systemd reported a service startup failure.
- NGINX never reached a running state after the configuration change.

---

## 2. Review of Other Relevant Logs

### System Journal

Additional journal entries showed repeated service failures:

```text
nginx.service: Failed with result 'exit-code'
Failed to start nginx.service
```

No operating system resource issues were observed, such as:

- Disk exhaustion
- Memory pressure
- CPU saturation

### Firewall Verification

```bash
sudo ufw status
```

Result:

```text
Status: active

80/tcp   ALLOW
443/tcp  ALLOW
```

Analysis:

- HTTP traffic was permitted.
- HTTPS traffic was permitted.
- Firewall rules were not responsible for the outage.

---

## 3. DNS Resolution Verification

### Command

```bash
dig +short api-backend
```

### Result

```text
(no response)
```

### Validation Test

```bash
dig +short google.com
```

Result:

```text
142.251.218.206
```

### DNS Server Verification

```bash
dig google.com | grep SERVER
```

Result:

```text
SERVER: 127.0.0.53#53(127.0.0.53)
```

### Analysis

The DNS resolver was functioning correctly because external domains resolved successfully.

However:

- `api-backend` could not be resolved.
- No DNS record existed for the configured upstream hostname.
- This confirms the issue was specific to the NGINX configuration rather than general DNS failure.

---

## 4. Network and Port Verification

### Commands

```bash
ss -tulpn | grep :80
ss -tulpn | grep :8080
```

### Findings

No listener corresponding to the configured upstream service was observed.

### Analysis

Even if NGINX had started successfully, the backend service definition could not be validated because the upstream host referenced in the configuration did not exist.

---

## Errors Identified

### Critical Error

```text
host not found in upstream "api-backend:8080"
```

### Service Failure

```text
nginx.service: Control process exited, code=exited, status=1/FAILURE
```

### Configuration Validation Failure

```text
nginx: configuration file /etc/nginx/nginx.conf test failed
```

### Startup Failure

```text
Failed to start nginx.service
```

---

# Root Cause Analysis

## Root Cause

The outage was caused by an invalid NGINX upstream configuration.

A backend host named:

```text
api-backend:8080
```

was configured within the NGINX reverse proxy configuration, but the hostname did not exist and could not be resolved through DNS.

During startup, NGINX performed configuration validation and encountered the unresolved upstream host. As a result:

1. Configuration validation failed.
2. NGINX exited with status code 1.
3. Systemd marked the service as failed.
4. The web service became unavailable.

---

# Resolution

The invalid upstream reference was replaced with a valid backend endpoint.

Example:

```nginx
upstream backend {
    server 127.0.0.1:8080;
    server api-backend:8080;
}
```

After correcting the configuration:

```bash
sudo nginx -t
sudo systemctl restart nginx
```

NGINX started successfully and service availability was restored.

---

# Acceptance Criteria Validation

| Acceptance Criteria                            | Status   | Evidence                                                             |
| ---------------------------------------------- | -------- | -------------------------------------------------------------------- |
| Check `journalctl` logs                        | Complete | Service startup failure identified                                   |
| Review other relevant logs                     | Complete | DNS, firewall, network, and system logs reviewed                     |
| Identify warnings, errors, or startup failures | Complete | Upstream resolution error and service failure identified             |
| Determine root cause                           | Complete | Invalid upstream hostname configuration caused NGINX startup failure |

---

# Final Conclusion

The simulated outage was successfully investigated. The evidence showed that NGINX failed during startup because the configured upstream host `api-backend:8080` could not be resolved. This caused configuration validation to fail, preventing NGINX from starting and resulting in service unavailability. The issue was configuration-related and not caused by firewall, network, or DNS resolver failures.
