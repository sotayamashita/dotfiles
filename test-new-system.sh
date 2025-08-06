#!/usr/bin/env bash
#
# test-new-system.sh - Test script for the new dotfiles management system
#
# This script tests the basic functionality of the new dot command

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

# Test functions
test_start() {
    echo -e "${BLUE}Testing:${NC} $1"
}

test_pass() {
    echo -e "  ${GREEN}✓${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
    echo -e "  ${RED}✗${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

# Tests
run_tests() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Running Tests for New Dotfiles System${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    
    # Test 1: Check if dot command exists
    test_start "Checking if 'dot' command exists"
    if [[ -f "./dot" ]]; then
        test_pass "dot command found"
    else
        test_fail "dot command not found"
    fi
    
    # Test 2: Check if dot command is executable
    test_start "Checking if 'dot' command is executable"
    if [[ -x "./dot" ]]; then
        test_pass "dot command is executable"
    else
        test_fail "dot command is not executable"
    fi
    
    # Test 3: Test help command
    test_start "Testing 'dot help' command"
    if ./dot help >/dev/null 2>&1; then
        test_pass "Help command works"
    else
        test_fail "Help command failed"
    fi
    
    # Test 4: Test version command
    test_start "Testing 'dot version' command"
    if ./dot version >/dev/null 2>&1; then
        test_pass "Version command works"
    else
        test_fail "Version command failed"
    fi
    
    # Test 5: Test status command
    test_start "Testing 'dot status' command"
    if ./dot status >/dev/null 2>&1; then
        test_pass "Status command works"
    else
        test_fail "Status command failed"
    fi
    
    # Test 6: Check if install.sh exists
    test_start "Checking if 'install.sh' exists"
    if [[ -f "./install.sh" ]]; then
        test_pass "install.sh found"
    else
        test_fail "install.sh not found"
    fi
    
    # Test 7: Check config directory
    test_start "Checking config directory"
    if [[ -d "./config" ]]; then
        test_pass "config directory exists"
    else
        test_fail "config directory not found"
    fi
    
    # Test 8: Test dry-run mode
    test_start "Testing 'dot sync --dry-run' command"
    if ./dot sync --dry-run >/dev/null 2>&1; then
        test_pass "Dry-run mode works"
    else
        test_fail "Dry-run mode failed"
    fi
    
    # Test 9: Check documentation
    test_start "Checking documentation"
    if [[ -f "./docs/improvement-proposal.md" ]]; then
        test_pass "Improvement proposal found"
    else
        test_fail "Improvement proposal not found"
    fi
    
    if [[ -f "./README-new.md" ]]; then
        test_pass "New README found"
    else
        test_fail "New README not found"
    fi
    
    echo
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Test Results${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${GREEN}Passed:${NC} $TESTS_PASSED"
    echo -e "  ${RED}Failed:${NC} $TESTS_FAILED"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo
        echo -e "${GREEN}✨ All tests passed!${NC}"
        return 0
    else
        echo
        echo -e "${YELLOW}⚠️  Some tests failed. Please review the results.${NC}"
        return 1
    fi
}

# Main
main() {
    cd "$(dirname "${BASH_SOURCE[0]}")"
    run_tests
}

main "$@"