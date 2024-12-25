import argparse
import os
import sys
from typing import Literal, Required, TypedDict, cast

from etc.exceptions import UnsupportedPlatformError
from etc.shell import MessageLevel

Platform = Literal["darwin"]

StepDirective = Literal["system-packages", "packages"]

# Packages can be declared either as a list of package names or as
# key-value pairs where the key is the name of the package and the value
# is the wanted version. If only a list of strings is given, the latest
# versions will be used. Latest version will also be used if the given
# version string is empty.
PackagesDeclaration = list[str] | dict[str, str]

PlatformPackagesConfig = PackagesDeclaration

DarwinPackagesConfig = TypedDict(
    "DarwinPackagesConfig",
    {"formulae": PackagesDeclaration, "casks": PackagesDeclaration},
    total=False,
)

_SystemPackagesPlatformsConfig = TypedDict(
    "_SystemPackagesPlatformsConfig",
    {
        "all": PlatformPackagesConfig,
        "darwin": PlatformPackagesConfig | DarwinPackagesConfig,
    },
    total=False,
)


class StepConfig(TypedDict, total=False):
    directive: Required[StepDirective]


class SystemPackagesStepConfig(StepConfig):
    directive: Required[StepDirective]
    packages: PackagesDeclaration
    platforms: _SystemPackagesPlatformsConfig


_InstallConfig = TypedDict(
    "_InstallConfig", {"steps": list[StepConfig]}, total=False
)


class Config(TypedDict, total=False):
    """
    Config represents a parsed configuration file.
    """

    install: _InstallConfig


CommandName = Literal["etc", "bootstrap", "init", "initialize", "install"]

DEFAULT_LINUX_BASE_DIRECTORY = "~/etc"
DEFAULT_DARWIN_BASE_DIRECTORY = "~/Preferences"
DEFAULT_CONFIG = "etc.toml"


def get_default_base_directory() -> str:
    if sys.platform == "darwin":
        return DEFAULT_DARWIN_BASE_DIRECTORY

    if sys.platform == "linux":
        return DEFAULT_LINUX_BASE_DIRECTORY

    raise UnsupportedPlatformError


class Options:
    """
    Options represents the command-line options given for a single run
    of the program.
    """

    def __init__(
        self,
        base_directory: str | None,
        command: CommandName | None,
        config_file: str | None,
        dry_run: bool,
        remote_repository_url: str | None,
        use_colors: bool,
        verbosity: MessageLevel,
        print_commands: bool,
    ):
        self.base_directory: str | None = base_directory
        self.command: CommandName | None = command
        self.config_file: str | None = config_file
        self.dry_run: bool = dry_run
        self.remote_repository_url: str | None = remote_repository_url
        self.use_colors: bool = use_colors
        self.verbosity: MessageLevel = verbosity
        self.print_commands: bool = print_commands

    @classmethod
    def parse(cls, args: argparse.Namespace) -> "Options":
        command = cast(CommandName | None, args.command)

        colors = cast(bool | None, args.colors)
        if colors is None:
            # TODO: Use a better way to determine the default value.
            colors = True

        base_directory = (
            None
            if "base_directory" not in args
            else os.path.expandvars(
                os.path.expanduser(cast(str, args.base_directory))
            )
        )
        if base_directory is not None and not os.path.isabs(base_directory):
            base_directory = os.path.abspath(base_directory)

        config_file = (
            None
            if "config_file" not in args
            else os.path.expandvars(
                os.path.expanduser(cast(str, args.config_file))
            )
        )
        # All commands that use the config file should also specify the
        # base directory. This might be changed in the future, but for
        # now, they have at least the default values.
        if base_directory is None and config_file is not None:
            raise ValueError(
                "configuration file has a value while base directory does not"
            )
        if (
            base_directory is not None
            and config_file is not None
            and not os.path.isabs(config_file)
        ):
            config_file = os.path.normpath(
                os.path.join(base_directory, config_file)
            )

        dry_run = cast(bool, args.dry_run)

        remote_repo = (
            None
            if "remote_repository" not in args
            else cast(str, args.remote_repository)
        )
        if command == "bootstrap" and remote_repo is None:
            raise ValueError("the remote repository is None")

        verbosity = MessageLevel.INFO - MessageLevel(cast(int, args.verbose))
        print_commands = (
            False
            if "print_commands" not in args
            else cast(bool, args.print_commands)
        ) or dry_run

        return cls(
            base_directory=base_directory,
            command=command,
            config_file=config_file,
            dry_run=dry_run,
            remote_repository_url=remote_repo,
            use_colors=colors,
            verbosity=verbosity,
            print_commands=print_commands,
        )
