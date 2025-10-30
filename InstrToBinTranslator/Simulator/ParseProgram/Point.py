from Debugger.IDebugLineValidator import IDebugLineValidator
from Debugger.NullDebugLineValidator import NullDebugLineValidator


class Point:
    def __init__(self, name: str, condition: IDebugLineValidator = NullDebugLineValidator()):
        self._name = name
        self._condition: IDebugLineValidator = condition

    @property
    def name(self) -> str:
        return self._name

    @property
    def condition(self) -> IDebugLineValidator:
        return self._condition

    @condition.setter
    def condition(self, condition: IDebugLineValidator):
        self._condition = condition
