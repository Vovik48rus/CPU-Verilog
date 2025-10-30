from CMD import CMD
from Debugger.DebugLine import DebugLine
from .ProgramData import ProgramData
from .TranslatorReport import TranslatorReport


class Translator:
    def __init__(self, program: str, program_data: ProgramData = ProgramData()):
        self.program = program
        self.program_data = program_data
        self.report: TranslatorReport = None

    def run(self) -> TranslatorReport:
        report = TranslatorReport()
        commands_and_points = [i for i in self.program.split('\n') if i]

        bin_commands: list[str] = []

        for i, command_and_point in enumerate(commands_and_points):
            bin_command, point = command_and_point.split(';')
            bin_commands.append(bin_command)
            point = point.strip()
            if len(point) > 0 and point[0] == '@':
                name_point = point[1::]
                report.debug_lines.append(DebugLine(name=name_point, number_line=i))

        bin_code = ""
        for i in bin_commands:
            operands_lst = []
            if len(i.split(' ', maxsplit=1)) > 1:
                command_str, operands_str = i.split(' ', maxsplit=1)
                operands_lst.extend(list(map(int, operands_str.split(' '))))
            else:
                command_str = i

            command = CMD.get_command(command_str)
            s = int_to_bin(command.value, self.KOP_SIZE)

            print(command.value, *operands_lst)

            # print(command, operands_lst)
            match command:
                case CMD.NOP:
                    pass
                case CMD.LTM:
                    s += int_to_bin(operands_lst[0], self.LIT_SIZE)
                    s += int_to_bin(operands_lst[1], self.ADDR_DATA_MEM_SIZE)
                case CMD.MTR:
                    s += int_to_bin(operands_lst[0], self.ADDR_RF_SIZE)
                    s += '0' * (self.LIT_SIZE - self.ADDR_RF_SIZE)
                    s += int_to_bin(operands_lst[1], self.ADDR_DATA_MEM_SIZE)
                case CMD.RTR:
                    s += int_to_bin(operands_lst[0], self.ADDR_RF_SIZE)
                    s += int_to_bin(operands_lst[1], self.ADDR_RF_SIZE)
                case CMD.SUB:
                    s += int_to_bin(operands_lst[0], self.ADDR_RF_SIZE)
                    s += int_to_bin(operands_lst[1], self.ADDR_RF_SIZE)
                    s += int_to_bin(operands_lst[2], self.ADDR_RF_SIZE)
                case CMD.JUMP_LESS:
                    s += int_to_bin(operands_lst[0], self.ADDR_RF_SIZE)
                    s += int_to_bin(operands_lst[1], self.ADDR_RF_SIZE)
                    s += int_to_bin(operands_lst[2], self.ADDR_CMD_MEM_SIZE)
                case CMD.MTRK:
                    s += int_to_bin(operands_lst[0], self.ADDR_RF_SIZE)
                    s += int_to_bin(operands_lst[1], self.ADDR_RF_SIZE)
                case CMD.RTMK:
                    s += int_to_bin(operands_lst[0], self.ADDR_RF_SIZE)
                    s += int_to_bin(operands_lst[1], self.ADDR_RF_SIZE)
                case CMD.JMP:
                    s += "0" * (2 * self.ADDR_RF_SIZE)
                    s += int_to_bin(operands_lst[0], self.ADDR_CMD_MEM_SIZE)
                case CMD.SUM:
                    s += int_to_bin(operands_lst[0], self.ADDR_RF_SIZE)
                    s += int_to_bin(operands_lst[1], self.ADDR_RF_SIZE)
                    s += int_to_bin(operands_lst[2], self.ADDR_RF_SIZE)

            if len(s) > self.CMD_SIZE:
                raise Exception(f"Command {command} too big, max size is {self.CMD_SIZE}")
            # print(s)
            bin_code += s.ljust(self.CMD_SIZE, '0') + '\n'

        bin_code = bin_code[:-1:]
        report.bin_code = bin_code
        self.report = report
        return report

    def save(self, filename="program.mem"):
        with open(filename, "w", encoding="UTF-8") as f2:
            f2.write(self.report.bin_code)
