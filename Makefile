.POSIX:
.SUFFIXES:

all: lint

fmt: FORCE
	stylua --config-path nvim/stylua.toml nvim/

lint: FORCE
	stylua --check --config-path nvim/stylua.toml nvim/
	selene --config nvim/selene.toml .

# TODO: Temporary task for installing the latest development version.
install-nvim: FORCE
	if [ ! -d "${HOME}/build" ]; then mkdir "${HOME}/build"; fi
	git clone git@github.com:neovim/neovim.git "${HOME}/build/neovim"
	rm -rf "${HOME}/.local/opt/nvim"
	cd "${HOME}/build/neovim" && make CMAKE_BUILD_TYPE=Release CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=${HOME}/.local/opt/nvim"
	cd "${HOME}/build/neovim" && make install

FORCE: ;
