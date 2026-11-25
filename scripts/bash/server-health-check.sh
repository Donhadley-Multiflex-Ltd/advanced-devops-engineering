#!/bin/bash

# Error handling
set -euo pipefail

# Define resource utilization thresholds for CPU, memory, and disk usage
CPU_LOAD_PASS_THRESHOLD=0.7
CPU_LOAD_WARNING_THRESHOLD=1.0
MEMORY_PASS_THRESHOLD=70
MEMORY_WARNING_THRESHOLD=90
DISK_PASS_THRESHOLD=70
DISK_WARNING_THRESHOLD=90

# Check the hostname of the server
check_hostname() {
    local hostname
    hostname=$(hostnamectl --static 2>/dev/null || hostname)
    if [[ -n "$hostname" ]]; then
        echo "Hostname: $hostname - PASS"
    else
        echo "Hostname: - FAIL"
    fi
}

# Display Uptime in a human-readable format
check_uptime() {
    local uptime
    uptime=$(uptime -p)
    if [[ -n "$uptime" ]]; then
        echo "Uptime: $uptime - PASS"
    else
        echo "Uptime: - FAIL"
    fi
}
# Check CPU load against thresholds
check_cpu_load() {
    local cpu_count load_avg load_threshold
    cpu_count=$(nproc)
    load_avg=$(awk '{print $1}' /proc/loadavg)
    load_threshold=$(echo "$cpu_count * $CPU_LOAD_PASS_THRESHOLD" | bc)
    if (( $(echo "$load_avg < $load_threshold" | bc -l) )); then
        echo "CPU Load: $load_avg - PASS"
    elif (( $(echo "$load_avg < $cpu_count * $CPU_LOAD_WARNING_THRESHOLD" | bc -l) )); then
        echo "CPU Load: $load_avg - WARNING"
    else
        echo "CPU Load: $load_avg - CRITICAL"
    fi
}
# Check memory usage against thresholds
check_memory() {
    local mem_total mem_used mem_free mem_usage
    mem_total=$(awk '/^Mem:/ {print $2}' /proc/meminfo)
    mem_used=$(awk '/^Mem:/ {print $3}' /proc/meminfo)
    mem_free=$(awk '/^Mem:/ {print $4}' /proc/meminfo)
    if [[ -n "$mem_total" && -n "$mem_used" && -n "$mem_free" ]]; then
        mem_usage=$(echo "scale=2; $mem_used/$mem_total*100" | bc)
        if (( $(echo "$mem_usage < $MEMORY_PASS_THRESHOLD" | bc -l) )); then
            echo "Memory Usage: $mem_used/$mem_total ($mem_usage%) - PASS"
        elif (( $(echo "$mem_usage < $MEMORY_WARNING_THRESHOLD" | bc -l) )); then
            echo "Memory Usage: $mem_used/$mem_total ($mem_usage%) - WARNING"
        else
            echo "Memory Usage: $mem_used/$mem_total ($mem_usage%) - CRITICAL"
        fi
    else
        echo "Memory Usage: - FAIL"
    fi
}

# Check disk usage against thresholds
check_disk_usage() {
    local fs usage
    while read -r fs usage _; do
        usage=${usage%\%}
        if (( usage < $DISK_PASS_THRESHOLD )); then
            echo "Disk Usage: $fs $usage% - PASS"
        elif (( usage < $DISK_WARNING_THRESHOLD )); then
            echo "Disk Usage: $fs $usage% - WARNING"
        else
            echo "Disk Usage: $fs $usage% - CRITICAL"
        fi
    done < <(df -P | awk 'NR>1 && $1 !~ /^tmpfs|^udev/ {print $1, $5}')
}

# Run all checks
check_hostname
check_uptime
check_cpu_load
check_memory
check_disk_usage

echo "Health check completed."