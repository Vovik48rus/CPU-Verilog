from copy import deepcopy

from Debugger.DebugLine import DebugLine
from Simulator.Console.DebuggerView import DebuggerView
from Simulator.CPU import CPU
from Simulator.DebuggerInput import DebuggerInput


class Debugger:
    """Основной класс отладчика, управляет логикой выполнения программы"""

    def __init__(self, cpu: CPU, debug_lines: list[DebugLine], program: str, debug_line_enable: bool = False):
        self.cpu = cpu
        self.debug_lines = debug_lines
        self._last_state_cpu: CPU = deepcopy(cpu)
        self._view = DebuggerView(program)
        self._program = program
        self.debugger_input = DebuggerInput(program, cpu)

    @property
    def view(self) -> DebuggerView:
        return self._view

    @view.setter
    def view(self, value: DebuggerView) -> None:
        self._view = value

    def _update_last_state_cpu(self, cpu: CPU):
        self._last_state_cpu = deepcopy(cpu)
        self.debugger_input.cpu = self._last_state_cpu

    def run(self):
        while not self.cpu.is_finished():
            self.cpu.step()
            self.view.render(self.cpu, self._last_state_cpu)
            self.debugger_input.step()
            self._update_last_state_cpu(self.cpu)
