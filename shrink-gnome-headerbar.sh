#!/usr/bin/env bash
#
# Shrinks GTK4 headerbars.
#
# GtkHeaderBar, AdwHeaderBar (i.e. nearly every modern GNOME app: files,
# settings, calculator, text-editor, ...) via user CSS at
# ~/.config/gtk-4.0/gtk.css.
# Verified pixel-stable against stock with Atspi. Selectors are stock GTK4 (no
# libadwaita dependency); GTK3 partial via symlink.
#
#   ./shrink-gnome-headerbar.sh --size 26 --force      # 28px-tall bars
#   ./shrink-gnome-headerbar.sh --size 46              # parity (empty CSS)
#   ./shrink-gnome-headerbar.sh                        # default --size 28
#
# Re-launch GTK apps to see the change. GTK3 symlinks to the same file.
#
# Why this exists: most "shrink headerbar" snippets online drift buttons toward
# the window edge as the bar contracts, or silently no-op because GTK4 drops
# nearly every rule with !important. This script is calibrated against actual
# widget bounds (Atspi) and uses two non-obvious rules:
#
#   1. Vertical knobs scale with SIZE/46; horizontal knobs stay at stock.
#      Buttons shrink in place instead of drifting right.
#   2. At SIZE >= 46 emit empty CSS -- anything else (even values identical to
#      stock) introduces 1px deltas.
#
# GTK4 gotchas:
#   - !important is silently dropped on min-height, min-width, padding-bottom,
#     and most shorthand. Don't add it; use longhand and explicit `px` units.
#   - User CSS at ~/.config/gtk-4.0/gtk.css IS loaded at PRIORITY_USER (highest),
#     beating libadwaita's THEME priority. The "user CSS doesn't work on Ubuntu"
#     folklore is wrong -- your rules just have to parse cleanly.
#   - Direct-child selectors (`headerbar > button`) miss most app buttons
#     because libadwaita nests them under panel widgets. Use `headerbar button`
#     and rely on specificity to override windowcontrols separately.
set -euo pipefail

SIZE=28
FORCE=0

