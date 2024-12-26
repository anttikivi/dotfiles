import os
import sys
import tomllib
from typing import Any, cast

from etc.command import BaseCommand, BootstrapCommand, InstallCommand
from etc.config import Config, Platform, SubcommandOptions
from etc.exceptions import UnsupportedPlatformError
from etc.shell import Shell
from etc.ui import Terminal


def main() -> int:
    try:
        platform = resolve_platform()
    except UnsupportedPlatformError as e:
        print(f"This platform is not supported: {e}", file=sys.stderr)
        return 3  # TODO: Or something

    base_cmd = BaseCommand()

    # TODO: Allow loading 'plugin' commands from configuration if the
    # environment is already bootstrapped. Maybe one solution could be
    # the following:
    # - If the configuration file is at one of a list of predefined
    #   locations (e.g. ~/.etc.toml or default_repo/etc.toml), add them
    #   as regular subcommands.
    # - If the configuration file is in a custom location, add a command
    #   that allows using custom subcommands.
    base_cmd.commands.extend([BootstrapCommand(), InstallCommand()])

    opts = base_cmd.parse_arguments(
        base_cmd.create_argument_parser(), platform
    )

    shell = Shell(
        dry_run=opts.dry_run,
        verbosity=opts.verbosity,
        print_commands=opts.print_commands,
    )
    ui = Terminal(level=opts.verbosity, shell=shell, use_colors=opts.colors)

    ui.trace(f"Command-line options parsed: {opts}")

    command_opts = opts.command_opts
    if command_opts is not None:
        if hasattr(command_opts, "base_directory"):
            command_opts = cast(SubcommandOptions, command_opts)
            ui.debug(
                (
                    f"Resolved {command_opts.base_directory} as the base "
                    "directory"
                )
            )
        if hasattr(command_opts, "config_file"):
            command_opts = cast(SubcommandOptions, command_opts)
            ui.debug(
                (
                    f"Resolved {command_opts.config_file} as the "
                    "configuration file"
                )
            )

    # TODO: Add a way to handle whether the options actually have the
    # configuration file. Right now a subcommand is required and every
    # subcommand has a required option for the configuration file.
    ui.start_task("Starting to parse the configuration file")
    command_opts = cast(SubcommandOptions, command_opts)

    shell.echo_test_not_f(command_opts.config_file)
    if not os.path.isfile(command_opts.config_file):
        ui.error(
            (
                f'The configuration file et "{command_opts.config_file}" does '
                "not exist"
            )
        )
        return 4  # TODO: Or something.

    raw_config: dict[str, Any] | None = None  # pyright: ignore[reportExplicitAny]
    try:
        with open(command_opts.config_file, "rb") as f:
            try:
                raw_config = tomllib.load(f)
            except tomllib.TOMLDecodeError as e:
                ui.error(
                    msg=(
                        "Failed to parse the configuration from file at "
                        f'"{command_opts.config_file}": {e}'
                    )
                )
                return 1  # TODO: Or something.
    except OSError as e:
        ui.error(
            msg=(
                "Failed to read the configuration file at "
                f'"{command_opts.config_file}": {e}'
            )
        )
        return cast(int, e.errno)

    ui.complete_task("The TOML configuration file parsed")
    ui.trace(f"Received the following raw configuration: {raw_config}")

    config: Config | None = None
    try:
        config = base_cmd.parse_config(raw_config, ui)
    except Exception as e:
        ui.error(f"Failed to parse the raw configuration data: {e}")
        return 1  # TODO: Or something.

    ui.trace(f"The configuration was parsed, received:\n{config}")

    # TODO: Determine some constant values for the exit codes.
    return base_cmd(config=config, opts=opts, shell=shell, ui=ui)


def resolve_platform() -> Platform:
    if sys.platform.lower() == "darwin":
        return "darwin"
    raise UnsupportedPlatformError(
        f'the platform "{sys.platform}" is not supported'
    )
