# shellcheck shell=bash

alias reload="source ~/.zshrc"
alias colors="source ~/.zshenv && source ~/.zprofile && source ~/.zshrc && update_color_scheme"

alias -- -="cd -"
alias -g ...=../..
alias -g ....=../../..
alias -g .....=../../../..
alias -g ......=../../../../..
alias _="sudo "

# Directory stack
for index in {1..9}; do
  # shellcheck disable=SC2139
  alias "${index}"="cd +${index} > /dev/null"
done
unset index

# alias ls="ls --color=auto"
# alias l="ls -lh"
# alias la="ls -lAh"
# alias ll="ls -lAhF"
# alias lls="ls -lAhFtr"
# alias lc="ls -CF"

# alias cp="cp -i"
# alias mv="mv -i"
# alias rm="rm -i"
# alias md="mkdir -p"
# alias rd="rmdir"

alias grep="grep --color"

alias cls="tput reset"

# Make the aliases for the different command implementations explicit.
alias which="whence -c"
alias type="whence -v"
alias where="whence -ca"

alias duf="du -sh * | sort -hr"

alias vi="nvim"
alias vim="nvim"

alias -g H="| head"
alias -g T="| tail"
alias -g G="| grep"
alias -g L="| less"
alias -g M="| most"
alias -g LL="2>&1 | less"
alias -g CA="2>&1 | cat -A"

alias td="tmux detach"
alias tks="tmux kill-server"
alias tls="tmux list-sessions"

# alias terraform="tofu"
# alias tf="tofu"

# terraform() {
#   if [ -f "./.env" ]; then
#     op run --env-file="./.env" -- terraform "$@"
#   else
#     terraform "$@"
#   fi
# }
#
# alias tf="terraform"
# alias terrafrom="terraform"

function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}
