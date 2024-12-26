import argparse
import os
import sys
from abc import ABC, abstractmethod
from collections.abc import Mapping, MutableMapping, MutableSequence, Sequence
from typing import TYPE_CHECKING, Any, Protocol, cast, final, runtime_checkable

from etc import config
from etc.config import (
    CONFIG_PARSED_MARKER,
    BootstrapOptions,
    CommandName,
    CommandOptions,
    Config,
    Options,
    Platform,
    StepConfig,
    StepDirective,
    SubcommandOptions,
)
from etc.exceptions import InvalidConfigError
from etc.shell import MessageLevel, Shell
from etc.steps.base_step import BaseStep
from etc.steps.system_packages import SystemPackagesStep
from etc.ui import UserInterface
from etc.version import VERSION

if TYPE_CHECKING:
    from argparse import (
        _SubParsersAction,  # pyright: ignore[reportPrivateUsage]
    )


if sys.version_info >= (3, 12):
    from typing import override
else:
    from typing import Any, Callable

    _Func = Callable[..., Any]

    # Fallback for Python 3.11 and earlier.
    def override(method: _Func, /) -> _Func:  # pyright: ignore[reportUnreachable]
        return method


class Command(Protocol):
    @property
    def name(self) -> CommandName: ...

    @property
    def aliases(self) -> Sequence[CommandName]: ...

    @property
    def commands(self) -> Sequence["Command"] | None:
        """
        A sequence of child commands associated with this command.
        """
        ...


@runtime_checkable
class CallableCommand(Command, Protocol):
    def __call__(
        self, config: Config, opts: Options, shell: Shell, ui: UserInterface
    ) -> int: ...


@runtime_checkable
class RunnableCommand(Command, Protocol):
    def run(
        self, config: Config, opts: Options, shell: Shell, ui: UserInterface
    ) -> int: ...


@runtime_checkable
class CallableStepsCommand(Command, Protocol):
    def __call__(
        self,
        config: Config,
        opts: Options,
        shell: Shell,
        ui: UserInterface,
        steps: Sequence["Step"],
    ) -> int: ...


@runtime_checkable
class RunnableStepsCommand(Command, Protocol):
    def run(
        self,
        config: Config,
        opts: Options,
        shell: Shell,
        ui: UserInterface,
        steps: Sequence["Step"],
    ) -> int: ...


# TODO: Add a ConfigurableCommand that can parse configuration related
# to a command.


@runtime_checkable
class Subparser(Protocol):
    """
    Subparser is duck type for commands that implement subparsers. If a
    subcommand wants to add command-line arguments, it should do so by
    implementing this duck type.
    """

    def create_subparser(
        self, subparsers: "_SubParsersAction[argparse.ArgumentParser]"
    ) -> argparse.ArgumentParser | Sequence[argparse.ArgumentParser]:
        """
        Creates the subparser using the given subparsers action and
        returns the ArgumentParser or the ArgumentParsers created for
        the subparser. Multiple ArgumentParsers are returned if the
        command has aliases as the aliases should have the same
        arguments.
        """
        ...

    def parse_arguments(self, args: argparse.Namespace) -> CommandOptions:
        """
        Parses the command-line arguments associated with this
        subcommand from the Namespace and returns the CommandOptions for
        this subcommand.
        """
        ...


