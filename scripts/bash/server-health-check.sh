#!/usr/bin/env bash

# ==========================================================
# Server Health Check
# Purpose:
#   Perform automated health checks against a Linux server.
#
# Jira:
#   DEVOPS-011
#
# Usage:
#   ./scripts/bash/server-health-check.sh [OPTIONS]
#
# Options:
#   --service NAME               Systemd service to check (default: nginx)
#   --url URL                    HTTP endpoint to check (default: https://example.com)
#   --timeout SECONDS            Curl timeout in seconds (default: 5)
#   --cpu-pass-threshold N       CPU load pass multiplier per core (default: 0.7)
#   --cpu-warning-threshold N    CPU load warning multiplier per core (default: 1.0)
#   --memory-pass-threshold N    Memory usage pass % (default: 80)
#   --memory-warning-threshold N Memory usage warning % (default: 90)
#   --disk-threshold N           Disk usage warning % (default: 80)
#   --disk-pass-threshold N      Disk usage pass % (default: 80)
#   --disk-warning-threshold N   Disk usage warning % (default: 90)
#   -h, --help                   Show this help message and exit 0
# ==========================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CPU_LOAD_PASS_THRESHOLD="${CPU_LOAD_PASS_THRESHOLD:-0.7}"
CPU_LOAD_WARNING_THRESHOLD="${CPU_LOAD_WARNING_THRESHOLD:-1.0}"
MEMORY_PASS_THRESHOLD="${MEMORY_PASS_THRESHOLD:-80}"
MEMORY_WARNING_THRESHOLD="${MEMORY_WARNING_THRESHOLD:-90}"
DISK_PASS_THRESHOLD="${DISK_PASS_THRESHOLD:-80}"
DISK_WARNING_THRESHOLD="${DISK_WARNING_THRESHOLD:-90}"
SERVICE_NAME="${SERVICE_NAME:-nginx}"
TEST_URL="${TEST_URL:-https://github.com}"
CURL_TIMEOUT="${CURL_TIMEOUT:-5}"

OVERALL_EXIT=0

record_status() {
    local status="$1"
    case "$status" in
        PASS)
            ;;
        WARNING)
            if (( OVERALL_EXIT < 1 )); then
                OVERALL_EXIT=1
            fi
            ;;
        FAIL|CRITICAL)
            OVERALL_EXIT=2
            ;;
    esac
}

is_number() {
    local val="$1"
    [[ "$val" =~ ^[0-9]+([.][0-9]+)?$ ]]
}

