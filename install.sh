#!/bin/bash

# Note: ubuntu defaults are:
# /etc/skel/{.bash_logout,.bashrc,.profile}

RCDIR="$PWD"
for f in ".bash_aliases" ".bashrc" ".gitconfig" ".inputrc" ".pystartup" ".screenrc" ".tmux.conf" ".vimrc" ; do
    ln -sf $RCDIR/$f ~/$f
done
mkdir -p ~/.config/nvim        && ln -sf $RCDIR/nvim_init.vim ~/.config/nvim/init.vim
mkdir -p ~/.local/bin          && ln -sf $RCDIR/bc            ~/.local/bin/bc   && chmod 0744 ~/.local/bin/bc
mkdir -p ~/.local/bin          && ln -sf $RCDIR/uvr           ~/.local/bin/uvr  && chmod 0744 ~/.local/bin/uvr

