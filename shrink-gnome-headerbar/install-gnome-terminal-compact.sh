#!/usr/bin/env bash
set -euo pipefail

APP_ID=org.gnome.Terminal.desktop
SOURCE_DESKTOP=/usr/share/applications/$APP_ID
LOCAL_BIN=${HOME}/.local/bin
LOCAL_APPS=${HOME}/.local/share/applications
SYSTEMD_USER_DIR=${HOME}/.config/systemd/user/gnome-terminal-server.service.d
WRAPPER_NAME=gnome-terminal-compact
WRAPPER_TARGET=$LOCAL_BIN/$WRAPPER_NAME
DESKTOP_TARGET=$LOCAL_APPS/$APP_ID
OVERRIDE_TARGET=$SYSTEMD_USER_DIR/override.conf
SERVER=/usr/libexec/gnome-terminal-server
RESOURCE=/org/gnome/terminal/ui/headerbar.ui
OVERLAY_ROOT=${XDG_CACHE_HOME:-$HOME/.cache}/gnome-terminal-compact-overlay
OVERLAY_FILE=$OVERLAY_ROOT/ui/headerbar.ui
PIXEL_SIZE=15

usage() {
    cat >&2 <<EOF
usage: $0 [install|uninstall]

install     Install compact GNOME Terminal launcher for this user.
uninstall   Remove the user launcher override, systemd override, and wrapper.
EOF
    exit "${1:-0}"
}

refresh_desktop_database() {
    command -v update-desktop-database >/dev/null || return 0
    update-desktop-database "$LOCAL_APPS" >/dev/null 2>&1 || true
}

reload_user_systemd() {
    systemctl --user daemon-reload >/dev/null 2>&1 || true
}

write_overlay() {
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
}

write_wrapper() {
    cat > "$WRAPPER_TARGET" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

SERVER=/usr/libexec/gnome-terminal-server
RESOURCE=/org/gnome/terminal/ui/headerbar.ui
OVERLAY_ROOT="${XDG_CACHE_HOME:-$HOME/.cache}/gnome-terminal-compact-overlay"
OVERLAY_FILE="$OVERLAY_ROOT/ui/headerbar.ui"
PIXEL_SIZE=15
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
EOF
    chmod 0755 "$WRAPPER_TARGET"
}

write_desktop_entry() {
    cp "$SOURCE_DESKTOP" "$DESKTOP_TARGET"
}

write_systemd_override() {
    mkdir -p "$SYSTEMD_USER_DIR"
    cat > "$OVERRIDE_TARGET" <<EOF
[Service]
Environment=G_RESOURCE_OVERLAYS=/org/gnome/terminal=$OVERLAY_ROOT
EOF
}

install_compact_terminal() {
    [[ -f "$SOURCE_DESKTOP" ]] || { echo "missing desktop entry: $SOURCE_DESKTOP" >&2; exit 1; }
    [[ -x "$SERVER" ]] || { echo "missing terminal server: $SERVER" >&2; exit 1; }

    mkdir -p "$LOCAL_BIN" "$LOCAL_APPS"
    write_overlay
    write_wrapper
    write_desktop_entry
    write_systemd_override
    refresh_desktop_database
    reload_user_systemd
    cat <<EOF
Installed compact GNOME Terminal setup:
  $OVERLAY_FILE
  $OVERRIDE_TARGET
  $DESKTOP_TARGET

Normal GNOME launches use stock gnome-terminal; the systemd override supplies the overlay.
$WRAPPER_TARGET remains available only for isolated testing.
Close all existing GNOME Terminal windows before testing the normal launcher.
EOF
}

uninstall_compact_terminal() {
    rm -f "$DESKTOP_TARGET" "$WRAPPER_TARGET" "$OVERRIDE_TARGET"
    rmdir "$SYSTEMD_USER_DIR" >/dev/null 2>&1 || true
    rm -rf "$OVERLAY_ROOT"
    refresh_desktop_database
    reload_user_systemd
    cat <<EOF
Uninstalled compact GNOME Terminal launcher.
Close all existing GNOME Terminal windows, then launch Terminal again to use stock GNOME Terminal.
EOF
}

case "${1:-install}" in
    install) install_compact_terminal ;;
    uninstall) uninstall_compact_terminal ;;
    -h|--help|help) usage 0 ;;
    *) echo "unknown command: $1" >&2; usage 1 ;;
esac
