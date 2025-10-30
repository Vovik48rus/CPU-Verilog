from .Line import Line
from .ParseProgram import ParseProgram
from .Point import Point


class PointRegistry:
    def __init__(self, parse_program: ParseProgram):
        self._parse_program: ParseProgram = parse_program
        self._lines: list[Line] = parse_program.lines

    @property
    def points(self) -> list[Point]:
        points: list[Point] = []
        for line in self._lines:
            if line.point:
                points.append(line.point)
        return points

    def has_point(self, name: str) -> bool:
        for point in self.points:
            if point.name == name:
                return True
        return False

    def get_point(self, name: str) -> Point | None:
        for point in self.points:
            if point.name == name:
                return point
        return None

    def get_point_by_line_number(self, line_number: int) -> Point | None:
        if 0 <= line_number < len(self._lines):
            return self._lines[line_number].point
        return None

    def has_point_at_line(self, line_number: int) -> bool:
        if 0 <= line_number < len(self._lines):
            return self._lines[line_number].point is not None
        return False

    @property
    def parse_program(self) -> ParseProgram:
        return self._parse_program

    @property
    def lines(self) -> list[Line]:
        return self._lines
