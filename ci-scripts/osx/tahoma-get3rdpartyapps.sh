#!/bin/bash
# Compatibility wrapper — use tahoma-bundle-apps.sh (FFmpeg staged from Homebrew build).
set -e
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/tahoma-bundle-apps.sh"
