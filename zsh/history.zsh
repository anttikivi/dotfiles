# shellcheck shell=bash

setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt SHARE_HISTORY

HISTFILE="${HOME}/.zsh_history"
HISTSIZE=8192
# shellcheck disable=SC2034
SAVEHIST=8192

export LESSHISTFILE="${XDG_STATE_HOME}/less/history"
