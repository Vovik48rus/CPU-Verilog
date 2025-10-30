from enum import Enum
from enum import auto


class DebuggerInputState(Enum):
    STEP = auto()
    FIND_POINT = auto()
    FIND_ANY_POINT = auto()
