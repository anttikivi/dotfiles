bindkey -e

autoload -U edit-command-line
zle -N edit-command-line
bindkey "^X^E" edit-command-line

bindkey "^A" beginning-of-line
bindkey "^E" end-of-line
bindkey "^K" kill-line
bindkey "^R" history-incremental-search-backward
bindkey "^P" history-search-backward
bindkey "^Y" accept-and-hold
bindkey "^N" insert-last-word

autoload -U up-line-or-beginning-search
zle -N up-line-or-beginning-search

bindkey "^[[A" up-line-or-beginning-search

autoload -U down-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey "^[[B" down-line-or-beginning-search

if [[ "${ENABLE_TMUX}" == true ]]; then
    bindkey -s "^F" "tmux-sessionizer\n"
fi
