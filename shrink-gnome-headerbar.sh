#!/usr/bin/env bash
#
# Writes compact GTK headerbar CSS to:
#   ~/.config/gtk-4.0/gtk.css
#   ~/.config/gtk-3.0/gtk.css
#
# GNOME Terminal is GTK3 but also needs its embedded headerbar images capped;
# install that launcher with ./install-gnome-terminal-compact.sh.
#
# Re-launch GTK apps to see changes. Tested with:
#   dbus-run-session -- gnome-terminal --wait
#   gnome-calculator
#   gnome-clocks
set -euo pipefail

SIZE=26
FORCE=0
FONT_PT=11
GTK4_ICON_PX=12
STOCK_SIZE=46

usage() {
    cat >&2 <<EOF
usage: $0 [--size N] [--force]
  --size N   target headerbar height in px (default: $SIZE, stock: $STOCK_SIZE)
             SIZE >= $STOCK_SIZE writes empty CSS (stock parity).
  --force    overwrite existing config without diff check
EOF
    exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --size)     SIZE="${2:?--size needs a value}"; shift 2 ;;
        --size=*)   SIZE="${1#*=}"; shift ;;
        --force|-f) FORCE=1; shift ;;
        -h|--help)  usage 0 ;;
        *) echo "unknown arg: $1" >&2; usage 1 ;;
    esac
done

[[ "$SIZE" =~ ^[0-9]+$ ]] || { echo "--size must be a positive integer" >&2; exit 1; }
(( SIZE >= 18 )) || { echo "--size must be >= 18" >&2; exit 1; }

GTK4="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0/gtk.css"
GTK3="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/gtk.css"
mkdir -p "$(dirname "$GTK4")" "$(dirname "$GTK3")"

if (( SIZE >= STOCK_SIZE )); then
    CSS_GTK4="/* Headerbar override: --size ${SIZE} >= stock ${STOCK_SIZE}.
 * Empty stylesheet: GTK4/libadwaita defaults render unmodified. */
"
    CSS_GTK3="/* Headerbar override: --size ${SIZE} >= stock ${STOCK_SIZE}.
 * Empty stylesheet: GTK3 defaults render unmodified. */
"
else
    CSS_GTK4="/* Compact GTK4 headerbar. Target height: ${SIZE}px (stock: ${STOCK_SIZE}). */

headerbar, .titlebar {
    min-height: ${SIZE}px;
}

headerbar > windowhandle > box {
    padding-top:    0px;
    padding-bottom: 0px;
}

headerbar button {
    min-height:     0;
    padding-top:    0px;
    padding-bottom: 0px;
}

headerbar windowcontrols > button {
    min-height: ${SIZE}px;
    min-width:  ${SIZE}px;
    margin:     0px;
    padding:    0px;
    font-size:  ${FONT_PT}pt;
}

headerbar windowcontrols > button image {
    -gtk-icon-size: ${GTK4_ICON_PX}px;
}

headerbar button image {
    -gtk-icon-size: ${GTK4_ICON_PX}px;
}

headerbar label {
    font-size: ${FONT_PT}pt;
}

headerbar popover label {
    font-size: unset;
}

headerbar viewswitcher {
    min-height: 0;
}

headerbar viewswitcher button.toggle > stack > box.wide {
    padding-top:    1px;
    padding-bottom: 1px;
}
"

    CSS_GTK3="/* Compact GTK3 headerbar. Target height: ${SIZE}px (stock: ${STOCK_SIZE}).
 * GNOME Terminal also needs ~/.local/bin/gnome-terminal-compact to cap the
 * headerbar.ui image widgets. */

headerbar, .titlebar {
    min-height:     ${SIZE}px;
    padding-top:    0;
    padding-bottom: 0;
}

headerbar *,
.titlebar * {
    min-height:     ${SIZE}px;
    min-width:      ${SIZE}px;
    margin:         0px;
    padding:        0px;
    font-size:      ${FONT_PT}pt;
}
"
fi

write_css() {
    local path=$1 css=$2
    if [[ -e "$path" && $FORCE -eq 0 ]]; then
        diff <(printf '%s' "$css") "$path"
    else
        [[ -L "$path" ]] && rm -f "$path"
        printf '%s' "$css" > "$path"
    fi
}

write_css "$GTK4" "$CSS_GTK4"
write_css "$GTK3" "$CSS_GTK3"
