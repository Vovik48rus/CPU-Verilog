from Debugger.IDebugLineValidator import IDebugLineValidator


class NullDebugLineValidator(IDebugLineValidator):
    def valid(self) -> bool:
        return True
