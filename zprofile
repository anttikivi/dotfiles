typeset -U path PATH

if [[ ${OSTYPE} == darwin* ]] && [ -d "/opt/homebrew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

path=("${XDG_BIN_HOME}" "${path[@]}")
path=("${HOME}/.local/opt/go/bin" "${path[@]}")
path=("${HOME}/.local/opt/nvim/bin" "${path[@]}")
path=("${HOME}/.local/opt/zig/bin" "${path[@]}")
path=("${GOPATH}/bin" "${path[@]}")
path=("${XDG_CONFIG_HOME}/composer/vendor/bin" "${path[@]}")
path=("/Applications/Ghostty.app/Contents/MacOS" "${path[@]}")

if [ -e "${HOME}/.cargo/env" ]; then
    source "${HOME}/.cargo/env"
fi

export GCLOUD_SDK_DIR="${LOCAL_OPT_DIR}/google-cloud-sdk"
if [ -f "${GCLOUD_SDK_DIR}/path.zsh.inc" ]; then
  source "${GCLOUD_SDK_DIR}/path.zsh.inc"
fi

# vi: ft=zsh
