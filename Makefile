.POSIX:
.SUFFIXES:

all: lint

fmt: FORCE
	stylua --config-path nvim/stylua.toml nvim/

lint: FORCE
	stylua --check --config-path nvim/stylua.toml nvim/
	selene --config nvim/selene.toml .

FORCE: ;
