from Translator.ProgramData import ProgramData
from .Point import Point
from .Command import Command

class Line:
    def __init__(self, line: str, program_data: ProgramData = ProgramData()):
        bin_command, point = line.split(';')
        point = point.strip()
        self._point: Point = None
        if len(point) > 0 and point[0] == '@':
            name_point = point[1::]
            self._point: Point = Point(name_point)

        self._command: Command = Command(bin_command, program_data)

    @property
    def point(self) -> Point:
        return self._point

    @property
    def command(self) -> Command:
        return self._command