usage() {
    cat >&2 <<EOF
usage: $0 [--size N] [--force]
  --size N   target headerbar height in px (default: 20, stock: 46)
             SIZE >= 46 writes empty CSS (true stock parity).
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
(( SIZE >= 18 )) || { echo "--size must be >= 18 (windowcontrols floor)" >&2; exit 1; }

# Bash integer rounding: (n*SIZE + 23) / 46.
scale() { echo $(( ( $1 * SIZE + 23 ) / 46 )); }
clamp() { local lo=$1 v=$2 hi=$3; (( v < lo )) && v=$lo; (( v > hi )) && v=$hi; echo "$v"; }

GTK4="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0/gtk.css"
GTK3="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/gtk.css"
mkdir -p "$(dirname "$GTK4")" "$(dirname "$GTK3")"

if (( SIZE >= 46 )); then
    # Parity mode. Empty file = no overrides at all = true stock.
    CSS="/* Headerbar override: --size ${SIZE} >= stock 46.
 * Empty stylesheet: libadwaita defaults render unmodified. */
"
else
    # Vertical knobs scale; horizontal knobs stay at stock.
    PAD_TOP=$(clamp 0 "$(scale 6)" 6)   # inner box padding top (stock: 6)
    PAD_BOT=$(clamp 0 "$(scale 7)" 7)   # inner box padding bottom (stock: 7)
    BTN_V=$(clamp   0 "$(scale 5)" 5)   # button padding top/bottom (stock: 5)
    # Font shrinks gentler than other knobs: linear interp 11pt -> 7pt across
    # SIZE 46 -> 18, instead of the 0-anchored scale() the others use.
    FONT_PT=$(( 7 + ( 4 * (SIZE - 18) + 14 ) / 28 ))
    ICON_PX=$(clamp 10 "$(scale 16)" 16) # general icon size (stock: 16)
    WC_SIZE=$(clamp 14 "$(scale 22)" 22) # windowcontrols button (stock: 22)
    WC_PAD=$(clamp   2 "$(scale 4)"  4)  # windowcontrols padding (stock: 4)
    # Windowcontrols glyph shrinks gentler than other knobs: linear interp
    # 16px -> 10px across SIZE 46 -> 18, like FONT_PT above.
    WC_ICON=$(( 10 + ( 6 * (SIZE - 18) + 14 ) / 28 ))

    # Horizontal anchor compensation: as windowcontrols shrink from stock 34px,
    # the right end-box contracts and buttons drift right. Grow inner-box
    # horizontal padding to push the cluster back. Capped at +6 because button
    # widths floor at 22px (rendered_wc_w hits min around SIZE=33; below that
    # further padding growth overshoots and pushes close button LEFT of stock).
    COMP=$(( ( 46 - SIZE ) / 3 ))
    (( COMP > 6 )) && COMP=6
    PAD_SIDE=$(( 7 + COMP ))

    CSS="/* Compact GTK headerbar. Target height: ${SIZE}px (stock: 46).
 * Vertical metrics scale with SIZE; horizontal metrics stay at stock so the
 * right-side button cluster stays anchored.
 *
 *   bar_height = PAD_TOP + PAD_BOT + max(button_total, label_total)
 *   button_total = 2 * BTN_V + ICON_PX
 *
 * Notes:
 *   - 'headerbar button' is broad on purpose; calc nests buttons many levels
 *     deep inside CenterBox > panel > panel, so direct-child selectors miss.
 *   - 'windowcontrols > button' has higher specificity, so it wins for
 *     min/max/close even though 'headerbar button' also matches them.
 *   - Only padding-top/bottom on buttons is overridden; left/right padding
 *     stays at stock so button widths and X positions don't drift.
 *   - GTK4 silently drops most rules with !important. Don't add it.
 *   - Popover font leak: 'headerbar label { font-size: ... }' also matches
 *     labels inside menubutton popovers (dropdown menu items etc.), shrinking
 *     their text. Rule (7) restores stock font-size in popovers via 'unset',
 *     which walks back up the inheritance chain to the theme default.
 *     Geometry overrides (min-height / padding on popover buttons) were
 *     tried and discarded -- they measurably thickened the headerbar in
 *     gnome-calculator, likely because GTK4 includes popover contents in
 *     the menubutton's natural-size measure even when the popover is closed.
 *     font-size is inheritable and doesn't participate in size measure, so
 *     restoring just text is safe. Popover button min-heights remain
 *     unshrunk because rule (3) sets 'min-height: 0' which doesn't shrink
 *     the buttons below their natural icon+padding size anyway.
 */

/* (1) Bar height floor */
headerbar, .titlebar {
    min-height: ${SIZE}px;
}

/* (2) Inner-box vertical padding shrinks; horizontal GROWS as bar shrinks
 *     to anchor the close-button right cluster. Stock=7; at SIZE=30 ~= 12. */
headerbar > windowhandle > box {
    padding-top:    ${PAD_TOP}px;
    padding-bottom: ${PAD_BOT}px;
    padding-left:   ${PAD_SIDE}px;
    padding-right:  ${PAD_SIDE}px;
}

/* (3) All headerbar buttons: shrink vertically only.
 *     Width/X are preserved by leaving padding-left/right alone. */
headerbar button {
    min-height:     0;
    padding-top:    ${BTN_V}px;
    padding-bottom: ${BTN_V}px;
}

/* (4) Windowcontrols (min/max/close) -- higher specificity overrides (3).
 *     Scaled from stock 22x22 with 4px padding. */
headerbar windowcontrols > button {
    min-height: ${WC_SIZE}px;
    min-width:  ${WC_SIZE}px;
    padding:    ${WC_PAD}px;
}
headerbar windowcontrols > button image {
    -gtk-icon-size: ${WC_ICON}px;
}

/* (5) Icon size for non-windowcontrols buttons */
headerbar button image {
    -gtk-icon-size: ${ICON_PX}px;
}

/* (6) Title text */
headerbar label {
    font-size: ${FONT_PT}pt;
}

/* (7) Restore stock font-size for popover labels (menu items etc.) so the
 *     shrunk title font doesn't leak into dropdown menus. See header note
 *     for why only font-size is restored (geometry overrides backfire). */
headerbar popover label {
    font-size: unset;
}
"
fi

if [[ -e "$GTK4" && $FORCE -eq 0 ]]; then
    diff <(printf '%s' "$CSS") "$GTK4"
else
    printf '%s' "$CSS" > "$GTK4"
fi

[[ -L "$GTK3" || $FORCE -eq 0 ]] || rm -f "$GTK3"
[[ -L "$GTK3" ]] || ln -s ../gtk-4.0/gtk.css "$GTK3"
[[ "$(readlink "$GTK3")" == "../gtk-4.0/gtk.css" ]]
