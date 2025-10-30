from .CPU import CPU
from .DebuggerInputState import DebuggerInputState


class DebuggerInput:
    def __init__(self, program: str, cpu: CPU, default: DebuggerInputState = DebuggerInputState.STEP):
        self.cpu = cpu
        self.default: DebuggerInputState = default
        self.last_step: DebuggerInputState = DebuggerInputState.STEP
        self.payload: dict = {}
        self.program = program.split('\n')

    def step(self):
        match self.last_step:
            case DebuggerInputState.STEP:
                command = self._input()
                self._run_command(command) # Дописать step и использовать в debugger
            case DebuggerInputState.FIND_ANY_POINT:
                pass


    def _run_command(self, command):
        match command:
            case "next":
                self.last_step = DebuggerInputState.STEP
            case "ap" | "all-point" | "all point":
                self.last_step = DebuggerInputState.FIND_ANY_POINT
            case s if s.startswith("@"):
                self.last_step = DebuggerInputState.FIND_POINT
                point_name = command[1::]
                self.payload = {"point": point_name}
            case s if (s.startswith("def") or s.startswith("default")):
                self.step()


    def _input(self):
        return input(f"Enter command (default: {self.default.__str__()}): ")
