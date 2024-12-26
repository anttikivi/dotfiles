import sys
from abc import ABC
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from typing import Literal

from etc.exceptions import UnsupportedPlatformError
from etc.shell import MessageLevel

Platform = Literal["darwin"]

StepDirective = Literal["clean", "system-packages", "packages"] | str

CONFIG_PARSED_MARKER = "etc_has_parsed"


@dataclass
class Config:
    """
    Config is the parsed configuration for a run of the program.

    The `steps` are the parsed configurations for the steps used by the
    program. The key of the mapping is a combination of a step's
    directive and the order number of the step within the same type of
    steps.

    The `steps_order` is simply an ordered sequence of the keys for the
    step configurations stored in `steps`.
    """

    steps: Mapping[str, "StepConfig"]
    steps_order: Sequence[str]


@dataclass
class StepConfig(ABC):
    directive: StepDirective


@dataclass
class SystemPackagesConfig(StepConfig):
    """
    SystemPackagesConfig is the type of the parsed configuration for the
    "system-packages" step. It resolves all of the packages to install
    into the `packages` mapping. The keys of the mapping are the names
    of the packages and the values are their version. The version info
    can be an empty string.
    """

    packages: Mapping[str, str]
    platform: Platform | None


@dataclass
class DarwinPackagesConfig(SystemPackagesConfig):
    casks: Mapping[str, str]


#######################################################################
# OPTIONS
#######################################################################

CommandName = (
    Literal["etc", "bootstrap", "init", "initialize", "install"] | str
)

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

    platform: Platform

    colors: bool
    command: CommandName
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
