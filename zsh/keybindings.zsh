autoload -U up-line-or-beginning-search
zle -N up-line-or-beginning-search

bindkey "^[[A" up-line-or-beginning-search

autoload -U down-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey "^[[B" down-line-or-beginning-search

if [[ "${ENABLE_TMUX}" == true ]]; then
    bindkey -s "^F" "tmux-sessionizer\n"
fi
