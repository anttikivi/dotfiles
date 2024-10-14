# shellcheck source=../../.zshenv
source ~/.zshenv

pathmunge() {
  if ! echo "${PATH}" | grep -Eq "(^|:)$1($|:)"; then
    if [ "$2" = "after" ]; then
      PATH=$PATH:$1
    else
      PATH=$1:$PATH
    fi
  fi
}

# TODO: It might be that `PATH` should be set in `.zshrc` on Linux.
if [ -d "/opt/homebrew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

pathmunge "${HOME}/.local/bin"
pathmunge "$(brew --prefix python)/libexec/bin"
pathmunge "/usr/local/go/bin"
pathmunge "${GOBIN}"
pathmunge "${HOME}/.local/opt/nvim/bin"

if [ -e "${HOME}/.cargo/env" ]; then
  # shellcheck source=../../.cargo/env
  source "${HOME}/.cargo/env"
fi

NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
export NVM_DIR
# shellcheck source=../../.config/nvm/nvm.sh
[ -s "${NVM_DIR}/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh"

if [ -f "${HOME}/.local/opt/google-cloud-sdk/path.zsh.inc" ]; then
  # shellcheck source=../../.local/opt/google-cloud-sdk/path.zsh.inc
  source "${HOME}/.local/opt/google-cloud-sdk/path.zsh.inc"
fi

PYTHONPATH="$(brew --prefix)/lib/python$(python --version | awk '{print $2}' | cut -d '.' -f 1,2)/site-packages"
export PYTHONPATH
# vi: ft=sh
