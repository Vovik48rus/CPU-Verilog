from dataclasses import dataclass

from Simulator.Instruction import Instruction


@dataclass
class StateCPU:
    # ----- Decode 1 -----
    instruction_op1Fetch: Instruction
    # ----- Decode 2 -----
    instruction_op2Fetch: Instruction
    op1_from_decode1: int
    # ----- Execute -----
    instruction_execute: Instruction
    op1_from_decode2: int
    op2_from_decode2: int
    # ----- Writeback -----
    instruction_writeback: Instruction
    result_from_execute: int
    op1_from_execute: int
    op2_from_execute: int

    def __init__(self):
        self.instruction_op1Fetch = Instruction()
        self.instruction_op2Fetch = Instruction()
        self.instruction_writeback = Instruction()
        self.instruction_execute = Instruction()

        self.op1_from_decode1 = 0
        self.op1_from_decode2 = 0
        self.op2_from_decode2 = 0
        self.result_from_execute = 0
        self.op1_from_execute = 0
        self.op2_from_execute = 0
