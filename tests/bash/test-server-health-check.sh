#!/usr/bin/env bash

# ==========================================================
# Automated Tests: Server Health Check
# Purpose:
#   Verify healthy, warning, critical, failure, CLI parsing,
#   and exit-code behavior for server-health-check.sh.
#
# Jira:
#   DEVOPS-011
#
# Usage:
#   ./tests/bash/test-server-health-check.sh
# ==========================================================

set -uo pipefail

SCRIPT_UNDER_TEST="${SCRIPT_UNDER_TEST:-./scripts/bash/server-health-check.sh}"
SERVICE_UNDER_TEST="${SERVICE_UNDER_TEST:-nginx}"
HEALTHY_URL="${HEALTHY_URL:-http://localhost}"

TESTS_PASSED=0
TESTS_FAILED=0
NGINX_WAS_STOPPED=0
TEMP_DIR=""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

test_pass() {
    local name="$1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}[PASS]${NC} $name"
}

test_fail() {
    local name="$1"
    local detail="${2:-}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}[FAIL]${NC} $name"
    if [[ -n "$detail" ]]; then
        echo "       $detail"
    fi
}

cleanup() {
    local exit_rc=$?
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR" >/dev/null 2>&1 || true
    fi
    if (( NGINX_WAS_STOPPED == 1 )) && command -v systemctl >/dev/null 2>&1; then
        if sudo -n systemctl start "$SERVICE_UNDER_TEST" >/dev/null 2>&1 || systemctl start "$SERVICE_UNDER_TEST" >/dev/null 2>&1; then
            echo -e "${YELLOW}[CLEANUP]${NC} Restored service '$SERVICE_UNDER_TEST'."
        else
            echo -e "${YELLOW}[CLEANUP]${NC} Could not automatically restore '$SERVICE_UNDER_TEST'; verify manually."
        fi
    fi
    exit "$exit_rc"
}
trap cleanup EXIT

run_script() {
    local output rc=0
    output="$("$@" 2>&1)" || rc=$?
    RUN_OUTPUT="$output"
    RUN_RC="$rc"
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    [[ "$haystack" == *"$needle"* ]]
}

if [[ ! -f "$SCRIPT_UNDER_TEST" ]]; then
    echo -e "${RED}[FAIL]${NC} Health-check script not found: $SCRIPT_UNDER_TEST"
    exit 1
fi

TEMP_DIR="$(mktemp -d)"

#  Bash syntax validation
if bash -n "$SCRIPT_UNDER_TEST" >/dev/null 2>&1; then
    test_pass "Bash syntax validation (bash -n)"
else
    test_fail "Bash syntax validation (bash -n)" "Syntax check returned non-zero."
fi

#  Help behavior
run_script "$SCRIPT_UNDER_TEST" --help
if (( RUN_RC == 0 )) && { assert_contains "$RUN_OUTPUT" "Usage:" || assert_contains "$RUN_OUTPUT" "--service"; }; then
    test_pass "Help flag (--help) output and exit code 0"
else
    test_fail "Help flag (--help) output and exit code 0" "rc=$RUN_RC output=$RUN_OUTPUT"
fi

#  Unknown parameter behavior
run_script "$SCRIPT_UNDER_TEST" --unknown-option
if (( RUN_RC != 0 )) && { assert_contains "$RUN_OUTPUT" "unknown" || assert_contains "$RUN_OUTPUT" "invalid" || assert_contains "$RUN_OUTPUT" "Usage:"; }; then
    test_pass "Unknown option rejected with non-zero exit code and message"
else
    test_fail "Unknown option rejected with non-zero exit code and message" "rc=$RUN_RC output=$RUN_OUTPUT"
fi

#  Invalid configuration input (--disk-threshold abc)
run_script "$SCRIPT_UNDER_TEST" --disk-threshold abc
if (( RUN_RC != 0 )) && { assert_contains "$RUN_OUTPUT" "invalid" || assert_contains "$RUN_OUTPUT" "threshold" || assert_contains "$RUN_OUTPUT" "number"; }; then
    test_pass "Invalid threshold (--disk-threshold abc) rejected"
else
    test_fail "Invalid threshold (--disk-threshold abc) rejected" "rc=$RUN_RC output=$RUN_OUTPUT"
fi

#  Healthy scenario (exit 0)
run_script "$SCRIPT_UNDER_TEST" --service "$SERVICE_UNDER_TEST" --url "$HEALTHY_URL"
if (( RUN_RC == 0 )) && assert_contains "$RUN_OUTPUT" "HEALTHY"; then
    test_pass "Healthy scenario returns exit 0 and HEALTHY status"
else
    test_fail "Healthy scenario returns exit 0 and HEALTHY status" "rc=$RUN_RC output=$RUN_OUTPUT"
fi

#  Warning scenario via safe threshold override (exit 1)
# Uses a very low pass threshold (0.0001) and high warning threshold (9999) so current load/usage triggers WARNING, not CRITICAL
run_script "$SCRIPT_UNDER_TEST" \
    --service "$SERVICE_UNDER_TEST" \
    --url "$HEALTHY_URL" \
    --cpu-pass-threshold 0.0001 \
    --cpu-warning-threshold 9999 \
    --memory-pass-threshold 0.0001 \
    --memory-warning-threshold 99.9 \
    --disk-pass-threshold 0.0001 \
    --disk-warning-threshold 99.9