@final
class BaseCommand:
    """
    BaseCommand represents the `etc` command. It implements creating the
    argument parser for the program and holds all of the subcommands.
    """

    def __init__(self) -> None:
        self.name: str = "etc"
        self.aliases: Sequence[str] = list()
        self.commands: MutableSequence[Command] = list()

        self.steps: Sequence[Step | CallableStep | RunnableStep] | None = None

    def __call__(
        self, config: Config, opts: Options, shell: Shell, ui: UserInterface
    ) -> int:
        """
        Runs the base command or selects the correct subcommand and
        runs that.
        """
        if opts.command == "etc":
            # TODO: Run the base command.
            raise NotImplementedError("bare base command cannot be run")
        assert self.steps is not None, "the steps in the base commands is None"
        for cmd in self.commands:
            if opts.command == cmd.name or opts.command in cmd.aliases:
                if isinstance(cmd, CallableStepsCommand):
                    return cmd(config, opts, shell, ui, self.steps)
                elif isinstance(cmd, RunnableStepsCommand):
                    return cmd.run(config, opts, shell, ui, self.steps)
                elif isinstance(cmd, CallableCommand):
                    return cmd(config, opts, shell, ui)
                elif isinstance(cmd, RunnableCommand):
                    return cmd.run(config, opts, shell, ui)
        return 1

    def create_argument_parser(self) -> argparse.ArgumentParser:
        parser = argparse.ArgumentParser(
            prog=self.name,
            description=(
                "Tool for managing workstation configuration and environment"
            ),
        )
        parser = self._create_global_parser(parser)

        assert len(self.commands) > 0, (
            "subcommands for the base command is an empty list while creating "
            "the arguments parser"
        )

        # TODO: See if I can find some use for the base command. Then
        # the subcommand is no longer required.
        subparsers = parser.add_subparsers(required=True, dest="command")

        for subcommand in self.commands:
            if isinstance(subcommand, Subparser):
                # TODO: Is there a reason to save the result?
                _ = subcommand.create_subparser(subparsers)

        return parser

    def parse_arguments(
        self, parser: argparse.ArgumentParser, platform: Platform
    ) -> Options:
        args = parser.parse_args()
        assert len(self.commands) > 0, (
            "subcommands for the base command is an empty list while parsing "
            "the command-line arguments"
        )

        colors = cast(bool | None, args.colors)
        if colors is None:
            # TODO: Use a better way to determine the default value.
            colors = True

        dry_run = cast(bool, args.dry_run)

        print_commands = (
            False
            if "print_commands" not in args
            else cast(bool, args.print_commands)
        ) or dry_run

        verbosity = MessageLevel.INFO - MessageLevel(cast(int, args.verbose))

        cmd_name = cast(CommandName | None, args.command)
        if cmd_name is None:
            cmd_name = "etc"

        command: Subparser | None = None
        for cmd in self.commands:
            if isinstance(cmd, Subparser) and (
                cmd_name == cmd.name or cmd_name in cmd.aliases
            ):
                command = cmd

        cmd_opts: CommandOptions | None = None
        if command is not None and cmd_name != "etc":
            cmd_opts = command.parse_arguments(args)

        return Options(
            platform=platform,
            colors=colors,
            command=cmd_name,
            dry_run=dry_run,
            print_commands=print_commands,
            verbosity=verbosity,
            command_opts=cmd_opts,
        )

    def parse_config(self, raw: Mapping[str, Any], ui: UserInterface):  # pyright: ignore[reportExplicitAny]
        """
        Parses the configuration dictionary read from a TOML file into
        a `Config`.
        """
        ui.debug("Starting to parse the configuration")
        ui.trace(f"Received the following raw data: {raw}")

        # TODO: Root-level configuration.

        # TODO: Read and load the places for external steps here.
        self._create_steps(ui)
        assert (
            self.steps is not None
        ), "the steps created in the base command is None"

        # `steps` is a special table that is shared between multiple
        # internal commands. Therefore it is parsed by the base command
        # not delegated.
        steps: MutableMapping[str, StepConfig] = {}
        raw_steps: Sequence[MutableMapping[str, Any]] = list()  # pyright: ignore[reportExplicitAny]
        if "steps" in raw:
            if isinstance(raw["steps"], Sequence):
                for raw_step in raw["steps"]:
                    if not isinstance(raw_step, Mapping):
                        ui.error(
                            (
                                "A step configuration is not a Mapping: "
                                f"{raw_step}"
                            )
                        )
                        raise InvalidConfigError(
                            'the value of "steps" in config file is invalid'
                        )
                raw_steps = cast(
                    Sequence[MutableMapping[str, Any]],  # pyright: ignore[reportExplicitAny]
                    raw["steps"],
                )
            else:
                ui.error(
                    (
                        'Configuration file has the key "steps" but its '
                        "type is invalid; the steps configuration must be an "
                        f"array of tables, got: {raw['steps']}"
                    )
                )
                raise InvalidConfigError(
                    'the value of "steps" in config file is invalid'
                )

        # Mark each step config as not parsed. The values are later used
        # for checking that every step configuration was parsed.
        for raw_step in raw_steps:
            raw_step[CONFIG_PARSED_MARKER] = False

        order = 0
        steps_order: list[str] = []
        for raw_step in raw_steps:
            directive: StepDirective | None = None
            if "directive" in raw_step:
                directive = cast(StepDirective, raw_step["directive"])
            elif "name" in raw_step:
                directive = cast(StepDirective, raw_step["name"])
            else:
                ui.error(
                    (
                        'A step does not have either the "directive" or the '
                        f'"name" key: {raw_step}'
                    )
                )
                raise InvalidConfigError('step without "directive" or "name"')

            for step in self.steps:
                if step.can_run(directive) and isinstance(
                    step, ConfigurableStep
                ):
                    parsed: StepConfig | None = None
                    try:
                        parsed = step.parse_config(raw_step, ui, order)
                    except Exception as e:
                        ui.error(
                            (
                                "Failed to parse the configuration for step "
                                f'"{directive}": {e}'
                            )
                        )
                        raise InvalidConfigError(
                            f"failed to parse step configuration: {e}"
                        )
                    name = BaseStep.get_step_name(step.directive, order)
                    steps[name] = parsed
                    steps_order.append(name)
                    raw_step[CONFIG_PARSED_MARKER] = True
                    order += 1

        unparsed: list[Mapping[str, Any]] = []  # pyright: ignore[reportExplicitAny]
        for raw_step in raw_steps:
            if CONFIG_PARSED_MARKER not in raw_step:
                ui.error(
                    (
                        'A step configuration without the "parsed marker" '
                        f"was found: {raw_step}"
                    )
                )
                raise RuntimeError
            if not raw_step[CONFIG_PARSED_MARKER]:
                unparsed.append(raw_step)

        if len(unparsed) > 0:
            if len(unparsed) == 1:
                ui.warning("Configuration for a step was not parsed:")
            else:
                ui.warning("Configurations for some steps were not parsed:")
            for s in unparsed:
                ui.warning(f"{s}")

        config: Config = Config(steps=steps, steps_order=steps_order)

        ui.trace(f"The configuration was parsed to:\n{config}")

        return config

    def _create_global_parser(
        self, parser: argparse.ArgumentParser
    ) -> argparse.ArgumentParser:
        # TODO: Add these to the subcommands with different destinations
        # so that they don't need to be invoked before specifying the
        # subcommand. Maybe implement this by accepting a prefix or
        # suffix to add to the destinations for the options in
        # subcommands.
        _ = parser.add_argument(
            "--colors",
            action=argparse.BooleanOptionalAction,
            help=(
                "Explicitly enable or disable colors in the program's output. "
                "The default value is determined automatically."
            ),
        )
        _ = parser.add_argument(
            "-n",
            "--dry-run",
            action="store_true",
            help=(
                "Show what would have been done instead of executing the commands."
            ),
        )
        _ = parser.add_argument(
            "--print-commands",
            action="store_true",
            help=(
                "Show commands before running them. Always true when the program "
                "is invoked as a dry run."
            ),
        )
        _ = parser.add_argument(
            "-v",
            "--verbose",
            action="count",
            default=0,
            help=(
                "Print more verbose output, can be passed twice to increase the "
                "verbosity."
            ),
        )
        _ = parser.add_argument(
            "--version", action="version", version=f"%(prog)s {VERSION}"
        )

        return parser

    # TODO: Should this function return something the steps were not
    # created successfully?
    # TODO: Accept configuration for loading external plugins as steps.
    def _create_steps(self, ui: UserInterface) -> None:
        ui.start_step("Creating steps")
        # TODO: Allow defining steps as plugins.
        self.steps = [SystemPackagesStep()]
        ui.complete_step("Steps created")


