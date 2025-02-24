#!/usr/bin/env bash

set -euo pipefail

# Check if an argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <plist-name>"
    echo "Example: $0 com.apple.symbolichotkeys"
    exit 1
fi

PLIST_NAME=$1
DESKTOP_PATH="$HOME/Desktop"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BASENAME=$(basename "$PLIST_NAME" .plist)
OUTPUT_DIR="$DESKTOP_PATH/${BASENAME}_monitor_${TIMESTAMP}"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Function to capture current state
capture_state() {
    local output_file="$1"
    defaults read "$PLIST_NAME" > "$output_file"
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

# Create a summary file
SUMMARY_FILE="$OUTPUT_DIR/summary.txt"
{
    echo "Plist Monitor Results"
    echo "===================="
    echo "Target Plist: $PLIST_NAME"
    echo "Timestamp: $(date)"
    echo "-------------------"
    echo "Changes detected:"
    echo
    grep '^[+-]' "$DIFF_FILE" | grep -v '^[+-][-+]'
} > "$SUMMARY_FILE"

echo
echo "Monitor session completed."
echo "All files are saved in: $OUTPUT_DIR"