if (( RUN_RC == 1 )) && assert_contains "$RUN_OUTPUT" "WARNING"; then
    test_pass "Warning threshold override returns exit 1 and WARNING status"
else
    test_fail "Warning threshold override returns exit 1 and WARNING status" "rc=$RUN_RC output=$RUN_OUTPUT"
fi

# Critical threshold breach via deterministic low warning threshold (exit 2)
run_script "$SCRIPT_UNDER_TEST" \
    --service "$SERVICE_UNDER_TEST" \
    --url "$HEALTHY_URL" \
    --disk-pass-threshold 0 \
    --disk-warning-threshold 0
if (( RUN_RC == 2 )) && assert_contains "$RUN_OUTPUT" "CRITICAL"; then
    test_pass "Critical threshold breach returns exit 2 and CRITICAL status"
else
    test_fail "Critical threshold breach returns exit 2 and CRITICAL status" "rc=$RUN_RC output=$RUN_OUTPUT"
fi

#  Invalid service name handling
run_script "$SCRIPT_UNDER_TEST" --service definitely-not-a-real-service --url "$HEALTHY_URL"
if (( RUN_RC != 0 )) && { assert_contains "$RUN_OUTPUT" "definitely-not-a-real-service" || assert_contains "$RUN_OUTPUT" "FAIL"; }; then
    test_pass "Invalid service name detected in output with non-zero exit"
else
    test_fail "Invalid service name detected in output with non-zero exit" "rc=$RUN_RC output=$RUN_OUTPUT"
fi

#  Stopped service scenario (with safe cleanup)
if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files "${SERVICE_UNDER_TEST}.service" >/dev/null 2>&1; then
    if sudo -n systemctl stop "$SERVICE_UNDER_TEST" >/dev/null 2>&1 || systemctl stop "$SERVICE_UNDER_TEST" >/dev/null 2>&1; then
        NGINX_WAS_STOPPED=1
        run_script "$SCRIPT_UNDER_TEST" --service "$SERVICE_UNDER_TEST" --url "$HEALTHY_URL"
        if (( RUN_RC != 0 )) && { assert_contains "$RUN_OUTPUT" "inactive" || assert_contains "$RUN_OUTPUT" "stopped" || assert_contains "$RUN_OUTPUT" "FAIL"; }; then
            test_pass "Stopped service ($SERVICE_UNDER_TEST) detected"
        else
            test_fail "Stopped service ($SERVICE_UNDER_TEST) detected" "rc=$RUN_RC output=$RUN_OUTPUT"
        fi
        sudo -n systemctl start "$SERVICE_UNDER_TEST" >/dev/null 2>&1 || systemctl start "$SERVICE_UNDER_TEST" >/dev/null 2>&1 || true
        NGINX_WAS_STOPPED=0
    else
        test_fail "Stopped service ($SERVICE_UNDER_TEST)" "Insufficient privileges to stop $SERVICE_UNDER_TEST non-interactively."
    fi
else
    test_fail "Stopped service ($SERVICE_UNDER_TEST)" "systemctl or ${SERVICE_UNDER_TEST}.service not present on host."
fi

#  Network failure scenario
run_script "$SCRIPT_UNDER_TEST" --service "$SERVICE_UNDER_TEST" --url "http://localhost:9999"
if (( RUN_RC != 0 )) && { assert_contains "$RUN_OUTPUT" "localhost:9999" || assert_contains "$RUN_OUTPUT" "FAIL" || assert_contains "$RUN_OUTPUT" "unreachable" || assert_contains "$RUN_OUTPUT" "failed"; }; then
    test_pass "Network failure (http://localhost:9999) detected"
else
    test_fail "Network failure (http://localhost:9999) detected" "rc=$RUN_RC output=$RUN_OUTPUT"
fi

# Mixed-result severity (critical failure dominates over warning/healthy)
run_script "$SCRIPT_UNDER_TEST" \
    --service "$SERVICE_UNDER_TEST" \
    --url "http://localhost:9999" \
    --memory-pass-threshold 0.0001 \
    --memory-warning-threshold 99.9
if (( RUN_RC == 2 )) && assert_contains "$RUN_OUTPUT" "CRITICAL"; then
    test_pass "Mixed results evaluate overall status as CRITICAL (exit 2)"
else
    test_fail "Mixed results evaluate overall status as CRITICAL (exit 2)" "rc=$RUN_RC output=$RUN_OUTPUT"
fi

# Valid HTTP endpoint check
run_script "$SCRIPT_UNDER_TEST" --service "$SERVICE_UNDER_TEST" --url "$HEALTHY_URL"
if (( RUN_RC == 0 )) && { assert_contains "$RUN_OUTPUT" "$HEALTHY_URL" && assert_contains "$RUN_OUTPUT" "[PASS]"; }; then
    test_pass "Valid HTTP endpoint ($HEALTHY_URL) detected"
else
    test_fail "Valid HTTP endpoint ($HEALTHY_URL) detected" "rc=$RUN_RC output=$RUN_OUTPUT"
fi

echo ""
echo "Tests Passed: $TESTS_PASSED"
echo "Tests Failed: $TESTS_FAILED"

if (( TESTS_FAILED > 0 )); then
    echo "Overall Test Result: FAIL"
    exit 1
else
    echo "Overall Test Result: PASS"
    exit 0
fi