usage() {
    cat << 'EOF'
Usage: server-health-check.sh [OPTIONS]

Options:
  --service NAME               Systemd service to check (default: nginx)
  --url URL                    HTTP endpoint to check (default: https://github.com)
  --timeout SECONDS            Curl timeout in seconds (default: 5)
  --cpu-pass-threshold N       CPU load pass multiplier per core (default: 0.7)
  --cpu-warning-threshold N    CPU load warning multiplier per core (default: 1.0)
  --memory-pass-threshold N    Memory usage pass % (default: 80)
  --memory-warning-threshold N Memory usage warning % (default: 90)
  --disk-threshold N           Disk usage warning % (default: 80)
  --disk-pass-threshold N      Disk usage pass % (default: 80)
  --disk-warning-threshold N   Disk usage warning % (default: 90)
  -h, --help                   Show this help message and exit 0
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            --service)
                [[ $# -ge 2 && -n "$2" ]] || { echo "Error: --service requires a value" >&2; exit 1; }
                SERVICE_NAME="$2"
                shift 2
                ;;
            --url)
                [[ $# -ge 2 && -n "$2" ]] || { echo "Error: --url requires a value" >&2; exit 1; }
                TEST_URL="$2"
                shift 2
                ;;
            --timeout)
                [[ $# -ge 2 ]] && is_number "$2" || { echo "Error: invalid --timeout value '$2'" >&2; exit 1; }
                CURL_TIMEOUT="$2"
                shift 2
                ;;
            --cpu-pass-threshold)
                [[ $# -ge 2 ]] && is_number "$2" || { echo "Error: invalid --cpu-pass-threshold value '${2:-}'" >&2; exit 1; }
                CPU_LOAD_PASS_THRESHOLD="$2"
                shift 2
                ;;
            --cpu-warning-threshold)
                [[ $# -ge 2 ]] && is_number "$2" || { echo "Error: invalid --cpu-warning-threshold value '${2:-}'" >&2; exit 1; }
                CPU_LOAD_WARNING_THRESHOLD="$2"
                shift 2
                ;;
            --memory-pass-threshold)
                [[ $# -ge 2 ]] && is_number "$2" || { echo "Error: invalid --memory-pass-threshold value '${2:-}'" >&2; exit 1; }
                MEMORY_PASS_THRESHOLD="$2"
                shift 2
                ;;
            --memory-warning-threshold)
                [[ $# -ge 2 ]] && is_number "$2" || { echo "Error: invalid --memory-warning-threshold value '${2:-}'" >&2; exit 1; }
                MEMORY_WARNING_THRESHOLD="$2"
                shift 2
                ;;
            --disk-threshold)
                [[ $# -ge 2 ]] && is_number "$2" || { echo "Error: invalid --disk-threshold value '${2:-}'" >&2; exit 1; }
                DISK_PASS_THRESHOLD="$2"
                DISK_WARNING_THRESHOLD="$2"
                shift 2
                ;;
            --disk-pass-threshold)
                [[ $# -ge 2 ]] && is_number "$2" || { echo "Error: invalid --disk-pass-threshold value '${2:-}'" >&2; exit 1; }
                DISK_PASS_THRESHOLD="$2"
                shift 2
                ;;
            --disk-warning-threshold)
                [[ $# -ge 2 ]] && is_number "$2" || { echo "Error: invalid --disk-warning-threshold value '${2:-}'" >&2; exit 1; }
                DISK_WARNING_THRESHOLD="$2"
                shift 2
                ;;
            *)
                echo "Error: unknown option '$1'" >&2
                usage >&2
                exit 1
                ;;
        esac
    done
}

check_hostname() {
    local hostname
    hostname=$(hostnamectl --static 2>/dev/null || hostname 2>/dev/null || true)
    if [[ -n "$hostname" ]]; then
        echo -e "Hostname: $hostname - ${GREEN}[PASS]${NC}"
        record_status "PASS"
    else
        echo -e "Hostname: - ${RED}[FAIL]${NC}"
        record_status "FAIL"
    fi
}

check_uptime() {
    local uptime
    uptime=$(uptime -p 2>/dev/null || true)
    if [[ -n "$uptime" ]]; then
        echo -e "Uptime: $uptime - ${GREEN}[PASS]${NC}"
        record_status "PASS"
    else
        echo -e "Uptime: - ${RED}[FAIL]${NC}"
        record_status "FAIL"
    fi
}

check_cpu_load() {
    local cpu_count load_avg pass_limit warn_limit
    cpu_count=$(nproc)
    load_avg=$(awk '{print $1}' /proc/loadavg)
    pass_limit=$(echo "$cpu_count * $CPU_LOAD_PASS_THRESHOLD" | bc -l)
    warn_limit=$(echo "$cpu_count * $CPU_LOAD_WARNING_THRESHOLD" | bc -l)

    if (( $(echo "$load_avg < $pass_limit" | bc -l) )); then
        echo -e "CPU Load: $load_avg - ${GREEN}[PASS]${NC}"
        record_status "PASS"
    elif (( $(echo "$load_avg < $warn_limit" | bc -l) )); then
        echo -e "CPU Load: $load_avg - ${YELLOW}[WARNING]${NC}"
        record_status "WARNING"
    else
        echo -e "CPU Load: $load_avg - ${RED}[CRITICAL]${NC}"
        record_status "CRITICAL"
    fi
}

check_memory() {
    local mem_total mem_avail mem_used mem_usage
    mem_total=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null || true)
    mem_avail=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo 2>/dev/null || true)

    if [[ -z "$mem_avail" ]]; then
        local mem_free buffers cached
        mem_free=$(awk '/^MemFree:/ {print $2}' /proc/meminfo 2>/dev/null || true)
        buffers=$(awk '/^Buffers:/ {print $2}' /proc/meminfo 2>/dev/null || true)
        cached=$(awk '/^Cached:/ {print $2}' /proc/meminfo 2>/dev/null || true)
        if [[ -n "$mem_free" && -n "$buffers" && -n "$cached" ]]; then
            mem_avail=$((mem_free + buffers + cached))
        fi
    fi

    if [[ -n "$mem_total" && -n "$mem_avail" && "$mem_total" -gt 0 ]]; then
        mem_used=$((mem_total - mem_avail))
        (( mem_used < 0 )) && mem_used=0
        mem_usage=$(echo "scale=2; ($mem_used / $mem_total) * 100" | bc -l)

        if (( $(echo "$mem_usage < $MEMORY_PASS_THRESHOLD" | bc -l) )); then
            echo -e "Memory Usage: $mem_used/$mem_total ($mem_usage%) - ${GREEN}[PASS]${NC}"
            record_status "PASS"
        elif (( $(echo "$mem_usage < $MEMORY_WARNING_THRESHOLD" | bc -l) )); then
            echo -e "Memory Usage: $mem_used/$mem_total ($mem_usage%) - ${YELLOW}[WARNING]${NC}"
            record_status "WARNING"
        else
            echo -e "Memory Usage: $mem_used/$mem_total ($mem_usage%) - ${RED}[CRITICAL]${NC}"
            record_status "CRITICAL"
        fi
    else
        echo -e "Memory Usage: - ${RED}[FAIL]${NC}"
        record_status "FAIL"
    fi
}

check_disk_usage() {
    local fs usage
    while read -r fs usage _; do
        usage=${usage%\%}
        [[ -n "$usage" ]] || continue
        if (( $(echo "$usage < $DISK_PASS_THRESHOLD" | bc -l) )); then
            echo -e "Disk Usage: $fs $usage% - ${GREEN}[PASS]${NC}"
            record_status "PASS"
        elif (( $(echo "$usage < $DISK_WARNING_THRESHOLD" | bc -l) )); then
            echo -e "Disk Usage: $fs $usage% - ${YELLOW}[WARNING]${NC}"
            record_status "WARNING"
        else
            echo -e "Disk Usage: $fs $usage% - ${RED}[CRITICAL]${NC}"
            record_status "CRITICAL"
        fi
    done < <(df -P | awk 'NR>1 && $1 !~ /^tmpfs|^udev/ {print $1, $5}')
}

check_service() {
    local svc="$SERVICE_NAME"
    local state rc=0

    if [[ -z "$svc" ]]; then
        echo -e "Service (<empty>): invalid service name - ${RED}[FAIL]${NC}"
        record_status "FAIL"
        return 0
    fi

    if ! command -v systemctl >/dev/null 2>&1; then
        echo -e "Service ($svc): systemctl not available - ${YELLOW}[WARNING]${NC}"
        record_status "WARNING"
        return 0
    fi

    state=$(systemctl is-active "$svc" 2>/dev/null) || rc=$?

    case "$state" in
        active)
            echo -e "Service ($svc): active - ${GREEN}[PASS]${NC}"
            record_status "PASS"
            ;;
        inactive|failed|deactivating|reloading)
            echo -e "Service ($svc): $state - ${RED}[FAIL]${NC}"
            record_status "FAIL"
            ;;
        unknown|not-found|"")
            echo -e "Service ($svc): invalid or unknown service (exit $rc) - ${RED}[FAIL]${NC}"
            record_status "FAIL"
            ;;
        *)
            echo -e "Service ($svc): state=$state (exit $rc) - ${YELLOW}[WARNING]${NC}"
            record_status "WARNING"
            ;;
    esac
}

check_network() {
    local url="$TEST_URL"
    local curl_rc=0
    local http_code

    if [[ -z "$url" ]]; then
        echo -e "Network (<empty>): TEST_URL is empty - ${RED}[FAIL]${NC}"
        record_status "FAIL"
        return 0
    fi

    if ! command -v curl >/dev/null 2>&1; then
        echo -e "Network ($url): curl not installed - ${RED}[FAIL]${NC}"
        record_status "FAIL"
        return 0
    fi

    http_code=$(curl -sS -L -o /dev/null \
        --connect-timeout "$CURL_TIMEOUT" \
        --max-time "$CURL_TIMEOUT" \
        -w "%{http_code}" \
        "$url" 2>/dev/null) || curl_rc=$?

    if (( curl_rc != 0 )); then
        echo -e "Network ($url): connection failed (curl exit $curl_rc) - ${RED}[FAIL]${NC}"
        record_status "FAIL"
        return 0
    fi

    if [[ "$http_code" =~ ^2[0-9]{2}$ || "$http_code" =~ ^3[0-9]{2}$ ]]; then
        echo -e "Network ($url): HTTP $http_code - ${GREEN}[PASS]${NC}"
        record_status "PASS"
    elif [[ "$http_code" =~ ^4[0-9]{2}$ || "$http_code" =~ ^5[0-9]{2}$ ]]; then
        echo -e "Network ($url): HTTP $http_code - ${RED}[FAIL]${NC}"
        record_status "FAIL"
    else
        echo -e "Network ($url): unexpected HTTP status '$http_code' - ${YELLOW}[WARNING]${NC}"
        record_status "WARNING"
    fi
}

print_overall_status() {
    case "$OVERALL_EXIT" in
        0)
            echo -e "Overall Status: ${GREEN}HEALTHY${NC}"
            ;;
        1)
            echo -e "Overall Status: ${YELLOW}WARNING${NC}"
            ;;
        *)
            echo -e "Overall Status: ${RED}CRITICAL${NC}"
            ;;
    esac
}

main() {
    parse_args "$@"

    echo -e "${BLUE}============ DevOps Server Health Check ========${NC}"

    check_hostname
    check_uptime
    check_cpu_load
    check_memory
    check_disk_usage
    check_service
    check_network
    print_overall_status

    exit "$OVERALL_EXIT"
}

main "$@"