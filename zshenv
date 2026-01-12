export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"

export CC="clang"
export CXX="clang++"

export EDITOR="nvim"
export VISUAL="nvim"

export GOPATH="${HOME}/go"

export PYENV_ROOT="${HOME}/.pyenv"

if [[ ${OSTYPE} == darwin* ]]; then
    export SSH_AUTH_SOCK="${HOME}/.bitwarden-ssh-agent.sock"
fi
