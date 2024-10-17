# shellcheck disable=SC2034
CATPPUCCIN="catppuccin"
CATPPUCCIN_FRAPPE="frappe"
CATPPUCCIN_MACCHIATO="macchiato"
CATPPUCCIN_MOCHA="mocha"
CATPPUCCIN_LATTE="latte"

NIGHTFOX="nightfox"
DAYFOX="dayfox"
DAWNFOX="dawnfox"
DUSKFOX="duskfox"
NORDFOX="nordfox"
TERAFOX="terafox"
CARBONFOX="carbonfox"

ROSE_PINE="rose-pine"
ROSE_PINE_MAIN="main"
ROSE_PINE_MOON="moon"
ROSE_PINE_DAWN="dawn"
KITTY_ROSE_PINE="Rosé Pine"

export TOKYONIGHT="tokyonight"
TOKYONIGHT_DAY="day"
TOKYONIGHT_MOON="moon"
TOKYONIGHT_NIGHT="night"
TOKYONIGHT_STORM="storm"
KITTY_TOKYONIGHT="Tokyo Night"

capitalize() {
  if [ -z "$1" ]; then
    echo "No string passed to the function to capitalize!" >&2
    exit 1
  fi
  echo "$(echo "$1" | cut -c -1 | tr '[:lower:]' '[:upper:]')$(echo "$1" | cut -c 2-)"
}

export COLOR_SCHEME="${NIGHTFOX}"

case "${COLOR_SCHEME}" in
  "${CATPPUCCIN}")
    COLOR_SCHEME_DARK_VARIANT="${CATPPUCCIN_MACCHIATO}"
    COLOR_SCHEME_LIGHT_VARIANT="${CATPPUCCIN_LATTE}"
    DARK_COLOR_SCHEME="${COLOR_SCHEME}-${COLOR_SCHEME_DARK_VARIANT}"
    LIGHT_COLOR_SCHEME="${COLOR_SCHEME}-${COLOR_SCHEME_LIGHT_VARIANT}"
    KITTY_DARK_COLOR_SCHEME="$(capitalize "${COLOR_SCHEME}")-$(capitalize "${COLOR_SCHEME_DARK_VARIANT}")"
    KITTY_LIGHT_COLOR_SCHEME="$(capitalize "${COLOR_SCHEME}")-$(capitalize "${COLOR_SCHEME_LIGHT_VARIANT}")"
    ;;
  "${NIGHTFOX}")
    COLOR_SCHEME_DARK_VARIANT="${NIGHTFOX}"
    COLOR_SCHEME_LIGHT_VARIANT="${DAYFOX}"
    DARK_COLOR_SCHEME="${COLOR_SCHEME_DARK_VARIANT}"
    LIGHT_COLOR_SCHEME="${COLOR_SCHEME_LIGHT_VARIANT}"
    KITTY_DARK_COLOR_SCHEME="$(capitalize "${COLOR_SCHEME_DARK_VARIANT}")"
    KITTY_LIGHT_COLOR_SCHEME="$(capitalize "${COLOR_SCHEME_LIGHT_VARIANT}")"
    ;;
  "${ROSE_PINE}")
    COLOR_SCHEME_DARK_VARIANT="${ROSE_PINE_MAIN}"
    COLOR_SCHEME_LIGHT_VARIANT="${ROSE_PINE_DAWN}"
    DARK_COLOR_SCHEME="${COLOR_SCHEME}"
    LIGHT_COLOR_SCHEME="${COLOR_SCHEME}-${COLOR_SCHEME_LIGHT_VARIANT}"
    KITTY_DARK_COLOR_SCHEME="${KITTY_ROSE_PINE}"
    KITTY_LIGHT_COLOR_SCHEME="${KITTY_ROSE_PINE} $(capitalize "${COLOR_SCHEME_LIGHT_VARIANT}")"
    ;;
  "${TOKYONIGHT}")
    COLOR_SCHEME_DARK_VARIANT="${TOKYONIGHT_STORM}"
    COLOR_SCHEME_LIGHT_VARIANT="${TOKYONIGHT_DAY}"
    DARK_COLOR_SCHEME="${COLOR_SCHEME}-${COLOR_SCHEME_DARK_VARIANT}"
    LIGHT_COLOR_SCHEME="${COLOR_SCHEME}-${COLOR_SCHEME_LIGHT_VARIANT}"
    KITTY_DARK_COLOR_SCHEME="${KITTY_TOKYONIGHT} $(capitalize "${COLOR_SCHEME_DARK_VARIANT}")"
    KITTY_LIGHT_COLOR_SCHEME="${KITTY_TOKYONIGHT} $(capitalize "${COLOR_SCHEME_LIGHT_VARIANT}")"
    ;;
  *)
    echo "Invalid color scheme: ${COLOR_SCHEME}" >&2
    ;;
esac

export COLOR_SCHEME_DARK_VARIANT
export COLOR_SCHEME_LIGHT_VARIANT
export DARK_COLOR_SCHEME
export LIGHT_COLOR_SCHEME
export KITTY_DARK_COLOR_SCHEME
export KITTY_LIGHT_COLOR_SCHEME
