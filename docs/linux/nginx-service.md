# Configure and Operate Linux Services

### DEVOPS-008-A: Install and Verify the Nginx Service Package

```bash
# Gather Information about the service (Nginx) before installing to ensure the right package is being installed
apt info nginx

# Install Nginx & Verify presence of nginx
sudo apt -y install nginx && nginx -v

# Verify service unit is available /usr/lib/systemd/system/nginx.service
sudo systemctl cat nginx.service
```

### DEVOPS-008-B: Start , Stop and Restart the Nginx Service

```bash
# Start , Stop and Restart Nginx
sudo systemctl start nginx.service; sudo systemctl stop nginx.service; sudo systemctl restart nginx.service
# Double check service is running after restart
```

### DEVOPS-008-C: Enable and Disable at Boot

```bash
# Enable nginx to ensure It starts each time system reboot as part of systemd PID at boot
sudo systemctl enable --now nginx.service

# Check nginx status
sudo systemctl status nginx.service

# Disable nginx
sudo systemctl disable nginx.service

# Verify nginx status for Enabled/Disabled
sudo systemctl is-enabled nginx.service. # Output should be disabled
```

### DEVOPS-008-D: Inspect Nginx Service Status with systemctl

```bash
# Check status of service after being disabled
sudo systemctl status nginx.service. # Output should be disabled after above action
```

### DEVOPS-008-E: Identify the Nginx Process with ps, pgrep, top, and htop

```bash
# Check running process of nginx
ps aux | grep nginx # Note: This will be as a master process and worker process (www-data) with PID 22845 & 22846 respectively

# Using pgrep
pgrep -a nginx # List process with list of PID annd full command line
pgrep -l nginx # List PID and process name

# Use top for non-graphical usage of resource
top # Shows entire running running process and their usage by cpu, mem, user, load average
top -p 22845 # filter by master nginx process
top -p 22846 # filter by worker/child nginx process

# Graphical Resource usage using htop
htop
htop -p 22845 # filter by master nginx process
htop -p 22846 # filter by worker/child nginx process
```

### DEVOPS-008-F: Inspect Listening Ports for Nginx

```bash
# Verify nginx is listening on port 80
ss -tulpn | grep -E '*:80'
```

### DEVOPS-008-G: Inspect Nginx Logs with journalctl

```bash
# Review nginx logs using journalctl - This should show logs of the lifecycle of nginx based on Start,Stop,Enable& disbale
sudo journalctl -u nginx.service
# Drill down based on time to see logs for Nginx entries, If no active in the specified time, then there will be no entries.
sudo journalctl -u nginx.service --since "60 minutes ago" # Drill down by 60mins to retrieve entries.
# Using flag -f allow Live interaction with entries of nginx activities
sudo journalctl -u nginx -f
```

### DEVOPS-008-H: Diagnose and Fix an Invalid Nginx Configuration && DEVOPS-008-I: Diagnose Nginx Startup Failures Caused by Port Conflicts or Missing Files

```bash
# Trigger a misconfiguration by commenting out some core settings in Config /etc/nginx/nginx.conf or Service /usr/lib/systemd/system/nginx.service or Kill existing process kill -9 PID
# Once triggered, Reload systemd daemon to ensure settings is updated
sudo systemctl daemon-reload

# Check service status
sudo systemctl status nginx.service

# Review journalctl entries logs using -u and -f
sudo journalctl -u nginx -f # View failed logged entries from the trigger

# Check port to ensure nginx is not listening on Port 80
ss -tulpn | grep -E '*:80'

# Remediate Misconfiguration by Rolling back to default setting
sudo nano /etc/nginx/nginx.conf # Fix misconfiguration
sudo nano /usr/lib/systemd/system/nginx.service # Fix misconfiguration

# Reload Daemon
sudo systemctl daemon-reload

# Review Logs to ensure service is back to a state of sanity
sudo journalctl -u nginx
```
