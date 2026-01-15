export XDG_BIN_HOME="${HOME}/.local/bin"
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"

export CC="clang"
export CXX="clang++"

export EDITOR="nvim"
export VISUAL="nvim"

export GOPATH="${HOME}/go"

if [[ ${OSTYPE} == darwin* ]]; then
    export SSH_AUTH_SOCK="${HOME}/.bitwarden-ssh-agent.sock"
fi

export GCLOUD_SDK_DIR="${HOME}/.local/opt/google-cloud-sdk"

# "Internal" options
export PROMPT_ENABLE_GIT_DIRTY=true

# vi: ft=zsh
