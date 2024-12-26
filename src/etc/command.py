import argparse
import os
import sys
from abc import ABC, abstractmethod
from collections.abc import Sequence
from typing import (
    TYPE_CHECKING,
    MutableSequence,
    Protocol,
    cast,
    final,
    runtime_checkable,
)

from etc import config
from etc.config import (
    BootstrapOptions,
    CommandName,
    CommandOptions,
    OldConfig,
    Options,
    StepConfig,
    SubcommandOptions,
)
from etc.shell import MessageLevel, Shell
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
    def __call__(
        self, config: OldConfig, opts: Options, shell: Shell, ui: UserInterface
    ) -> int: ...

    @property
    def name(self) -> str: ...

    @property
    def aliases(self) -> Sequence[str] | None: ...

    @property
    def commands(self) -> Sequence["Command"] | None:
        """
        A sequence of child commands associated with this command.
        """
        ...


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
        self.aliases: None = None
        self.commands: MutableSequence[Command] = list()

    def __call__(
        self, config: OldConfig, opts: Options, shell: Shell, ui: UserInterface
    ) -> int:
        """
        Runs the base command or selects the correct subcommand and
        runs that.
        """
        if opts.command == "etc":
            # TODO: Run the base command.
            raise NotImplementedError("bare base command cannot be run")
        for cmd in self.commands:
            if opts.command == cmd.name or (
                cmd.aliases is not None and opts.command in cmd.aliases
            ):
                return cmd(config, opts, shell, ui)
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

    def parse_arguments(self, parser: argparse.ArgumentParser) -> Options:
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
        for cmd in filter(
            lambda c: c.name
            or (c.aliases is not None and cmd_name in c.aliases),
            self.commands,
        ):
            if isinstance(cmd, Subparser):
                command = cmd

        cmd_opts: CommandOptions | None = None
        if command is not None and cmd_name != "etc":
            cmd_opts = command.parse_arguments(args)

        return Options(
            colors=colors,
            command=cmd_name,
            dry_run=dry_run,
            print_commands=print_commands,
            verbosity=verbosity,
            command_opts=cmd_opts,
        )

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
        self.aliases: Sequence[str] | None = aliases
        self.commands: Sequence[Command] | None = commands

        if help is not None:
            self.help: str | None = help

        self.steps: Sequence[Step | CallableStep | RunnableStep] | None = None

    @abstractmethod
    def __call__(
        self, config: OldConfig, opts: Options, shell: Shell, ui: UserInterface
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
        if self.aliases:
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

    # TODO: Should this function return something the steps were not
    # created successfully?
    def _create_steps(self, config: OldConfig, ui: UserInterface) -> None:  # pyright: ignore[reportUnusedParameter]
        ui.start_step("Creating steps")
        # TODO: Allow defining steps as plugins.
        self.steps = [SystemPackagesStep()]
        ui.complete_step("Steps created")

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
        self, config: OldConfig, opts: Options, shell: Shell, ui: UserInterface
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
        self, config: OldConfig, opts: Options, shell: Shell, ui: UserInterface
    ) -> int:
        ui.start_phase("Starting the install suite")

        # TODO: Maybe check the prerequisites again?
        self._create_steps(config, ui)
        assert (
            self.steps is not None
        ), "the steps required by the install command are not created"

        ui.start_phase("Starting to run the install steps")

        if "install" not in config:
            ui.warning(
                msg=(
                    'No "install" key was provided in the configuration file, '
                    "thus there are no steps to run"
                )
            )
        if "install" in config and "steps" not in config["install"]:
            ui.warning(
                msg=(
                    'No "install.steps" key was provided in the configuration '
                    "file, thus there are no steps to run"
                )
            )

        if "install" in config and "steps" in config["install"]:
            for step_config in config["install"]["steps"]:
                ui.debug(
                    (
                        "Finding runners for the current step with the "
                        f'"{step_config["directive"]}" directive'
                    )
                )
                for step in filter(
                    lambda s: s.can_run(step_config["directive"]), self.steps
                ):
                    try:
                        ui.trace(
                            (
                                f"Calling the step {step} with the "
                                "following configuration: {step}"
                            )
                        )
                        step_exit_code = 1
                        if isinstance(step, CallableStep):
                            step_exit_code = step(step_config, opts, shell, ui)
                        elif isinstance(step, RunnableStep):
                            step_exit_code = step.run(
                                step_config, opts, shell, ui
                            )
                        else:
                            ui.error(
                                f"The step {step} is not a CallableStep or a RunnableStep"
                            )
                            return step_exit_code
                        if step_exit_code != 0:
                            ui.error(
                                (
                                    f"The execution of {step} returned "
                                    f"a non-zero exit code: {step_exit_code}"
                                )
                            )
                            return step_exit_code
                    except Exception as e:
                        ui.error(
                            f"An error occured when executing {step}: {e}"
                        )
                        return 1  # TODO: Or something.

        ui.complete_phase("Install steps run")
        ui.complete_phase("Install suite complete")

        return 0


class Step(Protocol):
    @property
    def directive(self) -> str: ...

    @property
    def aliases(self) -> Sequence[str] | None: ...

    def can_run(self, directive: str) -> bool: ...


@runtime_checkable
class CallableStep(Step, Protocol):
    def __call__(
        self,
        config: StepConfig,
        opts: Options,
        shell: Shell,
        ui: UserInterface,
    ) -> int: ...


@runtime_checkable
class RunnableStep(Step, Protocol):
    def run(
        self,
        config: StepConfig,
        opts: Options,
        shell: Shell,
        ui: UserInterface,
    ) -> int: ...
