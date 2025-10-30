from copy import deepcopy

from Debugger.DebugLine import DebugLine
from Simulator.Console.DebuggerView import DebuggerView
from Simulator.CPU import CPU


class Debugger:
    """Основной класс отладчика, управляет логикой выполнения программы"""

    def __init__(self, cpu: CPU, debug_lines: list[DebugLine], program: str, debug_line_enable: bool = False):
        self.cpu = cpu
        self.debug_lines = debug_lines
        self._last_state_cpu: CPU = deepcopy(cpu)
        self._view = DebuggerView(program)
        self._program = program
        self.debug_line_enable = debug_line_enable
        self.current_debug_line: DebugLine = None

    @property
    def view(self) -> DebuggerView:
        return self._view

    @view.setter
    def view(self, value: DebuggerView) -> None:
        self._view = value

    def _update_last_state_cpu(self, cpu: CPU):
        self._last_state_cpu = deepcopy(cpu)

    def run(self):
        command = ''
        while not self.cpu.is_finished():
            self.cpu.step()
            self.view.render(self.cpu, self._last_state_cpu)
            if self.debug_line_enable:
                if self.current_debug_line is None:
                    for i in self.debug_lines:
                        if self._last_state_cpu.pc == i.number_line:
                            command = input("Enter command (default: next): ")
                else:
                    lst = self._program.split('\n')
                    if '@' in lst[self._last_state_cpu.pc] and self.current_debug_line.name == lst[self._last_state_cpu.pc].split("@")[1]:
                        command = input("Enter command (default: next): ")
            match (command.strip()):
                case "next":
                    pass
                case s if s.startswith("@"):
                    point = command[1::]
                    self.current_debug_line = DebugLine(point)
            self._update_last_state_cpu(self.cpu)
