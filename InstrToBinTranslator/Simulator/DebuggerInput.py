from .CPU import CPU
from .DebuggerInputState import DebuggerInputState
from .ParseProgram.ParseProgram import ParseProgram
from .ParseProgram.Point import Point
from .ParseProgram.PointRegistry import PointRegistry


class DebuggerInput:
    def __init__(self, program: str, cpu: CPU, default: DebuggerInputState = DebuggerInputState.STEP):
        self.cpu = cpu
        self.default: DebuggerInputState = default
        self.last_step: DebuggerInputState = DebuggerInputState.STEP
        self.payload: dict = {}
        self._point_registry = PointRegistry(ParseProgram(program))

    def step(self):
        match self.last_step:
            case DebuggerInputState.STEP:
                command = self._input()
                self._run_command(command)
            case DebuggerInputState.FIND_ANY_POINT:
                if self._point_registry.has_point_at_line(self.cpu.pc):
                    command = self._input()
                    self._run_command(command)
            case DebuggerInputState.FIND_POINT:
                if self._point_registry.has_point_at_line(self.cpu.pc):
                    point: Point = self._point_registry.get_point_by_line_number(self.cpu.pc)
                    if point.name == self.payload["point"].name:
                        command = self._input()
                        self._run_command(command)

    def _run_command(self, command):
        match command:
            case "next":
                self.last_step = self._get_state_from_command(command)
            case "ap" | "all-point" | "all point":
                self.last_step = self._get_state_from_command(command)
            case s if s.startswith("@"):
                self.last_step = self._get_state_from_command(command)
                point_name = command[1::]
                self.payload = {"point": Point(point_name)}
            case s if (s.startswith("def") or s.startswith("default")):
                if len(command.split(' ', maxsplit=1)) > 1:
                    default_command = command.split(' ', maxsplit=1)[1]
                    state = self.last_step
                    self._run_command(default_command)
                    self.default = self._get_state_from_command(default_command)
                    self.last_step = state
                    self.step()
                else:
                    raise ValueError("Не указана команда для установки по умолчанию.")
            case "h" | "help" | "?":
                print(self._help_text())
                self.step()
            case "":
                self.last_step = self.default

    def _get_state_from_command(self, command: str) -> DebuggerInputState:
        """
        Определяет, в какое состояние нужно перейти на основе введённой команды.
        Возвращает объект DebuggerInputState.
        """
        match command:
            case "next":
                return DebuggerInputState.STEP
            case "ap" | "all-point" | "all point":
                return DebuggerInputState.FIND_ANY_POINT
            case s if s.startswith("@"):
                return DebuggerInputState.FIND_POINT
            case _:
                return self.default

    def _input(self):
        return input(f"Enter command (default: {self.default.name.lower()}): ")

    def _help_text(self):
        HELP_TEXT = """
        Команды отладчика:
          next              — шаг выполнения (следующая инструкция)
          ap | all-point    — до любой точки (@имя)
          @<имя>            — до указанной точки
          def <команда>     — установить команду по умолчанию
          [Enter]           — выполнить команду по умолчанию
          help | ?          — показать справку
        """
        return HELP_TEXT
