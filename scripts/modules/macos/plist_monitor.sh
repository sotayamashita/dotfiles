#!/usr/bin/env bash
#
# Monitors changes to macOS plist files by capturing the state before and after
# modifications. Creates a diff of the changes and saves them to a timestamped
# directory on the Desktop.
#
# This script is useful for:
# - Debugging preference changes for dotfiles
# - Documenting system modifications
# - Identifying what settings are modified by GUI changes
#
# Usage:
#   ./plist_monitor.sh <plist-name>
#   Example: ./plist_monitor.sh com.apple.symbolichotkeys

set -euo pipefail

# Constants should be all caps and declared at the top
readonly DESKTOP_PATH="$HOME/Desktop"
readonly TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Function to capture current state - improve error handling
capture_state() {
    local output_file="$1"
    if ! defaults read "$PLIST_NAME" > "$output_file"; then
        echo "Error: Failed to read plist $PLIST_NAME" >&2
        exit 1
    fi
    echo "Current state saved to: $output_file"
}

# Function to compare states
compare_states() {
    local before="$1"
    local after="$2"
    local diff_file="$3"
    
    if diff -u "$before" "$after" > "$diff_file"; then
        echo "No changes detected"
    else
        echo "Changes detected and saved to: $diff_file"
        echo "Summary of changes:"
        grep '^[+-]' "$diff_file" | grep -v '^[+-][-+]'
    fi
}

main() {
    # Check if an argument is provided with better error message
    if [[ $# -ne 1 ]]; then
        echo "Error: Missing plist name argument" >&2
        echo "Usage: $0 <plist-name>" >&2
        echo "Example: $0 com.apple.symbolichotkeys" >&2
        exit 1
    fi

    readonly PLIST_NAME="$1"
    readonly BASENAME=$(basename "$PLIST_NAME" .plist)
    readonly OUTPUT_DIR="${DESKTOP_PATH}/${BASENAME}_monitor_${TIMESTAMP}"

    # Create output directory
    mkdir -p "$OUTPUT_DIR"

    # Capture initial state
    BEFORE_FILE="$OUTPUT_DIR/before.txt"
    capture_state "$BEFORE_FILE"

    echo "Monitoring $PLIST_NAME for changes..."
    echo "Please make your changes in System Settings now."
    echo "Press Enter when you're done to see the differences..."
    read

    # Capture after state
    AFTER_FILE="$OUTPUT_DIR/after.txt"
    capture_state "$AFTER_FILE"

    # Compare and show differences
    DIFF_FILE="$OUTPUT_DIR/changes.diff"
    compare_states "$BEFORE_FILE" "$AFTER_FILE" "$DIFF_FILE"

    # Create a summary file with better formatting
    readonly SUMMARY_FILE="$OUTPUT_DIR/summary.txt"
    {
        printf "Plist Monitor Results\n"
        printf "====================\n"
        printf "Target Plist: %s\n" "$PLIST_NAME"
        printf "Timestamp: %s\n" "$(date)"
        printf "-------------------\n"
        printf "Changes detected:\n\n"
        grep '^[+-]' "$DIFF_FILE" | grep -v '^[+-][-+]'
    } > "$SUMMARY_FILE"

    echo
    echo "Monitor session completed."
    echo "All files are saved in: $OUTPUT_DIR"
}

# Execute main function
main "$@" 
