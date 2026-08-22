#!/usr/bin/env bash

set -euo pipefail

readonly PACKAGE_ID="org.local.vn130connector"

if ! command -v kpackagetool6 >/dev/null 2>&1; then
    echo "Error: kpackagetool6 was not found. Install the KDE Plasma 6 development tools." >&2
    exit 1
fi

if ! kpackagetool6 --type Plasma/Applet --list | grep -Fxq "$PACKAGE_ID"; then
    echo "VN130 Controller is not installed for the current user."
    exit 0
fi

echo "Removing $PACKAGE_ID..."
kpackagetool6 --type Plasma/Applet --remove "$PACKAGE_ID"

cat <<'EOF'

VN130 Controller has been uninstalled. If a stale tray entry remains, restart
Plasma or sign out and back in.
EOF