class Subcommand(ABC):
    """
    Subcommand is a helper base class for the subcommands of the
    program. It implements common functionality shared between the
    internal subcommands.
    """

    def __init__(
        self,
        name: str,
        aliases: Sequence[str] | None = None,
        commands: Sequence[Command] | None = None,
        help: str | None = None,
    ) -> None:
        self.name: str = name
        self.aliases: Sequence[str] = list() if aliases is None else aliases
        self.commands: Sequence[Command] | None = commands

        if help is not None:
            self.help: str | None = help

    @abstractmethod
    def __call__(
        self,
        config: Config,
        opts: Options,
        shell: Shell,
        ui: UserInterface,
        steps: Sequence["Step"],
    ) -> int: ...

    def create_subparser(
        self, subparsers: "_SubParsersAction[argparse.ArgumentParser]"
    ) -> argparse.ArgumentParser | Sequence[argparse.ArgumentParser]:
        """
        Creates the subparser for this subcommand. The most common use
        case, where the base directory and configuration file arguments
        are added, is implemented in this base class.
        """
        parsers: list[argparse.ArgumentParser] = [
            self._create_subparser_with_configuration_file(
                self.name, subparsers
            )
        ]
        for alias in self.aliases:
            parsers.append(
                self._create_subparser_with_configuration_file(
                    alias, subparsers
                )
            )

        return parsers

    def parse_arguments(self, args: argparse.Namespace) -> CommandOptions:
        base_directory, config_file = self._parse_config_file_arguments(args)
        return SubcommandOptions(base_directory, config_file)

    def _create_subparser_with_configuration_file(
        self,
        name: str,
        subparsers: "_SubParsersAction[argparse.ArgumentParser]",
    ) -> argparse.ArgumentParser:
        parser = subparsers.add_parser(name=name, help=self.help)
        _ = parser.add_argument(
            "-d",
            "--base-directory",
            action="store",
            default=config.get_default_base_directory(),
            type=str,
            help=(
                "Path to the configuration directory. If the path is an "
                "absolute path, it is used as it is. Otherwise it is "
                "resolved relative to the base directory. Environment "
                'variables are expanded and initial "~" and "~user" are '
                "resolved to user's home directory. Default: %(default)s"
            ),
        )
        _ = parser.add_argument(
            "-c",
            "--config",
            action="store",
            default=config.DEFAULT_CONFIG,
            dest="config_file",
            type=str,
            help=(
                "Path to the configuration file. If the path is an "
                "absolute path, it is used as it is. Otherwise it is "
                "resolved relative to the base directory. Environment "
                'variables are expanded and initial "~" and "~user" are '
                "resolved to user's home directory. Default: %(default)s"
            ),
        )
        return parser

    def _parse_config_file_arguments(self, args: argparse.Namespace):
        if "base_directory" not in args:
            raise ValueError(
                (
                    f"the arguments namespace passed to command {self.name} "
                    'does not contain the key "base_directory"'
                )
            )
        base_directory = os.path.expandvars(
            os.path.expanduser(cast(str, args.base_directory))
        )
        if not os.path.isabs(base_directory):
            base_directory = os.path.abspath(base_directory)

        if "config_file" not in args:
            raise ValueError(
                (
                    f"the arguments namespace passed to command {self.name} "
                    'does not contain the key "config_file"'
                )
            )
        config_file = os.path.expandvars(
            os.path.expanduser(cast(str, args.config_file))
        )
        if not os.path.isabs(config_file):
            config_file = os.path.normpath(
                os.path.join(base_directory, config_file)
            )

        return base_directory, config_file


