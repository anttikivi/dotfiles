import sys
from abc import ABC, abstractmethod
from collections.abc import Sequence
from typing import cast

from etc.config import Options, StepConfig, StepDirective
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


class BaseStep(ABC):
    """
    BaseStep is a helper base class for the steps of the program. It
    implements common functionality shared between the internal steps.
    """

    def __init__(
        self,
        directive: StepDirective,
        aliases: StepDirective | Sequence[StepDirective] | None = None,
    ) -> None:
        self.directive: StepDirective = directive
        self.aliases: Sequence[StepDirective] = (
            cast(Sequence[StepDirective], list())
            if aliases is None
            else (
                cast(Sequence[StepDirective], [aliases])
                if type(aliases) is str
                else cast(Sequence[StepDirective], aliases)
            )
        )

    @staticmethod
    def get_step_name(directive: StepDirective, order: int) -> str:
        return f"{directive}-{order}"

    @abstractmethod
    def __call__(
        self,
        name: str,
        config: StepConfig,
        opts: Options,
        shell: Shell,
        ui: UserInterface,
    ) -> int: ...

    @override
    def __repr__(self) -> str:
        return f"<{self.__class__.__name__} '{self.directive}'>"

    def can_run(self, directive: str) -> bool:
        return directive == self.directive or directive in self.aliases
