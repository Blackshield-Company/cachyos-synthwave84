#!/usr/bin/env bash
# Re-apply Synthwave84 tray icons to Vesktop's app.asar after package updates.
# Vesktop hands raw pixmaps to Plasma SNI (no icon-theme lookup), so the tray
# icons live inside the asar and updates overwrite them. Re-run after every
# vesktop-bin bump. Requires: @electron/asar (hermes ships one), sudo.
set -euo pipefail
ASAR="${ASAR_BIN:-$HOME/.hermes/hermes-agent/node_modules/.bin/asar}"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

"$ASAR" extract /opt/vesktop/resources/app.asar "$WORK/app"
cp "$SRC/tray.png"         "$WORK/app/static/tray/tray.png"
cp "$SRC/trayUnread.png"   "$WORK/app/static/tray/trayUnread.png"
cp "$SRC/trayTemplate.png" "$WORK/app/static/tray/trayTemplate.png"
cp "$SRC/tray.png"         "$WORK/app/static/tray.png"
"$ASAR" pack "$WORK/app" "$WORK/app.asar"

[ -f /opt/vesktop/resources/app.asar.orig ] || \
  sudo cp /opt/vesktop/resources/app.asar /opt/vesktop/resources/app.asar.orig
sudo install -m 644 -o root -g root "$WORK/app.asar" /opt/vesktop/resources/app.asar
echo "Synthwave84 tray icons applied. Restart Vesktop."
