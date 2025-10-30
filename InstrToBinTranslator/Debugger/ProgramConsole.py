from rich.panel import Panel
from rich.syntax import Syntax


class ProgramConsole:
    def __init__(self, program: str, interval: int = 5):
        self.lst_commands = program.split("\n")
        self.interval = interval
        self.line_number = (interval - 1) // 2
        self.max_length = len(self.lst_commands)

    def get_panel(self, line: int = None) -> Panel:
        if line is None:
            panel = Panel(
                '\n'.join(self._get_lines_with_numbers(0, self.max_length))
            )
            return panel
        else:
            start, end = line - self.line_number, line - self.line_number + self.interval
            current_line_number = self.line_number
            if line < self.line_number:
                start, end = 0, min(self.interval, self.max_length)
                current_line_number = line
            elif line > self.max_length - self.interval + self.line_number:
                start, end = max(self.max_length - self.interval, 0), self.max_length
                current_line_number = self.line_number + (self.line_number - (self.max_length - line)) + 1
            lines_with_numbers = self._get_lines_with_numbers(start, end)
            lines_with_mark = self._mark_line(lines_with_numbers, current_line_number)
            panel = Panel(
                '\n'.join(lines_with_mark)
            )
            return Panel(Syntax('\n'.join(lines_with_mark), 'python'))

    def _mark_line(self, lines: list[str], index: int) -> list[str]:
        mark_lines = []
        for i, line in enumerate(lines):
            if i == index:
                mark_lines.append("---> " + line)
            else:
                mark_lines.append("     " + line)
        return mark_lines

    def _get_lines_with_numbers(self, start, end) -> list[str]:
        commands_with_numbers = []
        for i, command in enumerate(self[start:end]):
            commands_with_numbers.append(f"{start + i:>{len(str(self.max_length))}d}\t" + command)
        return commands_with_numbers

    def __getitem__(self, key):
        if isinstance(key, slice):
            return self.lst_commands[key.start:key.stop:key.step]
        else:
            return self.lst_commands[key]
