from abc import ABC, abstractmethod
from collections.abc import Sequence
import sys
from typing import cast

from etc.config import Config, Options, StepConfig, StepDirective
from etc.shell import Shell
from etc.ui import UserInterface


if sys.version_info >= (3, 12):
    from typing import override
else:
    from typing import Any, Callable

    _Func = Callable[..., Any]

    # Fallback for Python 3.11 and earlier.
    def override(method: _Func, /) -> _Func:  # pyright: ignore[reportUnreachable]
        return method


class Step(ABC):
    """
    StepRunner is a helper base class for the step runners of the
    program. It implements common functionality shared between the
    internal step runners.
    """

    def __init__(
        self,
        directive: StepDirective,
        aliases: StepDirective | Sequence[StepDirective] | None = None,
    ) -> None:
        self.directive: StepDirective = directive
        self.aliases: Sequence[str] | None = None
        if aliases is not None:
            self.aliases = (
                cast(Sequence[str], [aliases])
                if type(aliases) is str
                else cast(Sequence[str], aliases)
            )

    @abstractmethod
    def __call__(
        self,
        config: StepConfig,
        opts: Options,
        shell: Shell,
        ui: UserInterface,
    ) -> int: ...

    @override
    def __repr__(self) -> str:
        return f"<{self.__class__.__name__} '{self.directive}'>"

    def can_run(self, directive: str) -> bool:
        return directive == self.directive or (
            self.aliases is not None and directive in self.aliases
        )
