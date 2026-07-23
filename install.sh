#!/bin/bash

# Note: ubuntu defaults are:
# /etc/skel/{.bash_logout,.bashrc,.profile}

RCDIR="$PWD"

# Symlink src -> dst, creating parent dirs. Never overwrite: if dst already
# exists (as a real file/dir, or ANY symlink) it is left untouched and the
# reason is reported, including where a differing symlink currently points.
# Optional 3rd arg = mode to chmod onto a freshly created link's target.
safelink() {
    local src="$1" dst="$2" mode="$3"
    mkdir -p "$(dirname "$dst")"
    if [ -L "$dst" ]; then
        local cur; cur="$(readlink "$dst")"
        if [ "$cur" = "$src" ]; then
            echo "ok   (already linked):            $dst"
        else
            echo "skip (symlink -> other target):   $dst -> $cur  (wanted $src)"
        fi
        return
    fi
    if [ -e "$dst" ]; then
        echo "skip (exists as real file/dir):   $dst"
        return
    fi
    ln -s "$src" "$dst"
    [ -n "$mode" ] && chmod "$mode" "$dst"
    echo "link (created):                   $dst -> $src"
}

# Home-directory dotfiles.
for f in ".bash_aliases" ".bashrc" ".gitconfig" ".inputrc" ".pystartup" ".screenrc" ".tmux.conf" ".vimrc" ; do
    safelink "$RCDIR/$f" "$HOME/$f"
done

# Each .vim runtime file individually (not the whole dir) so vim/plugins can
# drop files into ~/.vim without polluting this repo, and vice-versa.
while IFS= read -r f; do
    safelink "$RCDIR/.vim/$f" "$HOME/.vim/$f"
done < <(cd "$RCDIR/.vim" && find . -type f | sed 's|^\./||')

safelink "$RCDIR/nvim_init.vim"           "$HOME/.config/nvim/init.vim"
safelink "$RCDIR/bc"                       "$HOME/.local/bin/bc"                     0744
safelink "$RCDIR/uvr"                      "$HOME/.local/bin/uvr"                    0744
# `git ais` shells out to this by bare name, so it must be on PATH.
safelink "$RCDIR/ai-change-description.sh" "$HOME/.local/bin/ai-change-description.sh" 0755
