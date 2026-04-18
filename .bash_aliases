export EMAIL='abc@xyz.com'

alias vi='nvim'
alias vim='nvim'
alias vimdiff='nvim -d'
export EDITOR='nvim'
export VISUAL="$EDITOR"
export MANPAGER='nvim +Man!'

# uvr is now in ~/.local/bin/uvr (symlink to ~/research/docs/ubuntu/uvr)
# To get the function + RESEARCH_ROOT exported, source it:
#   source ~/.local/bin/uvr
# Or just use it directly since ~/.local/bin is in PATH
# Old:
#   # alias uvr='uv --quiet --project ~/research run --no-sync "$@"'
#   uvr() {
#       uv --quiet --project ~/research run --no-sync "$@"
#   }

alias fixaudio='systemctl --user restart pipewire pipewire-pulse wireplumber'

restart-dash-to-panel() {
    gnome-extensions disable dash-to-panel@jderose9.github.com
    gnome-extensions enable dash-to-panel@jderose9.github.com
}

# sudo apt install lynx pandoc html2text libjs-mathjax
md () { pandoc -t plain "$1"; }

# Helper function to calculate scaled window dimensions
# Usage: _calc_scaled_geometry <percent> <image_file>
# Outputs: "WIDTHxHEIGHT"
_calc_scaled_geometry() {
    local percent="$1"
    local file="$2"

    # Get screen dimensions
    local screen_w="$(xdpyinfo | awk '/dimensions/{print $2}' | cut -d'x' -f1)"
    local screen_h="$(xdpyinfo | awk '/dimensions/{print $2}' | cut -d'x' -f2)"

    # Get image dimensions
    local img_dims="$(identify -format "%wx%h" "$file" 2>/dev/null)"
    local img_w="$(echo "$img_dims" | cut -d'x' -f1)"
    local img_h="$(echo "$img_dims" | cut -d'x' -f2)"

    # Calculate max dimensions at percent of screen
    local max_w=$((screen_w * percent / 100))
    local max_h=$((screen_h * percent / 100))

    # Scale image to fit within max dimensions, preserving aspect ratio
    local scale_w=$((max_w * 1000 / img_w))
    local scale_h=$((max_h * 1000 / img_h))
    local scale=$((scale_w < scale_h ? scale_w : scale_h))

    local win_w=$((img_w * scale / 1000))
    local win_h=$((img_h * scale / 1000))

    echo "${win_w}x${win_h}"
}

fv() {
    local percent=75
    local file="$1"

    # If first arg is a number, treat it as percent and shift
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        percent="$1"
        shift
        file="$1"
    fi

    local geometry="$(_calc_scaled_geometry "$percent" "$file")"
    feh --scale-down --auto-zoom --geometry "$geometry" "$@"
}

