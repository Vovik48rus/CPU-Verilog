from __future__ import annotations

from enum import Enum
from enum import auto
from unittest import case


class DebuggerInputState(Enum):
    STEP = auto()
    FIND_POINT = auto()
    FIND_ANY_POINT = auto()

    @classmethod
    def get_step(cls, s: str) -> DebuggerInputState | None:
        match s.lower():
            case 'step':
                return cls.STEP
            case 'find_point':
                return cls.FIND_POINT
            case 'find_any_point':
                return cls.FIND_ANY_POINT
            case _:
                return None
