import os
import tomllib
import typing

from etc.command import BaseCommand, BootstrapCommand, InstallCommand
from etc.config import Config, Options
from etc.shell import Shell
from etc.ui import Terminal


def main() -> int:
    # TODO: Maybe check here if the platform is supported?

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

    opts = Options.parse(base_cmd.create_argument_parser().parse_args())

    shell = Shell(
        dry_run=opts.dry_run,
        verbosity=opts.verbosity,
        print_commands=opts.print_commands,
    )
    ui = Terminal(
        level=opts.verbosity, shell=shell, use_colors=opts.use_colors
    )

    ui.debug(f"Resolved {opts.base_directory} as the base directory")
    ui.debug(f"Resolved {opts.config_file} as the configuration file")

    ui.start_task("Starting to parse the configuration file")
    assert (
        opts.config_file is not None
    ), "the configuration file passed to the install suite is None"

    shell.echo_test_not_f(opts.config_file)
    if not os.path.isfile(opts.config_file):
        ui.error(
            (
                f'The configuration file et "{opts.config_file}" does not '
                "exist"
            )
        )
        return 4  # TODO: Or something.

    config: Config | None = None
    try:
        with open(opts.config_file, "rb") as f:
            try:
                config = typing.cast(
                    Config, typing.cast(object, tomllib.load(f))
                )
            except tomllib.TOMLDecodeError as e:
                ui.error(
                    msg=(
                        "Failed to parse the configuration from file at "
                        f'"{opts.config_file}": {e}'
                    )
                )
                return 1  # TODO: Or something.
    except OSError as e:
        ui.error(
            msg=(
                "Failed to read the configuration file at "
                f'"{opts.config_file}": {e}'
            )
        )
        return typing.cast(int, e.errno)

    ui.complete_task("Configuration file parsed")
    ui.trace(f"Received the following configuration: {config}")

    # TODO: Determine some constant values for the exit codes.
    return base_cmd(config=config, opts=opts, shell=shell, ui=ui)
