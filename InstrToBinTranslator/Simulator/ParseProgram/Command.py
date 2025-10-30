from CMD import CMD
from Translator.ProgramData import ProgramData


class Command:
    def __init__(self, command: str, program_data: ProgramData = ProgramData()):
        self._ops: list[int] = []
        self._program_data: ProgramData = program_data

        command_and_ops = command.split(' ', maxsplit=1)
        if len(command_and_ops) > 1:
            command_str, operands_str = command_and_ops
            self._ops.extend(list(map(int, operands_str.split(' '))))
        else:
            command_str = command

        self._command: CMD = CMD.get_command(command_str)

    @property
    def ops(self) -> list[int]:
        return self._ops

    @property
    def command(self) -> CMD:
        return self._command

    @property
    def program_data(self) -> ProgramData:
        return self._program_data
