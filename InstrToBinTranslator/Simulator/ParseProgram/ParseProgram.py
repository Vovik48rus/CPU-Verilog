from .Line import Line
from Translator.ProgramData import ProgramData


class ParseProgram:
    def __init__(self, program: str, program_data: ProgramData = None):
        self._program = program
        self._program_data: ProgramData = program_data or ProgramData()
        self._lines: list[Line] = []
        self._parse_program()

    @property
    def lines(self) -> list[Line]:
        if not self._lines:
            self._parse_program()
        return self._lines

    def _parse_program(self):
        lines_str = [i for i in self._program.split('\n') if i]
        self._lines = [Line(line_str, self._program_data) for line_str in lines_str]

    @property
    def program(self) -> str:
        return self._program

    @program.setter
    def program(self, program: str):
        self.clear()
        self._program = program

    def clear(self):
        """Очищает программу и список строк."""
        self._program = ''
        self._lines = []

    @property
    def program_data(self) -> ProgramData:
        return self._program_data
