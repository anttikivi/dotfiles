typeset -U path PATH

if [[ ${OSTYPE} == darwin* && -d /opt/homebrew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

path=(
    "${XDG_BIN_HOME}"
    "${HOME}/.cargo/bin"
    "${GOPATH}/bin"
    "${XDG_CONFIG_HOME}/composer/vendor/bin"
    $path
)

optionals=("go" "nvim" "zig" "zlint")
for opt in "${optionals[@]}"; do
    path=("${HOME}/.local/opt/${opt}/bin" $path)
done
unset opt optionals

if [[ ${OSTYPE} == darwin* ]]; then
    path+=("/Applications/Ghostty.app/Contents/MacOS")
fi

if [[ -d "${GCLOUD_SDK_DIR}/bin" ]]; then
    path+=("${GCLOUD_SDK_DIR}/bin")
fi

# vi: ft=zsh
