from Debugger.NullDebugLineValidator import NullDebugLineValidator
from .IDebugLineValidator import IDebugLineValidator


class DebugLine:
    name: str = None
    number_line: int = None
    condition: IDebugLineValidator = None

    def __init__(self, name: str = None, number_line: int = None, condition: IDebugLineValidator = None):
        if condition is None:
            condition = NullDebugLineValidator()
        self.name = name
        self.number_line = number_line
        self.condition = condition
