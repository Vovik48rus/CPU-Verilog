from rich.console import Console
from rich.columns import Columns
from rich.panel import Panel
from rich.table import Table
from rich.text import Text
from rich.console import Group
from rich.padding import Padding

from Simulator.Console.DebuggerViewData import DebuggerViewData
from Debugger.ProgramConsole import ProgramConsole
from Simulator.CPU import CPU


class DebuggerView:
    """Отвечает за визуализацию состояния отладчика"""

    def __init__(self, program: str, debug_view_data: DebuggerViewData = None):
        self.console = Console()
        self.program_console = ProgramConsole(program)
        if debug_view_data is None:
            debug_view_data = DebuggerViewData()
        self._debug_view_data = debug_view_data

    @property
    def debug_view_data(self) -> DebuggerViewData:
        return self._debug_view_data

    @debug_view_data.setter
    def debug_view_data(self, value: DebuggerViewData) -> None:
        self._debug_view_data = value

    def render(self, current_cpu: CPU, previous_cpu: CPU):
        """Отрисовывает текущее состояние CPU с подсветкой изменений"""
        self.console.clear()

        main_group = Group()

        current_command_panel = self.program_console.get_panel(previous_cpu.pc)
        current_command_panel.title = Text("Current command")
        main_group.renderables.append(current_command_panel)

        group_before = self._create_before_group(current_cpu, previous_cpu)
        group_after = self._create_after_group(current_cpu, previous_cpu)

        columns = Columns([
            Panel(group_before, title='Before'),
            Panel(group_after, title='After')
        ])
        main_group.renderables.append(columns)

        next_command_panel = self.program_console.get_panel(current_cpu.pc)
        next_command_panel.title = Text("Next command")
        main_group.renderables.append(next_command_panel)

        self.console.print(main_group)

    def _create_before_group(self, current_cpu: CPU, previous_cpu: CPU) -> Group:
        """Создает группу с состоянием 'до' выполнения команды"""
        group = Group()

        pc_pad = self._get_difference_number(
            "pc", current_cpu.pc, previous_cpu.pc, color="red"
        )
        rf_table = self._get_difference_list(
            current_cpu.RF, previous_cpu.RF, color="red"
        )
        rf_table.title = Text("RF")

        dmem_table = self._get_difference_list(
            current_cpu.DMEM, previous_cpu.DMEM, color="red"
        )
        dmem_table.title = Text("DMEM")

        group.renderables.extend((pc_pad, rf_table, dmem_table))
        return group

    def _create_after_group(self, current_cpu: CPU, previous_cpu: CPU) -> Group:
        """Создает группу с состоянием 'после' выполнения команды"""
        group = Group()

        pc_pad = self._get_difference_number(
            "pc", previous_cpu.pc, current_cpu.pc, color="green"
        )
        rf_table = self._get_difference_list(
            previous_cpu.RF, current_cpu.RF, color="green"
        )
        rf_table.title = Text("RF")

        dmem_table = self._get_difference_list(
            previous_cpu.DMEM, current_cpu.DMEM, color="green"
        )
        dmem_table.title = Text("DMEM")

        group.renderables.extend((pc_pad, rf_table, dmem_table))
        return group

    def _get_difference_list(self, diff_list: list, current_list: list, color: str = "green") -> Table:
        """Создает таблицу с подсветкой измененных значений"""
        table = Table(show_header=True, header_style="bold white on dark_blue", box=None)

        table.add_column("#", justify="right", width=self.debug_view_data.CELL_SIZE, style="dim")

        for i in range(self.debug_view_data.MAX_WIDTH):
            table.add_column(str(i), justify="right", width=self.debug_view_data.CELL_SIZE, no_wrap=True)

        formatted_row = []
        for i, value in enumerate(current_list):
            if i % self.debug_view_data.MAX_WIDTH == 0:
                row_number = int((i // self.debug_view_data.MAX_WIDTH) * self.debug_view_data.MAX_WIDTH)
                formatted_row.append(Text(str(row_number)))

            if current_list[i] == diff_list[i]:
                formatted_row.append(Text(str(value)))
            else:
                formatted_row.append(Text(str(value), style=f"bold {color}"))

            if i != 0 and i % self.debug_view_data.MAX_WIDTH == self.debug_view_data.MAX_WIDTH - 1:
                table.add_row(*formatted_row)
                formatted_row = []
            if i == self.debug_view_data.MAX_HEIGHT * self.debug_view_data.MAX_WIDTH - 1:
                break

        if len(formatted_row) > 0:
            table.add_row(*formatted_row)

        return table

    def _get_difference_number(self, name: str, diff_number: int, current_number: int, color: str = "green") -> Padding:
        """Создает Padding с подсветкой измененного числа"""
        style = ""
        if diff_number != current_number:
            style = f"bold {color}"

        pad = Padding(f"{name}: {str(current_number)}", style=style, pad=1)

        return pad
