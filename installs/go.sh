#!/bin/sh

set -e

not_supported() {
  echo "This system is not supported: $*" >&2
  exit 1
}

. ../versions.sh
. ../utils/colors.sh

if [ "${HAS_CONNECTION}" = "true" ]; then
  minor_ver="$(echo "${GO_VERSION}" | head -c "$(echo "${GO_VERSION}" | grep -m 2 -ob "\." | tail -1 | grep -oE "[0-9]+")")"
  wanted_ver="$(curl -LsS 'https://go.dev/dl/?mode=json&include=all' | jq -r '.[] | .version' | grep "${minor_ver}" | sort -V | tail -1)"
  # TODO: Some values of `uname -m` might need to be changed.
  current_ver="$(go version | sed "s/go version //" | sed "s: $(uname | tr '[:upper:]' '[:lower:]')/$(uname -m)::")"

  install_go() {
    echo "Removing old Go installation"
    rm -rf "${HOME}/.local/opt/go"

    echo "Downloading Go"
    archive_name="$(curl -LsS 'https://go.dev/dl/?mode=json&include=all' | jq -r --arg "wanted_version" "${wanted_ver}" --arg "os" "$(uname | tr '[:upper:]' '[:lower:]')" --arg "arch" "$(uname -m)" '.[] | select(.version == $wanted_version) | .files[] | select(.os == $os and .arch == $arch and .kind == "archive") | .filename')"
    curl -LsS "https://go.dev/dl/${archive_name}" | tar -C "${HOME}/.local/opt" -xzf -
  }

  if ! command -v go >/dev/null 2>&1; then
    install_go
  elif [ "${wanted_ver}" != "${current_ver}" ]; then
    install_go
    if [ "${DO_UPDATES}" = "true" ]; then
      install_go
    else
      printf "%bGo update available! Current version: %s, available version: %s%b" "${ESC_YELLOW}" "${current_ver}" "${wanted_ver}" "${ESC_RESET}"
    fi
  else
    echo "Not installing Go"
  fi

  echo "Installing Go modules"

  go install mvdan.cc/sh/v3/cmd/shfmt@latest
  go install github.com/a-h/templ/cmd/templ@latest
fi