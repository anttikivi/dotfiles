#!/bin/sh

set -e

if [ "${HAS_CONNECTION}" = "true" ]; then
  if ! command -v composer >/dev/null 2>&1; then
    cd ~/tmp
    echo "Installing Composer"
    EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

    if [ "${EXPECTED_CHECKSUM}" != "${ACTUAL_CHECKSUM}" ]; then
      >&2 echo 'ERROR: Invalid installer checksum'
      rm composer-setup.php
      exit 1
    fi

    php composer-setup.php --quiet --install-dir="${HOME}/.local/bin" --filename="composer"
    echo "The Composer installation result was $?"
    rm composer-setup.php
    cd - >/dev/null
  elif [ "${DO_UPDATES}" = "true" ]; then
    echo "Updating Composer is not currently supported"
    # TODO
  else
    echo "Not installing Composer"
  fi
fi
