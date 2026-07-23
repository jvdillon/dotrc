#!/usr/bin/env bash
# Generate a commit changelog from a diff using sagent's utility model.
#
# Usage:
#   git diff --cached | ai-change-description.sh
#   git show <commit> | ai-change-description.sh
#
# Reads the diff from stdin (a diff can exceed the ARGV_MAX argument-size limit,
# so it must not be passed as an argument), prompts sagent (utility model) once
# per provider in SAGENT_ALLOW_PROVIDERS until one returns a
# BEGIN_COMMIT/END_COMMIT block, and prints the extracted message to stdout.
# Exits nonzero if every provider fails.
#
# Copybarista: any changed file whose directory has an ancestor containing a
# copy.barista.toml belongs to that export package. The prompt is pre-filled
# with a per-package Copybarista-PR-* skeleton and told to scope each package's
# summary to only that package's touched files.
# No `set -e`: a failing sagent call must fall through to the next provider,
# not abort the script.
set -u

diff=$(cat)
if [ -z "$diff" ]; then
    echo "ai-change-description: empty diff on stdin (pipe a diff in)" >&2
    exit 2
fi

command -v sagent >/dev/null || {
    echo "ai-change-description: sagent not found on PATH" >&2
    exit 127
}

# Provider allow-list. Falls back to the subscription providers only when
# SAGENT_ALLOW_PROVIDERS is unset.
providers=$(printf '%s' "${SAGENT_ALLOW_PROVIDERS:-OpenAISubscription,AnthropicSubscription}" | tr ',' ' ')

# --- Copybarista export discovery -------------------------------------------
# Changed paths: the post-image side of each hunk header. Covers adds, edits,
# and rename/copy targets; deletes (``/dev/null``) are filtered out.
changed_paths=$(
    printf '%s\n' "$diff" \
        | sed -n 's|^+++ b/||p' \
        | grep -v '^/dev/null$'
)

# Nearest ancestor directory of $1 that contains a copy.barista.toml, or empty.
_export_root() {
    dir=$(dirname "$1")
    while :; do
        if [ -f "$dir/copy.barista.toml" ]; then
            printf '%s\n' "$dir"
            return 0
        fi
        case "$dir" in
            .|/) return 1 ;;
        esac
        dir=$(dirname "$dir")
    done
}

# Package name from [workflow] name in copy.barista.toml, else the dir's name.
_package_name() {
    name=$(sed -n 's/^[[:space:]]*name[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' \
        "$1/copy.barista.toml" | head -1)
    [ -n "$name" ] && printf '%s\n' "$name" || basename "$1"
}

# Join the given blocks with one blank line between them (none after the last).
_join_blocks() {
    local i
    for i in "$@"; do
        printf '%s\n\n' "$i"
    done | sed -e '${/^$/d;}'
}

# Map each touched file to its export root (tab-separated: root<TAB>path).
root_file_pairs=$(
    printf '%s\n' "$changed_paths" | while IFS= read -r path; do
        [ -n "$path" ] || continue
        root=$(_export_root "$path") || continue
        printf '%s\t%s\n' "$root" "$path"
    done
)

# Build the Copybarista prompt section from the discovered packages.
if [ -n "$root_file_pairs" ]; then
    roots=$(printf '%s\n' "$root_file_pairs" | cut -f1 | sort -u)
    trailers=()
    breakdowns=()
    while IFS= read -r root; do
        [ -n "$root" ] || continue
        pkg=$(_package_name "$root")
        files=$(printf '%s\n' "$root_file_pairs" \
            | awk -F'\t' -v r="$root" '$1==r{print "  - "$2}')
        trailers+=("Copybarista-PR-Scope: $pkg
Copybarista-PR-Title: A <60 char headline sentence capturing the $pkg specific changes.
Copybarista-PR-Body-Mode: append
Copybarista-PR-Body:
- A terse bulleted list of essential details.
- Same style as top-level description but limited to $pkg specific changes.")
        breakdowns+=("Package '$pkg' (export root: $root) touched files:
$files")
    done <<EOF
$roots
EOF
    copybarista_guidance=$(cat <<'EOF'
The staged changes touch Copybarista export packages. One pre-filled
Copybarista-PR-* block per package appears inside BEGIN_COMMIT/END_COMMIT after the
bullets; keep every block inside the markers. Replace each <...> with public-safe
text (no private paths, SHAs, repo names, or issue links). Each package's Title/Body
MUST describe ONLY that package's changes, using the per-package file lists below.
EOF
)
    copybarista_trailers=$(_join_blocks "${trailers[@]}")
    copybarista_breakdown=$(_join_blocks "${breakdowns[@]}")
else
    copybarista_guidance=""
    copybarista_trailers=""
    copybarista_breakdown=""
fi

prompt=$(
    cat <<EOF
Describe the following diff.

Output a git commit message in exactly this format and nothing else:

BEGIN_COMMIT
A <60 char headline sentence capturing the overall change.

- A terse bulleted list of essential details.
- No file paths, line counts, unicode, or 'Summary'/'Overall' prefixes.
- Be concise; wordiness detracts from importance.
- Use as few bullets as possible to describe the changes.
${copybarista_trailers:+
$copybarista_trailers}
END_COMMIT
${copybarista_guidance:+
$copybarista_guidance
}${copybarista_breakdown:+
$copybarista_breakdown
}
The diff:
$diff
EOF
)

for provider in $providers; do
    err=$(mktemp -t ai-change-description.XXXXXX)
    out=$(printf '%s\n' "$prompt" | sagent --ephemeral --model utility --provider "$provider" 2>"$err")
    status=$?
    msg=$(printf '%s\n' "$out" | awk '/^BEGIN_COMMIT$/{flag=1; next} /^END_COMMIT$/{flag=0} flag')
    case "$msg" in
        *[![:space:]]*)
            rm -f "$err"
            printf '%s\n' "$msg"
            exit 0
            ;;
    esac
    printf 'ai-change-description: %s failed' "$provider" >&2
    if [ "$status" -ne 0 ]; then printf ' with exit %s' "$status" >&2; fi
    if [ -s "$err" ]; then
        printf ':\n' >&2
        sed 's/^/  /' "$err" >&2
    else
        printf ': no BEGIN_COMMIT block in output\n' >&2
    fi
    rm -f "$err"
done

echo "ai-change-description: all allowed providers failed" >&2
exit 1
