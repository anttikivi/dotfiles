autoload -Uz add-zsh-hook colors vcs_info
colors

zstyle ':vcs_info:git:*' formats '%F{cyan}(%b)%f'
zstyle ':vcs_info:*' enable git

_update_vcs_info() {
    vcs_info
}

add-zsh-hook precmd _update_vcs_info
add-zsh-hook chpwd _update_vcs_info

if [[ -n ${SSH_CONNECTION}${SSH_CLIENT}${SSH_TTY} ]]; then
    PROMPT_HOST='%F{blue}%n@%m%f '
else
    PROMPT_HOST=''
fi

setopt PROMPT_SUBST

PROMPT='
${PROMPT_HOST}%~ ${vcs_info_msg_0_}
%(?.%F{magenta}.%F{red})%#%f '
