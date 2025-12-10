from typing import List

from Simulator.CPU import CPU
from Simulator.Instruction import Instruction
from .StateCPU import StateCPU


class PipelineCPU(CPU):
    def __init__(self, program: str) -> None:
        super().__init__(program)
        self.state: StateCPU = StateCPU() # для wire
        self.next_state: StateCPU = StateCPU() # для wire

        del self.res
        del self.op2
        del self.op1
        del self.instruction
        del self.command

    def read_memory(self, program: str) -> List[str]:
        return super().read_memory(program)

    def step(self) -> None:
        self.command: str = self._fetch()
        instruction: Instruction = self._decode(self.command)
        self.next_state.instruction_op1Fetch = instruction

        op1: int = self._op1Fetch(self.state.instruction_op1Fetch)
        self.next_state.op1_from_decode1 = op1
        self.next_state.instruction_op2Fetch = self.state.instruction_op1Fetch

        op2: int = self._op2Fetch(self.next_state.instruction_op2Fetch)
        self.next_state.op2_from_decode2 = op2
        self.next_state.op1_from_decode2 = self.state.op1_from_decode1
        self.next_state.instruction_execute = self.state.instruction_op2Fetch

        res: int = self._execute(self.state.instruction_execute, self.state.op1_from_decode2, self.state.op2_from_decode2)
        self.next_state.op1_from_execute = self.state.op1_from_decode2
        self.next_state.op2_from_execute = self.state.op2_from_decode2
        self.next_state.result_from_execute = res
        self.next_state.instruction_writeback = self.state.instruction_execute

        self._writeback(self.state.instruction_writeback, self.state.result_from_execute)

        self._program_counter_next(self.state.instruction_writeback, self.state.result_from_execute)

        self.state = self.next_state
        self.next_state = StateCPU()


    def run(self):
        raise NotImplementedError()

    def is_finished(self):
        return False

    # def _fetch(self) -> str:
    #     return super()._fetch()
    #
    # def _decode(self, command: str) -> Instruction:
    #     raise NotImplementedError()
    #
    # def _op1Fetch(self, instruction: Instruction) -> int:
    #     raise NotImplementedError()
    #
    # def _op2Fetch(self, instruction: Instruction) -> int:
    #     raise NotImplementedError()
    #
    # def _execute(self, instruction: Instruction, op1: int, op2: int) -> int:
    #     raise NotImplementedError()
    #
    # def _writeback(self, instruction: Instruction, res: int) -> None:
    #     raise NotImplementedError()
