autoload -Uz add-zsh-hook colors vcs_info
colors

zstyle ':vcs_info:git:*' formats '%F{cyan}(%b)%f'
zstyle ':vcs_info:*' enable git

_git_dirty_check() {
    GIT_DIRTY=''

    [[ "${PROMPT_ENABLE_GIT_DIRTY}" == true ]] || return

    [[ -n ${vcs_info_msg_0_} ]] || return

    command git diff --quiet HEAD -- &>/dev/null
    if (( $? == 1 )); then
        GIT_DIRTY='%F{magenta}*%f'
        return
    fi

    command git ls-files --others --exclude-standard &>/dev/null
    if (( $? == 1 )); then
        GIT_DIRTY='%F{magenta}*%f'
    fi
}

_update_vcs_info() {
    vcs_info
}

add-zsh-hook precmd _update_vcs_info
add-zsh-hook precmd _git_dirty_check
add-zsh-hook chpwd _update_vcs_info
add-zsh-hook chpwd _git_dirty_check

if [[ -n ${SSH_CONNECTION}${SSH_CLIENT}${SSH_TTY} ]]; then
    PROMPT_HOST='%F{blue}%n@%m%f '
else
    PROMPT_HOST=''
fi

setopt PROMPT_SUBST

PROMPT='
${PROMPT_HOST}%~ ${vcs_info_msg_0_}${GIT_DIRTY}
%(?.%F{magenta}.%F{red})%#%f '