sv() {
    local percent=75
    local file="$1"

    # If first arg is a number, treat it as percent and shift
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        percent="$1"
        shift
        file="$1"
    fi

    # If a single file is given, open all images in that directory
    if [[ -f "$file" ]]; then
        local dir="$(dirname "$file")"
        local geometry="$(_calc_scaled_geometry "$percent" "$file")"
        # Get all image files in directory, sorted
        shopt -s nullglob
        local images=("$dir"/*.{jpg,jpeg,JPG,JPEG,png,PNG,gif,GIF,bmp,BMP,webp,WEBP})
        shopt -u nullglob
        if [[ ${#images[@]} -gt 0 ]]; then
            sxiv -g "$geometry" "${images[@]}"
        else
            sxiv -g "$geometry" "$file"
        fi
    else
        # If directory or glob pattern, just pass through
        if [[ -n "$file" ]]; then
            local geometry="$(_calc_scaled_geometry "$percent" "$file")"
            sxiv -g "$geometry" "$@"
        else
            echo "Usage: sv [percent] <image-file>"
            return 1
        fi
    fi
}

# Navigate images in sxiv:
#   Left/Right arrow OR n/p - previous/next image
#   Space - next image
#   Backspace - previous image
#   q - quit
#   f - fullscreen toggle
#   w - fit to width
#   h - fit to height
#   W - fit window to image

md2html () {
    # ?config=TeX-AMS-MML_HTMLorMML
    pandoc --mathjax=https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=Accessible -s --variable pagetitle=" " "$@"
}

md2html_local () {
    # ?config=TeX-AMS-MML_HTMLorMML
    pandoc --mathjax=/usr/share/javascript/mathjax/MathJax.js?config=Accessible -s --variable pagetitle=" " "$@"
}

# pdftk A=contract.pdf B=signature.pdf cat A1-r2 B1 output contract-signed.pdf

codesearch() {
    local path="$1"
    shift
    #local path="${!#}"  # Get the value of the last argument
    #set -- "${@:1:$(($#-1))}" # Reassign positional parameters without the last one
    echo find -L "$path" -type f -iname \*.py -not -path \*.venv\* -exec grep -H --color "$@" "{}" \;
    find -L "$path" -type f -iname \*.py -not -path \*.venv\* -exec grep -H --color "$@" "{}" \;
}

codesearch0() {
    # codesearch0 . -Ei --color import.*sys | cut -d: -f1 | sort | uniq | wc -l
    local path="$1"
    shift
    find -L "$path" -type f -iname \*.py -not -path \*.venv -exec grep -H --color "$@" "{}" \; -print0 |xargs -0
}


togif() {
    local input="$1"
    local output="${2:-${input%.*}.gif}"
    local fps="${3:-15}"
    local height="${4:-270}"

    # Test files:
    #   wget https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/1080/Big_Buck_Bunny_1080_10s_30MB.mp4
    #   wget http://distribution.bbb3d.renderfarming.net/video/mp4/bbb_sunflower_1080p_30fps_normal.mp4

    # References:
    #   https://ffmpeg.org/ffmpeg-filters.html#Filtering-Introduction
    #   https://blog.pkh.me/p/21-high-quality-gif-with-ffmpeg.html
    #   https://stackoverflow.com/questions/42980663/ffmpeg-high-quality-animated-gif

    # Note: Google slides are 960x540.

    [[ -z "$input" ]] && { echo "Usage: togif input [output] [fps] [height]"; return 1; }

    # -filter_complex "fps=$fps,scale=-1:$height:flags=lanczos,split[v1][v2];[v1]palettegen=stats_mode=full[palette];[v2][palette]paletteuse=dither=sierra2_4a" \
    ffmpeg -nostdin -hide_banner -loglevel error -y \
        -i "$input" \
        -filter_complex "fps=$fps,scale=-1:$height:flags=lanczos+accurate_rnd+full_chroma_int,split[v1][v2];[v1]palettegen=max_colors=256:stats_mode=single[palette];[v2][palette]paletteuse=dither=floyd_steinberg:diff_mode=rectangle:new=1" \
        -fps_mode passthrough \
        "$output"
}

pipinstall() { python3 -m pip install --user --upgrade --break-system-packages "$@"; }

httpserver() { python -m http.server "${1:-80}"; }

# export SDL_AUDIODRIVER=alsa
# export AUDIODEV=hw:0,0


# <<<"" is a "here string" (as opposed to a "here document")
? () { bc <<< "$*"; }
toupper () { echo "$*" | tr '[:lower:]' '[:upper:]'; }
tolower () { echo "$*" | tr '[:upper:]' '[:lower:]'; }
hex2dec () { echo "ibase=16;obase=A;$(toupper "$*")" | \bc; }
dec2hex () { echo "obase=16;$(toupper "$*")" | \bc; }
bin2dec () { echo "ibase=2;obase=A;$*" | \bc; }
dec2bin () { echo "obase=2;$*" | \bc; }



# --- Power
# sudo apt install xdg-utils dbus-x11
lock() {
    if ! amixer sget Master | grep -vq '\[on\]'; then
        # Already muted.
        xdg-screensaver activate
        return
    fi

    xdg-screensaver lock &&
    amixer -q set Master mute &&
    while read -r line; do
        if echo "$line" | grep -q "boolean false"; then
            amixer -q set Master unmute
            break 2
        fi
    done < <(dbus-monitor --session "interface='org.gnome.ScreenSaver',member='ActiveChanged'")
}

blank() {
    if ! amixer sget Master | grep -vq '\[on\]'; then
        # Already muted.
        xdg-screensaver activate
        return
    fi

    xdg-screensaver activate &&
    amixer -q set Master mute &&
    while read -r line; do
        if echo "$line" | grep -q "boolean false"; then
            amixer -q set Master unmute
            break 2
        fi
    done < <(dbus-monitor --session "interface='org.gnome.ScreenSaver',member='ActiveChanged'")
}

suspend_() { systemctl suspend -i; }

hibernate() { systemctl hibernate; }


# --- Network
# --archive --partial --progress --human-readable --verbose
# --recursive --compress
alias smartscp="rsync -aPhv --no-r --stats --rsh=ssh"
# backing-up: smartscp -rz --del user@remote:/path/to/src /path/to/dest
# DANGER: deletes files that aren't on the sending side
# also, a real backup can be done as:
# su; dd if=/dev/hda1 | gzip | ssh userid@remote_host 'dd of=hda1.gz'


whatsmyip () { curl --silent canhazip.com || curl --silent https://ipinfo.io/ip; }

whatsmyhost () { host "$(whatsmyip)"; }


checkvpn() {
    # Get the actual connected server info
    # Example: get_vpn_region|sed "2q;d"
    # Example: readarray -t info < <(get_vpn_region)
    # Example: get_vpn_region | xargs
    local state="$(piactl -u dump daemon-state 2>/dev/null)"
    local info=($(piactl get region 2>/dev/null || echo "Unknown"))
    info+=($(echo "$state" | jq -r '.connectedServer | [.commonName // "none", .ip // "none"] | join(" ")'))
    info+=($(echo "$state" | jq -r '.connectedConfig.vpnLocation.id' | sed -e 's/_/-/g'))
    info+=($(echo "$state" | jq -r '.overrideDNS'))
    printf "%s\n" "${info[@]}"
    #echo "${info[@]}"
    # piactl get connectionstate
    # wget https://www.privateinternetaccess.com/what-is-my-ip -O- 2>&1 | \grep -o "You are connected to PIA"
}



bandwidth_mbps() {
    local interval="${1:-3}"
    local iface="${2:-tun0}"

    local mbits0="$(_get_mbits "$iface")"
    sleep "$interval"
    local mbits1="$(_get_mbits "$iface")"

    if [[ "$mbits0" -lt "0" ]] || [[ "$mbits1" -lt "0" ]]; then
        echo "-1"
        return 1
    fi

    local mbits_diff=$((mbits1 - mbits0))
    local mbits_per_sec=$((mbits_diff / interval))

    echo "$mbits_per_sec"
}


_get_mbits() {
    local iface="$1"

    local stats="$([[ -z "$iface" ]] || ip -s link show "$iface" 2>/dev/null)"
    if [[ -z "$stats" ]]; then
        echo "0"
        return 1
    fi
    local rx_bytes="$(echo "$stats" | grep -A1 "RX:" | tail -1 | awk '{print $1}')"
    local tx_bytes=0 # $(echo "$stats" | grep -A1 "TX:" | tail -1 | awk '{print $1}')

    # Validate that we got numeric values
    if ! [[ "$rx_bytes" =~ ^[0-9]+$ ]] || ! [[ "$tx_bytes" =~ ^[0-9]+$ ]]; then
        echo "-1"
        return 1
    fi
    # 131072 = 1024 * 1024 / 8
    local total_mbits=$(((rx_bytes + tx_bytes) / 131072))
    echo "$total_mbits"
}

now () {
    date +"%a %b %d %-I:%M:%S%#p"
}


# --- System
alias df='df -h'
alias bc='bc -l'

# # Create PDF:
# pandoc ~/GB.md -o /tmp/out.pdf -V fontsize=10pt --pdf-engine=xelatex -V geometry:margin=1.0in
#
# # Create 2x1 PDF:
# pandoc ~/GB.md -o /tmp/out.pdf -V fontsize=11pt --pdf-engine=xelatex -V geometry:twoside -V geometry:inner=0.5in -V geometry:outer=0.25in -V geometry:top=0.5in -V geometry:bottom=0.5in
# pdfjam --nup 2x1 --landscape /tmp/out.pdf -o /tmp/out-2up.pdf 
# 
# # Preview:
# evince /tmp/out.pdf
# 
# # Print (1-up, long edge):
# lp -o sides=two-sided-long-edge /tmp/out.pdf
# 
# # Print (2-up, short edge, landscape):
# lp -o number-up=2 -o landscape -o sides=two-sided-short-edge /tmp/out.pdf


# # Preview
# mdcat.py --ascii ~/GB.md | enscript -G -f Courier-Bold10 -o - | psview
#
# # 2-up, short edge:
# mdcat.py --ascii ~/GB.md | enscript -2rG -f Courier-Bold7 -DDuplex:DuplexTumble
#
# # 1-up, long edge:
# mdcat.py --ascii ~/GB.md | enscript -G -f Courier-Bold10 -DDuplex:DuplexNoTumble

psview() { local f="$(mktemp --suffix=.ps)"; cat > "$f"; /usr/bin/evince "$f" & }

alias printcode='enscript -2rGE -DDuplex:true -DTumble:true'


rebootrequired() { [ -f /var/run/reboot-required ] && cat /var/run/reboot-required; }
meminfo() { vmstat -s -S M | grep mem; }

vol() {
    if [ x"$1" = x"+" ]; then
        amixer -q set Master 5%+
    elif [ x"$1" = x"-" ]; then
        amixer -q set Master 5%-
    elif [ x"$1" = x"m" ]; then
        amixer -q set Master toggle
    else
        #echo "invalid option"
        amixer get 'Master'
    fi
}


findgrep () { find . -iname "$1" -exec grep -Hi --color "$2" {} \;; }

epochget() { date "+%s"; }

epochfmt() {
    local tz="$(date "+%z" | sed -e 's/-/+/')"
    echo "$(date -u --date "Jan 1, 1970 00:00:00 $tz +$1 seconds" "+%m/%d %k:%M:%S")"
}

epochdiff() {
    echo "$(date -u --date "Jan 1, 1970 00:00:00 +0000 +$(($1 - $2)) seconds" "+%k:%M:%S")"
}

# sudo apt install festival festvox-us-slt-hts sox
say () { festival -b "(voice_cmu_us_slt_arctic_hts)" "(SayText \"$*\")"; }
# say () { festival -b "(voice_cmu_us_slt_arctic_hts)" "(Parameter.set 'Audio_Command \"play -q -v 0.985 -b 16 -c 1 -e signed-integer -r \$SR -t raw \$FILE tempo 0.6 pitch -150\")" "(Parameter.set 'Audio_Method 'Audio_Command)" "(SayText \"$*\")"; }


alias xev="xev | grep -A2 --line-buffered '^KeyRelease' | sed -n '/keycode /s/^.*keycode \([0-9]*\).* (.*, \(.*\)).*$/\1 \2/p'"
pause  () { kill -SIGSTOP "$(pidof "$1")"; }
resume () { kill -SIGCONT "$(pidof "$1")"; }


# --- Python

export PYTHONSTARTUP="$HOME/.pystartup"
alias ipython3='ipython3 --no-confirm-exit --no-banner'
alias ipython='ipython3'
# pip install --user notebook jupyter
alias jupyter-kernel="jupyter notebook --NotebookApp.allow_origin='https://colab.research.google.com' --port=8888 --NotebookApp.port_retries=0"

reverse() { python3 -c 'import fileinput as f; print(*reversed(list(f.input())), end="")' "$@"; }
sum()     { python3 -c 'import fileinput as f; print(sum(float(n) for line in f.input() for n in line.split()))' "$@"; }
min()     { python3 -c 'import fileinput as f; print(min(float(n) for line in f.input() for n in line.split()))' "$@"; }
max()     { python3 -c 'import fileinput as f; print(max(float(n) for line in f.input() for n in line.split()))' "$@"; }
median()  { python3 -c 'import fileinput as f, statistics as s; print(s.median(float(n) for line in f.input() for n in line.split()))' "$@"; }
mean()    { python3 -c 'import fileinput as f, statistics as s; print(s.mean(float(n) for line in f.input() for n in line.split()))' "$@"; }
std()     { python3 -c 'import fileinput as f, statistics as s; print(s.stdev(float(n) for line in f.input() for n in line.split()))' "$@"; }
stats()   { python3 -c 'import fileinput as f, statistics as s; x=tuple(float(n) for line in f.input() for n in line.split()); print(min(x), s.median(x), max(x), s.mean(x), s.stdev(x), sep='\n')' "$@"; }


# --- Latex
xdvi  () { /usr/bin/xdvi   "$1" &>/dev/null & }
evince() { /usr/bin/evince "$1" &>/dev/null & }

# watch -n1 'awk "{printf \"%.1f W\n\", \$1/1000000}" /sys/class/power_supply/BAT*/power_now'
power_draw() {
    awk '{printf "%.1f W\n", $1/1000000}' /sys/class/power_supply/BAT*/power_now
}
