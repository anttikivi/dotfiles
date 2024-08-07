.PHONY: all fmt lint

fmt:
	@printf "\nFormatting...\n"
	@printf "\nRunning Stylua...\n"
	stylua nvim/
	@printf "\nRunning Prettier...\n"
	prettier --write "**/*.{?(c)js?(on),md,yml}"
	@printf "\nRunning shfmt...\n"
	shfmt -l -w -i 2 -ci -bn .

lint:
	@printf "\nLinting...\n"
	@printf "\nRunning Luacheck...\n"
	luacheck nvim --exclude-files *.json
	@printf "\nRunning Selene...\n"
	selene .
	@printf "\nRunning shfmt...\n"
	shfmt -l -d -i 2 -ci -bn .
	@printf "\nRunning shellcheck...\n"
	shellcheck setup/install
	@printf "\nRunning Ansible Lint...\n"
	@printf "\nAnsible Lint is currently disabled...\n"
	# ansible-lint