class BootstrapCommand(Subcommand):
    help: str | None = (
        "Bootstrap the workstation configuration and environment and run the "
        "installation afterwards."
    )

    def __init__(self) -> None:
        super().__init__("bootstrap", ["init", "initialize"])

    @override
    def __call__(
        self,
        config: Config,
        opts: Options,
        shell: Shell,
        ui: UserInterface,
        steps: Sequence["Step"],
    ) -> int:
        ui.start_phase("Starting to bootstrap to configuration")

        assert isinstance(opts.command_opts, BootstrapOptions), (
            f'the command options passed to the command "{self.name}" is not '
            "an instance of bootstrap options"
        )

        base_directory = opts.command_opts.base_directory

        shell.echo_test_e(base_directory)
        if os.path.exists(base_directory):
            ui.error(f"The configuration directory at {base_directory} exists")
            ui.error("Bootstrapping must be done using a clean installation")
            return 1

        remote_repository = opts.command_opts.remote_repository

        # Check if the given remote URL is an SSH URL. If so, it needs to be
        # converted to HTTPS URL for the initial clone. It will be changed
        # back later.
        remote_url = remote_repository
        if remote_url.startswith("git@github.com:"):
            _, repo_name = remote_url.split(":")
            remote_url = f"https://github.com/{repo_name}"

        ui.start_step("Cloning the remote directory")
        ui.debug(f'Cloning from "{remote_url}" to "{base_directory}"')
        _ = shell(["git", "clone", remote_url, base_directory])
        ui.complete_step("Repository cloned")

        # TODO: Run the new install!
        install_exit_code = 0
        if install_exit_code != 0:
            ui.error(f"The install failed with the code {install_exit_code}")
            return install_exit_code

        ui.start_step("Changing the remote URL for the local repository")
        ui.trace("Checking the current remote URL for origin")
        result = shell.output(
            ["git", "-C", base_directory, "remote", "get-url", "origin"]
        )
        current_remote = result.strip()
        ui.trace(f"Got {current_remote} as the current remote URL")
        if current_remote != remote_repository:
            shell(
                [
                    "git",
                    "-C",
                    base_directory,
                    "remote",
                    "set-url",
                    "origin",
                    remote_repository,
                ]
            )
        ui.debug(
            "The remote URLs of the local repository are now set to:",
            bold=True,
        )
        shell(
            ["git", "-C", base_directory, "remote", "-v"],
            allow_output=opts.verbosity <= MessageLevel.DEBUG,
        )
        ui.debug("Fetching the remote")
        shell(["git", "-C", base_directory, "fetch"])

        ui.debug("The status of the repository now is:", bold=True)
        shell(
            ["git", "-C", base_directory, "status"],
            allow_output=opts.verbosity <= MessageLevel.DEBUG,
        )

        return 0

    @override
    def create_subparser(
        self, subparsers: "_SubParsersAction[argparse.ArgumentParser]"
    ) -> argparse.ArgumentParser | Sequence[argparse.ArgumentParser]:
        parsers = cast(
            Sequence[argparse.ArgumentParser],
            super().create_subparser(subparsers),
        )
        assert isinstance(parsers, Sequence), (
            "the return value of create_subparser from Subcommand must be a "
            "Sequence"
        )
        for parser in parsers:
            _ = parser.add_argument(
                "-r",
                "--remote",
                "--repo",
                "--repository",
                action="store",
                dest="remote_repository",
                help=(
                    "Git repository for the configuration. It will be cloned "
                    "to the base directory. If the provided URL is an SSH URL "
                    "for a Git repository in GitHub, it is converted into an "
                    "HTTP URL for cloning and changed back to the SSH one "
                    "after everything has been set up correctly."
                ),
                required=True,
            )

        return parsers

    @override
    def parse_arguments(self, args: argparse.Namespace) -> CommandOptions:
        base_directory, config_file = self._parse_config_file_arguments(args)
        if "remote_repository" not in args:
            raise ValueError(
                (
                    f"the arguments namespace passed to command {self.name} "
                    'does not contain the key "remote_repository"'
                )
            )
        remote_repo = cast(str, args.remote_repository)
        return BootstrapOptions(base_directory, config_file, remote_repo)


