from pathlib import Path

from CMD import CMD
from Simulator.Instruction import Instruction
from Simulator.Pipeline.PipelineCPU import PipelineCPU
from Translator.Translator import Translator
from Simulator.CPU import CPU
from Simulator.Debugger import Debugger
from example.numLength.Tests.RangeTest import RangeTest

from rich.pretty import pprint


def instruction_to_command(instr: Instruction) -> str:
    """
    Преобразует Instruction обратно в строку команды 'CMD arg1 arg2 ...;'
    Использует CMD.<op>.name для имени команды.
    """

    # Получаем enum-команду по opCode
    cmd = CMD.from_value(instr.opCode)
    name = cmd.name  # <-- используется .name, как просили

    # Восстановление операндов — строго симметрично тому,
    # как они кодировались в run()
    match cmd:
        case CMD.NOP:
            return f"{name};"

        case CMD.LTM:
            # literal (4–14), addr_m_1 (14–24)
            return f"{name} {instr.literal} {instr.addr_m_1};"

        case CMD.MTR:
            return f"{name} {instr.addr_r_1} {instr.addr_m_1};"

        case CMD.RTR:
            return f"{name} {instr.addr_r_1} {instr.addr_r_2};"

        case CMD.SUB:
            return f"{name} {instr.addr_r_1} {instr.addr_r_2} {instr.addr_r_3};"

        case CMD.JUMP_LESS:
            return f"{name} {instr.addr_r_1} {instr.addr_r_2} {instr.addr_to_jump};"

        case CMD.MTRK:
            return f"{name} {instr.addr_r_1} {instr.addr_r_2};"

        case CMD.RTMK:
            return f"{name} {instr.addr_r_1} {instr.addr_r_2};"

        case CMD.JMP:
            return f"{name} {instr.addr_to_jump};"

        case CMD.SUM:
            return f"{name} {instr.addr_r_1} {instr.addr_r_2} {instr.addr_r_3};"

    raise ValueError(f"Unknown opcode: {instr.opCode}")


if __name__ == "__main__":
    with open("program.txt", "r") as file:
        program = file.read()
    translator = Translator(program)
    report = translator.run()
    print(*[(i.name, i.number_line) for i in report.debug_lines])
    translator.save()

    cpu = PipelineCPU(report.bin_code)
    pprint(cpu.IMEM)
    while not cpu.is_finished():
        cpu.step()
        pprint(cpu.RF)
        pprint(cpu.pc)
        pprint(cpu.DMEM[0:20])
        pprint([instruction_to_command(i) for i in [cpu.state.instruction_op1Fetch, cpu.state.instruction_op2Fetch, cpu.state.instruction_execute, cpu.state.instruction_writeback]])
        input()

    # print(CMD.MTR.name)
