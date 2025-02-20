#!/usr/bin/env bash

set -euo pipefail

function info() {
    echo -e "\033[0;32m[INFO]: \033[0m $1" >&2
}

function error() {
    echo -e "\033[0;31m[ERROR]:\033[0m $1" >&2
    exit 1
}

function debug() {
    echo -e "\033[0;33m[DEBUG]:\033[0m $1" >&2
}
