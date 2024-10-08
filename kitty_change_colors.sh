#!/bin/sh

set -e

. ~/.config/env/color_scheme.sh

color_scheme="${KITTY_LIGHT_COLOR_SCHEME}"

if [ "$1" = "dark" ]; then
  color_scheme="${KITTY_DARK_COLOR_SCHEME}"
fi

echo "Changing to the $1 color scheme: ${color_scheme}"

~/.local/bin/kitten themes --reload-in all "${color_scheme}"
