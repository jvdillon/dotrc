#!/usr/bin/env bash
set -euo pipefail

SERVER=/usr/libexec/gnome-terminal-server
RESOURCE=/org/gnome/terminal/ui/headerbar.ui
OVERLAY_ROOT="${XDG_CACHE_HOME:-$HOME/.cache}/gnome-terminal-compact-overlay"
OVERLAY_FILE="$OVERLAY_ROOT/ui/headerbar.ui"
PIXEL_SIZE=12
ISOLATED=0

if [[ ${1:-} == --isolated ]]; then
    ISOLATED=1
    shift
fi

mkdir -p "$(dirname "$OVERLAY_FILE")"
gresource extract "$SERVER" "$RESOURCE" > "$OVERLAY_FILE"
python3 - "$OVERLAY_FILE" "$PIXEL_SIZE" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
pixel_size = sys.argv[2]
text = path.read_text()
text = text.replace(
    '<property name="show-close-button">True</property>',
    '<property name="show-close-button">True</property>\n    <property name="has-subtitle">False</property>',
    1,
)
for icon in ('tab-new-symbolic', 'pan-down-symbolic', 'open-menu-symbolic', 'edit-find-symbolic'):
    text = text.replace(
        f'<property name="icon_name">{icon}</property>',
        f'<property name="icon_name">{icon}</property>\n                <property name="pixel-size">{pixel_size}</property>',
        1,
    )
path.write_text(text)
PY

export G_RESOURCE_OVERLAYS="/org/gnome/terminal=$OVERLAY_ROOT${G_RESOURCE_OVERLAYS:+:$G_RESOURCE_OVERLAYS}"

if (( ISOLATED )); then
    exec dbus-run-session -- gnome-terminal --wait "$@"
fi

exec gnome-terminal "$@"
