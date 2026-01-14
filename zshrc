# The Zsh options for reference:
# https://zsh.sourceforge.io/Doc/Release/Options.html
setopt AUTO_CD
setopt AUTO_PUSHD

unsetopt MENU_COMPLETE
setopt AUTO_MENU

setopt BAD_PATTERN
setopt EXTENDED_GLOB

setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_SPACE

# Credits to https://gist.github.com/ctechols/ca1035271ad134841284
local dumpfile="${XDG_CACHE_HOME:-"${HOME}/.cache"}/zsh/zcompdump-${ZSH_VERSION}"
mkdir -p -- "${dumpfile:h}"

autoload -Uz compinit
if [[ -n "${dumpfile}"(#qN.mh-24) ]]; then
    compinit -C -d "${dumpfile}"
else
    compinit -d "${dumpfile}"
fi

zstyle ':completion:*' matcher-list 'm:{[:lower:]}={[:upper:][:lower:]}' 'r:|=*' 'l:|=* r:|=*'
# NOTE: This version is truly case insensitive. However, I prefer to only match
# upper case with upper case:
# zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|=*' 'l:|=* r:|=*'

export MANPAGER="nvim +Man!"
export HISTSIZE=32768
export SAVEHIST=$HISTSIZE

eval "$(fnm env --use-on-cd --shell zsh)"
eval "$(fnm completions --shell zsh)"

if [[ -f "${GCLOUD_SDK_DIR}/completion.zsh.inc" ]]; then
    source "${GCLOUD_SDK_DIR}/completion.zsh.inc"
fi

if [[ ${OSTYPE} == darwin* ]] && [[ ! -S "${SSH_AUTH_SOCK}" ]]; then
    print -u2 -- "warning: SSH agent socket missing at ${SSH_AUTH_SOCK}"
fi

option_files=("keybindings" "prompt")
for filename in "${option_files[@]}"; do
    file="${HOME}/src/personal/dotfiles/zsh/${filename}.zsh"
    if [[ -f "${file}" ]]; then
        source "${file}"
    else
        print -u2 -- "warning: Zsh option file at \"${file}\" does not exist"
    fi
done
unset file filename option_files

option_files=("alias")
for filename in "${option_files[@]}"; do
    file="${HOME}/src/personal/dotfiles/sh/${filename}.sh"
    if [[ -f "${file}" ]]; then
        source "${file}"
    else
        print -u2 -- "warning: sh option file at \"${file}\" does not exist"
    fi
done
unset file filename option_files

# vi: ft=zsh
