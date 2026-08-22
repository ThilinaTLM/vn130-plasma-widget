#!/usr/bin/env bash

set -euo pipefail

readonly PACKAGE_ID="org.local.vn130connector"
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v kpackagetool6 >/dev/null 2>&1; then
    echo "Error: kpackagetool6 was not found. Install the KDE Plasma 6 development tools." >&2
    exit 1
fi

if kpackagetool6 --type Plasma/Applet --list | grep -Fxq "$PACKAGE_ID"; then
    echo "Upgrading $PACKAGE_ID..."
    kpackagetool6 --type Plasma/Applet --upgrade "$SCRIPT_DIR"
else
    echo "Installing $PACKAGE_ID..."
    kpackagetool6 --type Plasma/Applet --install "$SCRIPT_DIR"
fi

cat <<'EOF'

VN130 Controller is installed for the current user and registered as a Plasma
system tray applet.

To show it in the tray:
  1. Right-click the system tray and choose Configure System Tray...
  2. Open Entries.
  3. Set VN130 Controller to Always shown or Shown when relevant.

If it is not listed immediately, restart Plasma or sign out and back in.
EOF
