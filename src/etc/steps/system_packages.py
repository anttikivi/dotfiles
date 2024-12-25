import os
import sys
from typing import cast

from etc.config import (
    DarwinPackagesConfig,
    Options,
    PackagesDeclaration,
    Platform,
    StepConfig,
    SystemPackagesStepConfig,
)
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
    def __init__(self) -> None:
        super().__init__("system-packages", "packages")

    @override
    def __call__(
        self,
        config: StepConfig,
        opts: Options,
        shell: Shell,
        ui: UserInterface,
    ) -> int:
        ui.start_step(
            (
                f'Invoking the "{self.directive}" runner for the '
                f'"{config["directive"]}" step'
            )
        )
        config = cast(SystemPackagesStepConfig, config)

        ui.trace("Created the configuration instance")
        ui.trace(f"Received the following configuration: {config}")

        # Populate the packages first from the `packages` list. If the
        # key does not exist, this the packages are set to an empty
        # dictionary by default and updated later with the packages from
        # `platforms.all`.
        all_packages: PackagesDeclaration = {}
        ui.trace("Created the `all_packages` instance")
        if "packages" in config:
            ui.debug('Found the key "packages" in the system packages step')
            all_packages = config["packages"]

        ui.trace(
            (
                "After populating from `packages`, `all_packages` is now "
                f"{all_packages}"
            )
        )

        # Convert the packages to a dict if they are given as a list.
        if type(all_packages) is list:
            ui.trace("`all_packages` is a list")
            all_packages = {pkg: "" for pkg in all_packages}
        ui.trace(
            (
                "`all_packages` is now converted to a dictionary and is "
                f"{all_packages}"
            )
        )

        # `all_packages` should always be a dictionary at this point.
        # The LSP understands the assert statement, so it is placed here
        # for convenience.
        assert (
            type(all_packages) is dict
        ), 'variable "all_packages" is not a dictionary'

        ui.trace(
            (
                "Assertion for `all_packages` complete, the type is "
                f"{type(all_packages)}"
            )
        )

        platforms_config = None
        ui.trace("Created the `platforms_config` configuration instance")
        if "platforms" in config:
            ui.debug('Found the key "platforms" in the system packages step')
            platforms_config = config["platforms"]

        ui.trace(
            (
                'After populating from "platforms", variable '
                f"`platforms_config` is now {platforms_config}"
            )
        )

        # Start by checking if there are packages to install on all
        # platforms and merge them with the
        if "all" in platforms_config:
            ui.debug(
                (
                    'Found the key "all" in the platforms configuration of the '
                    "system packages step"
                )
            )
            platform_all_pkgs = platforms_config["all"]
            if type(platform_all_pkgs) is list:
                platform_all_pkgs = {pkg: "" for pkg in platform_all_pkgs}
            ui.trace(
                (
                    'After populating from "platforms.all", variable '
                    f"`platform_all_pkgs` is now {platform_all_pkgs}"
                )
            )

            # `platform_all_pkgs` should always be a dictionary at this
            # point.
            assert type(platform_all_pkgs) is dict
            all_packages.update(platform_all_pkgs)

        ui.trace(
            (
                'After merging with packages from "platforms.all", variable '
                f"`all_packages` is now {all_packages}"
            )
        )

        # TODO: Handle Linux distros.
        shell.echo_uname_tr()
        # TODO: Set this at the start of the program run and receive
        # the value from the caller.
        current_platform: Platform = cast(Platform, sys.platform)

        ui.trace(f'Resolved "{current_platform}" as the platform')
        ui.debug(
            (
                "Checking if there are platform-specific packages for "
                f'"{current_platform}"'
            )
        )

        # Create the instance for casks as it is needed if we are
        # running Darwin.
        all_casks: PackagesDeclaration = {}

        if current_platform in platforms_config:
            ui.debug(
                (
                    f'Found the key "{current_platform}" in the platforms '
                    "configuration of the system packages step"
                )
            )
            current_platform_config = platforms_config[current_platform]
            if current_platform == "darwin" and (
                "formulae" in current_platform_config
                or "casks" in current_platform_config
            ):
                current_platform_config = cast(
                    DarwinPackagesConfig, current_platform_config
                )
                # NOTE: This is stupid, but I want to print the
                # granular debug messages.
                if (
                    "formulae" in current_platform_config
                    and "casks" in current_platform_config
                ):
                    ui.debug(
                        (
                            'Found the keys "formulae" and "casks" in the platforms configuration of the system packages step'
                        )
                    )
                elif "formulae" in current_platform_config:
                    ui.debug(
                        (
                            'Found the key "formulae" in the platforms configuration of the system packages step'
                        )
                    )
                elif "casks" in current_platform_config:
                    ui.debug(
                        (
                            'Found the key "casks" in the platforms configuration of the system packages step'
                        )
                    )

                # Populate the packages from `formulae`.
                if "formulae" in current_platform_config:
                    formulae = current_platform_config["formulae"]
                    if type(formulae) is list:
                        formulae = {formula: "" for formula in formulae}
                    ui.trace(
                        (
                            "After populating from "
                            '"platforms.darwin.formulae", variable '
                            f"`formulae` is now {formulae}"
                        )
                    )
                    # `formulae` should always be a dictionary at this
                    # point.
                    assert type(formulae) is dict
                    all_packages.update(formulae)

                # Populate the packages from `formulae`.
                if "casks" in current_platform_config:
                    casks = current_platform_config["casks"]
                    if type(casks) is list:
                        casks = {cask: "" for cask in casks}
                    ui.trace(
                        (
                            'After populating from "platforms.darwin.casks", '
                            f"variable `casks` is now {casks}"
                        )
                    )
                    # `casks` should always be a dictionary at this
                    # point.
                    assert type(casks) is dict
                    all_casks.update(casks)

            else:
                platform_pkgs: PackagesDeclaration = cast(
                    PackagesDeclaration, platforms_config[current_platform]
                )
                if type(platform_pkgs) is list:
                    platform_pkgs = {pkg: "" for pkg in platform_pkgs}
                ui.trace(
                    (
                        "After populating from "
                        f'"platforms.{current_platform}", variable '
                        f"`platform_pkgs` is now {platform_pkgs}"
                    )
                )
                # `platform_all_pkgs` should always be a dictionary at this
                # point.
                assert type(platform_pkgs) is dict
                all_packages.update(platform_pkgs)

        ui.trace(
            (
                "After merging with packages from "
                f'"platforms.{current_platform}", variable `all_packages` is '
                f"now {all_packages}"
            )
        )
        if current_platform == "darwin":
            ui.trace(
                (
                    "After merging with casks from "
                    f'"platforms.{current_platform}", variable `all_casks` is '
                    f"now {all_casks}"
                )
            )

        ui.start_task("Starting to install the packages")
        ui.trace("Going to install:")
        for k, v in all_packages.items():
            s = f" - {k}"
            if v != "":
                s = f"{s}@{v}"
            ui.trace(s)

        if current_platform == "darwin":
            self._install_darwin_packages(shell, ui, all_packages)

            if all_casks:
                ui.start_task("Installing casks")
                self._install_darwin_packages(shell, ui, all_casks, casks=True)
                ui.complete_task("Casks installed")
        else:
            raise ValueError(
                (
                    "trying to install packages on an unsupported platform: "
                    f"{current_platform}"
                )
            )  # pyright: ignore[reportUnreachable]

        ui.complete_task("Packages installed")

        ui.complete_step(f'Step "{config["directive"]}" complete')

        return 0

    def _install_darwin_packages(
        self,
        shell: Shell,
        ui: UserInterface,
        packages: dict[str, str],
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
