#!/bin/sh

set -e

not_supported() {
  echo "This system is not supported: $*" >&2
  exit 1
}

os_name="$(uname)"

if [ "${os_name}" = "Darwin" ]; then
  echo "Running on Darwin"

  echo "Installing general utilities"

  brew update
  brew install fzf jq ripgrep tmux reattach-to-user-namespace

  echo "Installing user interface utilities"

  brew install cormacrelf/tap/dark-notify
  brew install --cask nikitabobko/tap/aerospace

  echo "Installing tools"

  pipx install ansible-lint

  if ! command -v aws >/dev/null 2>&1; then
    tmp_dir="$(mktemp -d "aws_cli")"
    pkg_file="${tmp_dir}/AWSCLIV2.pkg"
    curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "${pkg_file}"
    installer -pkg "${pkg_file}" -target CurrentUserHomeDirectory -applyChoiceChangesXML ./templates/aws_cli_choices.xml
    ln -s ~/.local/opt/aws-cli/aws ~/.local/bin/aws
    ln -s ~/.local/opt/aws-cli/aws_completer ~/.local/bin/aws_completer
    rm -r "${tmp_dir}"
  fi
elif [ "${os_name}" = "Linux" ]; then
  echo "Checking the Linux distribution..."
  distro="$(cat /etc/*-release | grep ^ID | head -n1 | cut -d '=' -f2)"
  echo "Running on ${distro}"

  if [ "${distro}" = "debian" ]; then
    not_supported "${os_name}" "${distro}"
  elif [ "${distro}" = "ubuntu" ]; then
    not_supported "${os_name}" "${distro}"
  else
    not_supported "${os_name}" "${distro}"
  fi
else
  not_supported "${os_name}"
fi
