typeset -U path PATH

if [[ ${OSTYPE} == darwin* && -d /opt/homebrew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

path=(
    "${XDG_BIN_HOME}"
    "${HOME}/.local/opt/go/bin"
    "${HOME}/.local/opt/nvim/bin"
    "${HOME}/.local/opt/zig/bin"
    "${HOME}/.cargo/bin"
    "${GOPATH}/bin"
    "${XDG_CONFIG_HOME}/composer/vendor/bin"
    $path
)

if [[ ${OSTYPE} == darwin* ]]; then
    path+=("/Applications/Ghostty.app/Contents/MacOS")
fi

if [[ -d "${GCLOUD_SDK_DIR}/bin" ]]; then
    path+=("${GCLOUD_SDK_DIR}/bin")
fi

# vi: ft=zsh
