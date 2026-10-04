.POSIX:
.SUFFIXES:

VIM_CLASSIC_VERSION = 8.3.0
NVIM_VERSION = 0.12.2
SUPERHTML_VERSION = 0.7.0
ZIG_VERSION = 0.16.0
ZIG_ARCHIVE = zig-aarch64-macos-$(ZIG_VERSION).tar.xz
ZIG_PUBLIC_KEY = RWSGOq2NVecA2UPNdBUZykf1CCb147pkmdtYxgb3Ti+JO/wCYvhbAb/U
Z_TAG = 1.12
ZIGGY_VERSION = 0.2.0
ZINE_VERSION = 0.13.0

all: lint

fmt: FORCE
	stylua --config-path nvim/stylua.toml nvim/

lint: FORCE
	stylua --check --config-path nvim/stylua.toml nvim/
	selene --config nvim/selene.toml .

install-screenrc: FORCE
	ln -sf "$$(pwd)/screenrc" "${HOME}/.screenrc"

install-vim: FORCE
	if [ ! -d "${HOME}/build" ]; then mkdir "${HOME}/build"; fi
	if [ -d "${HOME}/build/vim" ]; then rm -rf "${HOME}/build/vim"; fi
	git clone https://git.sr.ht/~sircmpwn/vim-classic "${HOME}/build/vim"
	git -C "${HOME}/build/vim" checkout "tags/v$(VIM_CLASSIC_VERSION)"
	git -C "${HOME}/build/vim" apply --unidiff-zero "$$(pwd)/vim/patches/netrw-preserve-registers.patch"
	cd "${HOME}/build/vim/src" && ./configure --prefix="${HOME}/.local/opt/vim"
	cd "${HOME}/build/vim/src" && make
	cd "${HOME}/build/vim/src" && make test
	rm -rf "${HOME}/.local/opt/vim"
	cd "${HOME}/build/vim/src" && make install

# TODO: Temporary task for installing the latest development version.
install-nvim: FORCE
	if [ ! -d "${HOME}/build" ]; then mkdir "${HOME}/build"; fi
	if [ -d "${HOME}/build/neovim" ]; then rm -rf "${HOME}/build/neovim"; fi
	git clone git@github.com:neovim/neovim.git "${HOME}/build/neovim"
	git -C "${HOME}/build/neovim" checkout "tags/v$(NVIM_VERSION)"
	rm -rf "${HOME}/.local/opt/nvim"
	cd "${HOME}/build/neovim" && make CMAKE_BUILD_TYPE=Release CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=${HOME}/.local/opt/nvim"
	cd "${HOME}/build/neovim" && make install

install-z: FORCE
	if [ ! -d "${HOME}/build" ]; then mkdir "${HOME}/build"; fi
	if [ -d "${HOME}/build/z" ]; then rm -rf "${HOME}/build/z"; fi
	git clone git@github.com:rupa/z.git "${HOME}/build/z"
	git -C "${HOME}/build/z" checkout "tags/v$(Z_TAG)"
	rm -rf "${HOME}/.local/opt/z"
	mv "${HOME}/build/z" "${HOME}/.local/opt/z"
	rm -rf "${HOME}/.local/opt/z/.git"

# TODO: Temporary task for installing the latest development version.
install-zig: FORCE
	if [ ! -d "${HOME}/build" ]; then mkdir "${HOME}/build"; fi
	if [ -d "${HOME}/build/zig" ]; then rm -rf "${HOME}/build/zig"; fi
	mkdir "${HOME}/build/zig"
	curl -fsSLo "${HOME}/build/zig/$(ZIG_ARCHIVE)" "https://ziglang.org/builds/$(ZIG_ARCHIVE)"
	curl -fsSLo "${HOME}/build/zig/$(ZIG_ARCHIVE).minisig" "https://ziglang.org/builds/$(ZIG_ARCHIVE).minisig"
	minisign -Vm "${HOME}/build/zig/$(ZIG_ARCHIVE)" -x "${HOME}/build/zig/$(ZIG_ARCHIVE).minisig" -P "$(ZIG_PUBLIC_KEY)"
	rm -rf "${HOME}/.local/opt/zig"
	mkdir -p "${HOME}/.local/opt"
	tar -C "${HOME}/build" -xf "${HOME}/build/zig/$(ZIG_ARCHIVE)"
	mv "${HOME}/build/zig-aarch64-macos-$(ZIG_VERSION)" "${HOME}/.local/opt/zig"

# Installs the related tools, too!
install-zine: FORCE
	if [ ! -d "${HOME}/build" ]; then mkdir "${HOME}/build"; fi
	if [ -d "${HOME}/build/superhtml" ]; then rm -rf "${HOME}/build/superhtml"; fi
	mkdir -p "${HOME}/build/superhtml"
	curl -fsSLo "${HOME}/build/superhtml/superhtml.zip" "https://github.com/kristoff-it/superhtml/releases/download/v$(SUPERHTML_VERSION)/aarch64-macos.zip"
	rm -rf "${HOME}/.local/opt/superhtml"
	mkdir -p "${HOME}/.local/opt/superhtml/bin"
	unzip "${HOME}/build/superhtml/superhtml.zip" -d "${HOME}/.local/opt/superhtml/bin"
	rm -rf "${HOME}/build/superhtml"
	if [ ! -d "${HOME}/build" ]; then mkdir "${HOME}/build"; fi
	if [ -d "${HOME}/build/ziggy" ]; then rm -rf "${HOME}/build/ziggy"; fi
	mkdir -p "${HOME}/build/ziggy"
	curl -fsSLo "${HOME}/build/ziggy/ziggy.zip" "https://github.com/kristoff-it/ziggy/releases/download/v$(ZIGGY_VERSION)/aarch64-macos.zip"
	rm -rf "${HOME}/.local/opt/ziggy"
	mkdir -p "${HOME}/.local/opt/ziggy/bin"
	unzip "${HOME}/build/ziggy/ziggy.zip" -d "${HOME}/.local/opt/ziggy/bin"
	rm -rf "${HOME}/build/ziggy"
	if [ ! -d "${HOME}/build" ]; then mkdir "${HOME}/build"; fi
	if [ -d "${HOME}/build/zine" ]; then rm -rf "${HOME}/build/zine"; fi
	mkdir -p "${HOME}/build/zine"
	curl -fsSLo "${HOME}/build/zine/zine.zip" "https://github.com/kristoff-it/zine/releases/download/v$(ZINE_VERSION)/aarch64-macos.zip"
	rm -rf "${HOME}/.local/opt/zine"
	mkdir -p "${HOME}/.local/opt/zine/bin"
	unzip "${HOME}/build/zine/zine.zip" -d "${HOME}/.local/opt/zine/bin"
	rm -rf "${HOME}/build/zine"

# TODO: Temporary task for installing the latest development version.
install-zls: FORCE
	if [ ! -d "${HOME}/build" ]; then mkdir "${HOME}/build"; fi
	if [ -d "${HOME}/build/zls" ]; then rm -rf "${HOME}/build/zls"; fi
	git clone git@github.com:zigtools/zls.git "${HOME}/build/zls"
	git -C "${HOME}/build/zls" checkout tags/0.16.0
	rm -rf "${HOME}/.local/opt/zls"
	mkdir -p "${HOME}/.local/opt/zls"
	cd "${HOME}/build/zls" && zig build -p "${HOME}/.local/opt/zls" -Doptimize=ReleaseSafe

FORCE: ;
