import os
import sys
from collections.abc import Mapping, MutableMapping, Sequence
from typing import Any, cast, get_args

from etc.config import (
    DarwinPackagesConfig,
    Options,
    Platform,
    StepConfig,
    StepDirective,
    SystemPackagesConfig,
)
from etc.exceptions import ConfigTypeError, InvalidConfigError
from etc.shell import Shell
from etc.steps.base_step import BaseStep
from etc.ui import UserInterface

if sys.version_info >= (3, 12):
    from typing import override
else:
    from typing import Any, Callable

    _Func = Callable[..., Any]

    # Fallback for Python 3.11 and earlier.
    def override(method: _Func, /) -> _Func:  # pyright: ignore[reportUnreachable]
        return method


class SystemPackagesStep(BaseStep):
    """
    Installs system-wide packages.
    """

    def __init__(self) -> None:
        super().__init__("system-packages", "packages")

    @override
    def __call__(
        self,
        name: str,
        config: StepConfig,
        opts: Options,
        shell: Shell,
        ui: UserInterface,
    ) -> int:
        ui.start_step(
            f'Invoking the "{name}" step for the "{config.directive}" step'
        )
        if not isinstance(config, SystemPackagesConfig):
            raise TypeError(
                (
                    f'the "{name}" step received a config that is not an '
                    "instance of SystemPackagesConfig but the type of which "
                    f'is "{type(config)}"'
                )
            )

        if config.platform is not None and opts.platform != config.platform:
            ui.complete_step(
                (
                    f'The "{name}" step is configured for {config.platform} '
                    f"but the program is running on {opts.platform}, skipping"
                )
            )  # pyright: ignore[reportUnreachable]
            return 0

        if config.platform == "darwin" and not isinstance(
            config, DarwinPackagesConfig
        ):
            raise TypeError(
                (
                    f'on Darwin, the "{name}" step received a config that is '
                    "not an instance of DarwinPackagesConfig but the type of "
                    f'which is "{type(config)}"'
                )
            )

        ui.trace(f"Received the following configuration: {config}")

        ui.start_task("Starting to install the packages")
        ui.trace("Going to install:")
        for k, v in config.packages.items():
            s = f" - {k}"
            if v != "":
                s = f"{s}@{v}"
            ui.trace(s)

        if config.platform == "darwin":
            config = cast(DarwinPackagesConfig, config)
            self._install_darwin_packages(shell, ui, config.packages)

            if config.casks:
                ui.start_task("Installing casks")
                ui.trace("Going to install:")
                for k, v in config.casks.items():
                    s = f" - {k}"
                    if v != "":
                        s = f"{s}@{v}"
                    ui.trace(s)
                self._install_darwin_packages(
                    shell, ui, config.casks, casks=True
                )
                ui.complete_task("Casks installed")
        else:
            config = cast(SystemPackagesConfig, config)
            if opts.platform == "darwin":
                self._install_darwin_packages(shell, ui, config.packages)
            else:
                raise ValueError(
                    (
                        f"trying to install packages on an unsupported "
                        f"platform: {opts.platform}"
                    )
                )  # pyright: ignore[reportUnreachable]

        ui.complete_task("Packages installed")

        ui.complete_step(f'Step "{name}" complete')

        return 0

    def parse_config(
        self,
        raw: Mapping[str, Any],  # pyright: ignore[reportExplicitAny]
        ui: UserInterface,
        order: int,
    ) -> StepConfig:
        """
        Parses the configuration of the system packages step.

        Valid configuration is one of the following (in addition to
        either `directive` or `name` key):
            - String `platform` corresponding to one of the valid
              platforms given in the type etc.config.Platform. If this
              string is present, the packages in this step are installed
              only on the given platform.
            - Array or table `packages` that contains packages to be
              installed. If no `platform` is given, the packages are
              installed on all platforms. If `packages` is given as a
              table, the key of the table is the name of the package and
              the value is the version to install. The version
              information is optional and can be an empty string. If it
              is, the functionality is essentially the same as if the
              package was given using the `packages` array.

        Darwin-specific configuration:
            - Array or table `formulae` that contains Homebrew formulae
              to install. This functions similar to the `packages` array
              or table. You can use `packages` as a synonym for
              `formulae` on Darwin.
            - Array or table `casks` that contains Homebrew casks to
              install. This functions similar to the `packages` array or
              table.
        """
        name = BaseStep.get_step_name(self.directive, order)
        platform: Platform | None = None
        if "platform" in raw:
            t = type(raw["platform"])  # pyright: ignore[reportAny, reportUnknownVariableType]
            if t is not str:
                raise ConfigTypeError(
                    (
                        f'in step "{name}": type of the value "platform" is '
                        f'not "str" but "{t}"'
                    )
                )
            pkgs = cast(str, raw["platform"])
            if pkgs not in get_args(Platform):
                raise InvalidConfigError
            platform = cast(Platform, pkgs)

        ui.trace(f'Resolved "{platform}" as the platform of the "{name}" step')

        if "formulae" in raw and platform != "darwin":
            raise InvalidConfigError(
                (
                    f'the "{name}" step for platform other than "darwin" '
                    f'({platform}) contains the key "formulae"'
                )
            )
        if "casks" in raw and platform != "darwin":
            raise InvalidConfigError(
                (
                    f'the "{name}" step for platform other than "darwin" '
                    f'({platform}) contains the key "casks"'
                )
            )
        if platform == "darwin" and "packages" in raw and "formulae" in raw:
            raise InvalidConfigError(
                (
                    f'the "{name}" step for "darwin" has both "packages" and '
                    '"formulae" keys'
                )
            )

        packages: MutableMapping[str, str] = {}
        packages_found = False
        if "packages" in raw:
            ui.trace('Found the key "packages" in the step')
            packages_found = True
            pkgs = self._parse_config_packages(raw["packages"], "packages", ui)
            packages.update(pkgs)
        ui.trace(
            (
                'After parsing from "packages", the packages for the '
                f'"{name}" step are: {packages}'
            )
        )

        if platform == "darwin" and "formulae" in raw:
            ui.trace('Found the key "formulae" in the step')
            packages_found = True
            pkgs = self._parse_config_packages(raw["formulae"], "formulae", ui)
            packages.update(pkgs)
        ui.trace(
            (
                'After parsing from "formulae", the packages for the '
                f'"{name}" step are: {packages}'
            )
        )

        casks: MutableMapping[str, str] = {}
        if platform == "darwin" and "casks" in raw:
            ui.trace('Found the key "casks" in the step')
            packages_found = True
            pkgs = self._parse_config_packages(raw["casks"], "casks", ui)
            casks.update(pkgs)
            ui.trace(
                (
                    f'After parsing from "casks", the casks for the "{name}" '
                    f"step are: {casks}"
                )
            )

        if not packages_found:
            raise InvalidConfigError(
                f'no valid packages configuration found for the "{name}"'
            )

        if platform == "darwin":
            return DarwinPackagesConfig(
                directive=cast(StepDirective, raw["directive"]),
                packages=packages,
                platform=platform,
                casks=casks,
            )
        else:
            return SystemPackagesConfig(
                directive=cast(StepDirective, raw["directive"]),
                packages=packages,
                platform=platform,
            )

    def _install_darwin_packages(
        self,
        shell: Shell,
        ui: UserInterface,
        packages: Mapping[str, str],
        casks: bool | None = None,
    ):
        ui.trace("Getting the list of installed Homebrew packages")
        installed_packages = shell.output(["brew", "ls"])
        for pkg, ver in packages.items():
            ui.trace(f'Handling the {"cask" if casks else "package"} "{pkg}"')
            ui.trace(
                (
                    f'Checking it the {"cask" if casks else "package"} '
                    f'"{pkg}" is installed'
                )
            )
            shell.print_command(["basename", pkg])
            pkg_name = os.path.basename(pkg) if "/" in pkg else pkg
            should_install = True
            shell.print_command(["brew", "ls", "|", "grep", "-qx", pkg_name])
            for p in (p for p in installed_packages.splitlines()):
                if pkg_name == p:
                    should_install = False
                    break
            if not should_install:
                ui.debug(
                    (
                        f'The {"cask" if casks else "package"} "{pkg}" is '
                        'already installed, skipping'
                    )
                )
                continue
            ui.start_task(
                f'Installing "{(pkg if ver == "" else f"{pkg}@{ver}")}"'
            )
            shell(
                ["brew", "install", "--cask", pkg]
                if casks
                else ["brew", "install", pkg]
            )
            ui.complete_task(
                f'"{(pkg if ver == "" else f"{pkg}@{ver}")}" installed'
            )

    def _parse_config_packages(
        self,
        raw: Any,  # pyright: ignore[reportAny, reportExplicitAny]
        key: str,
        ui: UserInterface,
    ) -> Mapping[str, str]:
        ui.trace(f'Parsing the packages from "{key}"')
        packages: MutableMapping[str, str] = {}
        if isinstance(raw, Sequence):
            ui.trace(f'The value found for "{key}" is a Sequence')
            for pkg in cast(list[str], raw):
                if type(pkg) is not str:
                    raise ConfigTypeError(
                        (
                            f'the entry {pkg} in "{key}" in the '
                            f'"{self.directive}" step is not a string'
                        )
                    )
                packages[pkg] = ""
        elif isinstance(raw, Mapping):
            ui.trace(f'The value found for "{key}" is a Mapping')
            for k, v in cast(dict[str, str], raw).items():
                if type(k) is not str:
                    raise ConfigTypeError(
                        (
                            f'the key "{k}" in "{key}" in the '
                            f'"{self.directive}" step is not a string'
                        )
                    )
                if type(v) is not str:
                    raise ConfigTypeError(
                        (
                            f'the value "{v}" for the key "{k}" in "{key}" in '
                            f'the "{self.directive}" step is not a string'
                        )
                    )
                packages[k] = v
        else:
            raise ConfigTypeError(
                (
                    "invalid type for packages specification in the "
                    f'"{self.directive}" step: {raw}'
                )
            )
        return packages