class InstallCommand(Subcommand):
    help: str | None = "Install the workstation configuration and environment."

    def __init__(self) -> None:
        super().__init__("install")

    @override
    def __call__(
        self,
        config: Config,
        opts: Options,
        shell: Shell,
        ui: UserInterface,
        steps: Sequence["Step"],
    ) -> int:
        ui.start_phase("Starting the install suite")

        ui.start_phase("Starting to run the install steps")

        if not config.steps or not config.steps_order:
            ui.complete_phase("No install steps to run, skipping")
            return 0
        for step_name in config.steps_order:
            ui.debug(
                (
                    "Finding runners for the current step with the name "
                    f'"{step_name}"'
                )
            )
            step_config = config.steps[step_name]
            for step in steps:
                if step.can_run(step_config.directive):
                    try:
                        ui.trace(
                            (
                                f'Calling the step "{step_name}" with the '
                                f"following configuration: {step}"
                            )
                        )
                        step_exit_code = 1  # TODO: Or something.
                        if isinstance(step, CallableStep):
                            step_exit_code = step(
                                step_name, step_config, opts, shell, ui
                            )
                        elif isinstance(step, RunnableStep):
                            step_exit_code = step.run(
                                step_name, step_config, opts, shell, ui
                            )
                        else:
                            ui.error(
                                (
                                    f'The step "{step_name}" (directive: '
                                    f"{step_config.directive}) is not a "
                                    "CallableStep or a RunnableStep"
                                )
                            )
                            return step_exit_code
                        if step_exit_code != 0:
                            ui.error(
                                (
                                    f"The execution of {step_name} returned a "
                                    f"non-zero exit code: {step_exit_code}"
                                )
                            )
                            return step_exit_code
                    except Exception as e:
                        ui.error(
                            (
                                "An error occured when executing "
                                f"{step_name}: {e}"
                            )
                        )
                        return 1  # TODO: Or something.

        ui.complete_phase("Install steps run")
        ui.complete_phase("Install suite complete")

        return 0


