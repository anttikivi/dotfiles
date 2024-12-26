import sys
from abc import ABC
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from typing import Literal, NotRequired, TypedDict

from etc.exceptions import UnsupportedPlatformError
from etc.shell import MessageLevel

Platform = Literal["darwin"]

StepDirective = Literal["clean", "system-packages", "packages"]


#######################################################################
# OLD CONFIG
#######################################################################


class StepConfig(TypedDict):
    directive: StepDirective


#######################################################################
# SYSTEM PACKAGES CONFIG
#######################################################################


# Packages can be declared either as a list of package names or as
# key-value pairs where the key is the name of the package and the value
# is the wanted version. If only a list of strings is given, the latest
# versions will be used. Latest version will also be used if the given
# version string is empty.
PackagesDeclaration = Sequence[str] | Mapping[str, str]

PlatformPackagesConfig = PackagesDeclaration

DarwinPackagesConfig = TypedDict(
    "DarwinPackagesConfig",
    {
        "formulae": NotRequired[PackagesDeclaration],
        "casks": NotRequired[PackagesDeclaration],
    },
)

_SystemPackagesPlatformsConfig = TypedDict(
    "_SystemPackagesPlatformsConfig",
    {
        "all": NotRequired[PlatformPackagesConfig],
        "darwin": NotRequired[PlatformPackagesConfig | DarwinPackagesConfig],
    },
)


class SystemPackagesStepConfig(StepConfig):
    packages: NotRequired[PackagesDeclaration]
    platforms: NotRequired[_SystemPackagesPlatformsConfig]


#######################################################################
# INSTALL CONFIG
#######################################################################


_InstallConfig = TypedDict(
    "_InstallConfig", {"steps": NotRequired[Sequence[StepConfig]]}
)


#######################################################################
# BASE CONFIG
#######################################################################


class OldConfig(TypedDict):
    """
    Config represents a parsed configuration file.
    """

    install: NotRequired[_InstallConfig]


#######################################################################
# OPTIONS
#######################################################################

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


@dataclass
class Options:
    """
    Options represents the command-line options given for a single run
    of the program.
    """

    # def __init__(
    #     self,
    #     base_directory: str | None,
    #     command: CommandName | None,
    #     config_file: str | None,
    #     dry_run: bool,
    #     remote_repository_url: str | None,
    #     use_colors: bool,
    #     verbosity: MessageLevel,
    #     print_commands: bool,
    # ):
    #     self.base_directory: str | None = base_directory
    #     self.command: CommandName | None = command
    #     self.config_file: str | None = config_file
    #     self.dry_run: bool = dry_run
    #     self.remote_repository_url: str | None = remote_repository_url
    #     self.use_colors: bool = use_colors
    #     self.verbosity: MessageLevel = verbosity
    #     self.print_commands: bool = print_commands

    colors: bool
    command: CommandName | str
    dry_run: bool
    print_commands: bool
    verbosity: MessageLevel

    command_opts: "CommandOptions | None"


@dataclass
class CommandOptions(ABC):
    """
    Contains the parsed command-line options for a subcommand. Cannot
    be used by itself but each subcommand should have its own
    implementation of this class.
    """

    ...


@dataclass
class SubcommandOptions(CommandOptions):
    """
    A helper class for the internal subcommands to use as the commands
    options.
    """

    base_directory: str
    config_file: str


@dataclass
class BootstrapOptions(SubcommandOptions):
    remote_repository: str
