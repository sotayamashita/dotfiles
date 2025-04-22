#!/usr/bin/env bash

set -euo pipefail

readonly TEXT_URL="https://go.dev/VERSION?m=text"
readonly JSON_URL="https://go.dev/dl/?mode=json"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source utils.sh using the script directory as base
source "${SCRIPT_DIR}/../lib/utils.sh"

# Check if Go is already installed
if command -v go &>/dev/null; then
    info "Go is already installed. Skipping installation."
    exit 0
fi

info "--- Installing Go ---"

# Get latest version from https://go.dev/dl/
readonly LATEST_VERSION=$(curl -fsSL "$JSON_URL" | jq -r 'map(select(.stable == true)) | .[0].version')

# Sanity‑check we got something that looks like "go1.x.y".
if [[ "$LATEST_VERSION" =~ ^go[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    info "Latest version: $LATEST_VERSION"
else
    error "Failed to get latest version"
    exit 1
fi

readonly PKG_FILE="${LATEST_VERSION}.darwin-arm64.pkg"

# Download the package
curl -fsSLO "https://go.dev/dl/${PKG_FILE}"

# Install it system‑wide (requires sudo)
info "Running sudo installer …"
sudo installer -pkg "${PKG_FILE}" -target /

# Update PATH for the current session
source "/usr/local/go/bin/go" || {
    error "Failed to update PATH for the current session"
    exit 1
}

# Verify installation
if command -v go &>/dev/null; then
    info "Go $(go version) installed successfully"
elif [[ -x /usr/local/go/bin/go ]]; then
    info "Go installed at /usr/local/go/bin/go"
    warn "Add /usr/local/go/bin to your PATH or start a new terminal session. See: ~/.config/fish/config.fish"
else
    error "Installer finished but Go binary not found ❌"
    exit 1
fi
