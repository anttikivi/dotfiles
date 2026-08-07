.POSIX:
.SUFFIXES:

JJ_VERSION = 0.40.0
VIM_CLASSIC_VERSION = 8.3.0
NVIM_VERSION = 0.12.2
ZIG_VERSION = 0.16.0
ZIG_ARCHIVE = zig-aarch64-macos-$(ZIG_VERSION).tar.xz
ZIG_PUBLIC_KEY = RWSGOq2NVecA2UPNdBUZykf1CCb147pkmdtYxgb3Ti+JO/wCYvhbAb/U

all: lint

fmt: FORCE
	stylua --config-path nvim/stylua.toml nvim/

lint: FORCE
	stylua --check --config-path nvim/stylua.toml nvim/
	selene --config nvim/selene.toml .

install-vim: FORCE
	if [ ! -d "${HOME}/build" ]; then mkdir "${HOME}/build"; fi
	if [ -d "${HOME}/build/vim" ]; then rm -rf "${HOME}/build/vim"; fi
	git clone https://git.sr.ht/~sircmpwn/vim-classic "${HOME}/build/vim"
	git -C "${HOME}/build/vim" checkout "tags/v$(VIM_CLASSIC_VERSION)"
	git -C "${HOME}/build/vim" apply "$$(pwd)/vim/patches/netrw-preserve-registers.patch"
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

# TODO: Temporary task for installing jj.
install-jj: FORCE
	if [ -n "$$(jj --version)" ] && [ "$$(jj --version | xargs -n1 echo | tail -1)" != "$(JJ_VERSION)" ]; then cargo uninstall jj jj-cli; fi
	cargo install --version "$(JJ_VERSION)" --locked --bin jj jj-cli

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
