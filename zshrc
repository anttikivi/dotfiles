# Credits to https://gist.github.com/ctechols/ca1035271ad134841284
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

export MANPAGER="nvim +Man!"

export HISTSIZE=32768
export SAVEHIST=$HISTSIZE

# The Zsh options for reference:
# https://zsh.sourceforge.io/Doc/Release/Options.html

setopt AUTO_CD
setopt AUTO_PUSHD
setopt BAD_PATTERN
setopt EXTENDED_GLOB
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_SPACE

bindkey -s "^F" "tmux-sessionizer\n"

eval "$(fnm env --use-on-cd --shell zsh)"
eval "$(fnm completions --shell zsh)"

alias td="tmux detach"
alias tks="tmux kill-server"
alias tls="tmux list-sessions"
alias vi="nvim"
alias vim="nvim"

if [[ -f "${GCLOUD_SDK_DIR}/completion.zsh.inc" ]]; then
    source "${GCLOUD_SDK_DIR}/completion.zsh.inc"
fi

if [[ ${OSTYPE} == darwin* ]] && [[ ! -S "${SSH_AUTH_SOCK}" ]]; then
    print -u2 -- "warning: SSH agent socket missing at ${SSH_AUTH_SOCK}"
fi

if [[ -f "${HOME}/src/personal/dotfiles/zsh/prompt.zsh" ]]; then
    source "${HOME}/src/personal/dotfiles/zsh/prompt.zsh"
fi

# vi: ft=zsh
