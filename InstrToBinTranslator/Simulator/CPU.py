from typing import List
from CMD import CMD
from .Instruction import Instruction


class CPU:
    def __init__(self, program: str) -> None:
        self.res = None
        self.op2 = None
        self.op1 = None
        self.instruction = None
        self.command = None
        self._pc: int = 0
        self._IMEM: List[str] = []
        self._DMEM: List[int] = [0] * 1024
        self._RF: List[int] = [0] * 17
        self._RF[1] = 1
        self._IMEM = self.read_memory(program)

    @property
    def pc(self) -> int:
        return self._pc

    @pc.setter
    def pc(self, value: int) -> None:
        self._pc = value

    @property
    def IMEM(self) -> List[str]:
        return self._IMEM

    @IMEM.setter
    def IMEM(self, value: List[str]) -> None:
        self._IMEM = value

    @property
    def DMEM(self) -> List[int]:
        return self._DMEM

    @DMEM.setter
    def DMEM(self, value: List[int]) -> None:
        self._DMEM = value

    @property
    def RF(self) -> List[int]:
        return self._RF

    @RF.setter
    def RF(self, value: List[int]) -> None:
        self._RF = value

    def read_memory(self, program: str) -> List[str]:
        instrSet: List[str] = []
        for line in program.split('\n'):
            instrSet.append(line)
        return instrSet

    def step(self) -> None:
        self.command: str = self._fetch()
        self.instruction: Instruction = self._decode(self.command)
        self.op1: int = self._op1Fetch(self.instruction)
        self.op2: int = self._op2Fetch(self.instruction)
        self.res: int = self._execute(self.instruction, self.op1, self.op2)
        self._writeback(self.instruction, self.res)

    def run(self):
        while not self.is_finished():
            self.step()

    def is_finished(self):
        return self._pc >= len(self._IMEM)

    def _fetch(self) -> str:
        command: str = self._IMEM[self._pc].strip()
        return command

    def _decode(self, command: str) -> Instruction:
        instruction = Instruction()
        instruction.opCode = int(command[:4], 2)
        instruction.literal = int(command[4:14], 2)
        instruction.addr_r_1 = int(command[4:8], 2)
        instruction.addr_r_2 = int(command[8:12], 2)
        instruction.addr_r_3 = int(command[12:16], 2)
        instruction.addr_m_1 = int(command[14:24], 2)
        instruction.addr_to_jump = int(command[12:22], 2)
        return instruction

    def _op1Fetch(self, instruction: Instruction) -> int:
        match instruction.opCode:
            case CMD.NOP.value:
                return 0
            case CMD.LTM.value:
                return instruction.literal
            case CMD.MTR.value:
                return self._DMEM[instruction.addr_m_1]
            case CMD.RTR.value | CMD.MTRK.value:
                return self._RF[instruction.addr_r_2]
            case CMD.SUB.value | CMD.JUMP_LESS.value | CMD.RTMK.value | CMD.SUM.value:
                return self._RF[instruction.addr_r_1]
            case CMD.JMP.value:
                return instruction.addr_to_jump
            case _:
                raise Exception(f"Некорректный код инструкции: {instruction.opCode}")

    def _op2Fetch(self, instruction: Instruction) -> int:
        match instruction.opCode:
            case (CMD.NOP.value | CMD.LTM.value | CMD.MTR.value |
                  CMD.RTR.value | CMD.MTRK.value | CMD.RTMK.value | CMD.JMP.value):
                return 0
            case CMD.SUB.value | CMD.JUMP_LESS.value | CMD.SUM.value:
                return self._RF[instruction.addr_r_2]
            case _:
                raise Exception(f"Некорректный код инструкции: {instruction.opCode}")

    def _execute(self, instruction: Instruction, op1: int, op2: int) -> int:
        if instruction.opCode == CMD.NOP.value:
            return 0
        elif instruction.opCode in {CMD.LTM.value, CMD.MTR.value, CMD.RTR.value,
                                    CMD.MTRK.value, CMD.RTMK.value, CMD.JMP.value}:
            return op1
        elif instruction.opCode == CMD.SUB.value:
            return op1 - op2
        elif instruction.opCode == CMD.JUMP_LESS.value:
            return int(op1 < op2)
        elif instruction.opCode == CMD.SUM.value:
            return op1 + op2
        else:
            raise Exception("Некорректный код инструкции: " + str(instruction.opCode))

    def _writeback(self, instruction: Instruction, res: int) -> None:
        match instruction.opCode:
            case CMD.NOP.value:
                self._pc += 1
            case CMD.LTM.value:
                self._DMEM[instruction.addr_m_1] = res
                self._pc += 1
            case CMD.MTR.value | CMD.RTR.value:
                self._RF[instruction.addr_r_1] = res
                self._pc += 1
            case CMD.SUB.value | CMD.SUM.value:
                self._RF[instruction.addr_r_3] = res
                self._pc += 1
            case CMD.JUMP_LESS.value:
                if not res:
                    self._pc = instruction.addr_to_jump
                else:
                    self._pc += 1
            case CMD.MTRK.value:
                self._RF[instruction.addr_r_1] = self._DMEM[res]
                self._pc += 1
            case CMD.RTMK.value:
                self._DMEM[res] = self._RF[instruction.addr_r_2]
                self._pc += 1
            case CMD.JMP.value:
                self._pc = res
            case _:
                raise Exception(f"Некорректный код инструкции: {instruction.opCode}")
