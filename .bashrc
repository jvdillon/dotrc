# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# # If not running interactively, don't do anything
# case $- in
#     *i*) ;;
#       *) return;;
# esac

# Expand aliases even non-interactively so `ssh host ll` works (off by
# default for `ssh host cmd`; harmless no-op in interactive shells).
shopt -s expand_aliases

# Interactive-only: history, prompt, lesspipe, window-title, completion.
# Cosmetic/stateful and pointless (or wasteful) for `ssh host cmd`; the
# stock guard's `return` is replaced by gating just this block on $-.
case $- in *i*)

# don't put duplicate lines or lines starting with space in the history.
# ... or force ignoredups and ignorespace
# See bash(1) for more options
HISTCONTROL=ignoredups:ignorespace:erasedups

# append to the history file, don't overwrite it
shopt -s histappend

# HISTFILESIZE : Max number of lines contained in the history file.
# HISTSIZE     : Number of commands to remember in the command history.
HISTSIZE=100000
HISTFILESIZE=200000
# -a: append this session's new history to ~/.bash_history
# -n: read in new entries other sessions have appended since last check
PROMPT_COMMAND="history -a; history -n; ${PROMPT_COMMAND}"

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# https://stackoverflow.com/questions/15883416/adding-git-branch-on-the-bash-command-prompt
if [ "$color_prompt" = yes ]; then
    # PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
    # PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\033[0;32m$(__git_ps1 " (%s)")\033[0m\$ '
    # PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\033[0;32m$(__git_ps1 "(%s)")\033[0m\[\033[01;34m\]\w\[\033[00m\]\$ '
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;33m\]$(__git_ps1 "[%s]")\[\033[00m\]\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    # PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
    # PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w$(__git_ps1 " (%s)")\$ '
    # PS1='${debian_chroot:+($debian_chroot)}\u@\h:$(__git_ps1 "(%s)")\w\$ '
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:$(__git_ps1 "[%s]")\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

;; esac  # end interactive-only block

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls -h --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Fix scaling on HiDPI monitors.
export _JAVA_OPTIONS="-Dsun.java2d.uiScale.enabled=true -Dsun.java2d.uiScale=2.0"

# Speed up GTK4 over X11 forwarding by disabling D-Bus session bus.
if [ -n "$SSH_CONNECTION" ]; then
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/dev/null"
    export GDK_BACKEND=x11
    export NO_AT_BRIDGE=1
    export GTK_MODULES=""
fi

export TORCH_HOME=/opt/scratch/models/torch
export PYTORCH_ALLOC_CONF="expandable_segments:True"
export PYTORCH_CUDA_ALLOC_CONF="expandable_segments:True"

# sudo update-alternatives --config cuda
export CUDA_HOME=/usr/local/cuda
if [ -d "$CUDA_HOME" ]; then
    export PATH="${CUDA_HOME}/bin:/usr/src/tensorrt/bin${PATH:+:${PATH}}"
    export LD_LIBRARY_PATH="${CUDA_HOME}/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
fi
unset CUDA_HOME

export ROCM_HOME=/opt/rocm
if [ -d "$ROCM_HOME" ]; then
    export PATH="${ROCM_HOME}/bin${PATH:+:${PATH}}"
    export LD_LIBRARY_PATH="${ROCM_HOME}/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
fi
unset ROCM_HOME

if [ -d "$HOME/.npm-global/bin" ]; then
    export PATH="$HOME/.npm-global/bin${PATH:+:${PATH}}"
fi

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

[ -f ~/.secrets ] && . ~/.secrets
