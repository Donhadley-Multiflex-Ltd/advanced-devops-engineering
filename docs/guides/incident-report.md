# INC-001 - Linux Service Outage (NGINX Startup Failure)

## Incident Summary

On 15-Nov-2026, a simulated outage was introduced by modifying the NGINX configuration to reference an invalid upstream host (`api-backend:8080`).

When NGINX was restarted, configuration validation failed because the upstream hostname could not be resolved. As a result, the NGINX service failed to start and the web application became unavailable.

This incident was intentionally created as part of a chaos engineering exercise to practice incident investigation, log analysis, and root cause identification.

---

## Impact

### User Impact

- Users were unable to access the web application hosted behind NGINX.
- HTTP requests to the server failed because the reverse proxy service was unavailable.

### Service Impact

- NGINX service entered a failed state.
- Reverse proxy functionality was unavailable.
- Backend requests could not be routed.

### Severity

**SEV-3 (Low)**

This was a controlled outage conducted in a non-production environment.

---

## Detection

The incident was detected during service validation after restarting NGINX.

### Service Status Check

```bash
sudo systemctl status nginx
```

### Journal Logs

```bash
sudo journalctl -u nginx -xe
```

Observed errors:

```text
host not found in upstream "api-backend:8080"

nginx: configuration file /etc/nginx/nginx.conf test failed

nginx.service: Control process exited, code=exited, status=1/FAILURE

Failed to start nginx.service
```

### Additional Validation

DNS resolution testing was performed:

```bash
dig +short api-backend
```

Result:

```text
(no response)
```

External DNS resolution succeeded:

```bash
dig +short google.com
```

Result:

```text
142.251.218.206
```

This confirmed that DNS functionality was operational and the issue was isolated to the configured upstream hostname.

---

## Timeline

| Time  | Event                                                  |
| ----- | ------------------------------------------------------ |
| 18:23 | NGINX configuration modified to use `api-backend:8080` |
| 18:23 | NGINX restart initiated                                |
| 18:23 | Configuration validation failed                        |
| 18:23 | NGINX service stopped unexpectedly                     |
| 18:23 | Systemd reported startup failure                       |
| 18:24 | Investigation started                                  |
| 18:26 | Journal and DNS logs reviewed                          |
| 18:28 | Root cause identified                                  |
| 18:30 | Configuration corrected and service restored           |

---

## Root Cause

The outage was caused by an invalid upstream configuration in NGINX.

The configuration referenced:

```nginx
proxy_pass http://api-backend:8080;
```

However, the hostname `api-backend` did not exist and could not be resolved through DNS.

During startup, NGINX attempted to validate the configuration and encountered the following error:

```text
host not found in upstream "api-backend:8080"
```

Because the upstream host could not be resolved:

1. Configuration validation failed.
2. NGINX exited with status code 1.
3. Systemd marked the service as failed.
4. The web service became unavailable.

---

## Resolution

The invalid upstream hostname was replaced with a valid backend endpoint.

Example:

```nginx
upstream backend {
    server 127.0.0.1:8080;
}
```

Configuration validation was then performed:

```bash
sudo nginx -t
```

Result:

```text
syntax is ok
test is successful
```

The service was subsequently restarted:

```bash
sudo systemctl restart nginx
```

NGINX started successfully and normal service was restored.

---

## Preventive Actions

### Immediate Actions

- Validate NGINX configurations before deployment.
- Verify upstream hostnames exist before service restart.
- Document standard rollback procedures.

### Short-Term Improvements

- Add `nginx -t` checks to deployment workflows.
- Implement automated configuration validation in CI/CD pipelines.
- Create monitoring alerts for NGINX service startup failures.

### Long-Term Improvements

- Introduce infrastructure testing for service discovery and DNS dependencies.
- Implement health checks for upstream services.
- Perform regular chaos engineering exercises to validate operational readiness.

---

## Lessons Learned

- NGINX startup failures can often be identified quickly through `journalctl`.
- Configuration validation should always be performed before applying changes.
- DNS and service-discovery dependencies should be validated during deployment.
- Structured incident documentation improves troubleshooting efficiency and knowledge sharing.

---

## Incident Status

**Status:** Resolved

**Root Cause Category:** Configuration Error

**Environment:** Development / Chaos Engineering Lab

**Incident Owner:** Platform Engineering Team

**Date Closed:** 15-Nov-2026