class Step(Protocol):
    @property
    def directive(self) -> str: ...

    @property
    def aliases(self) -> Sequence[str]: ...

    def can_run(self, directive: str) -> bool: ...


@runtime_checkable
class CallableStep(Step, Protocol):
    def __call__(
        self,
        name: str,
        config: StepConfig,
        opts: Options,
        shell: Shell,
        ui: UserInterface,
    ) -> int:
        """
        Runs the step.

        The function receives the internal name for it which can be used
        for debugging, the parsed configuration associated with this
        step, the parsed command-line arguments for the program, the
        shell utility instance, and the user interface instance.
        """
        ...


@runtime_checkable
class RunnableStep(Step, Protocol):
    def run(
        self,
        name: str,
        config: StepConfig,
        opts: Options,
        shell: Shell,
        ui: UserInterface,
    ) -> int:
        """
        Runs the step.

        The function receives the internal name for it which can be used
        for debugging, the parsed configuration associated with this
        step, the parsed command-line arguments for the program, the
        shell utility instance, and the user interface instance.
        """

        ...


@runtime_checkable
class ConfigurableStep(Protocol):
    def parse_config(
        self,
        raw: Mapping[str, Any],  # pyright: ignore[reportExplicitAny]
        ui: UserInterface,
        order: int,
    ) -> StepConfig:
        """
        Parses the configuration for this step.

        The parameter `raw` contains the data for this step read from
        the TOML configuration file. The parameter `ui` is an user
        interface instance for printing messages to the user. The
        parameter `order` is the ordinal number for this step; steps
        are run in order in the ordinal number is appended to the end of
        the step directive so will become "{directive}-{order}". The
        parameter in this function can be used to print more accurate
        messages for debugging.
        """
        ...
