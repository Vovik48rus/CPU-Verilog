from enum import Enum


class CMD(Enum):
    NOP = 0
    LTM = 1
    MTR = 2
    RTR = 3
    SUB = 4
    JUMP_LESS = 5
    MTRK = 6
    RTMK = 7
    JMP = 8
    SUM = 9

    @classmethod
    def get_command(cls, s: str):
        if s == 'NOP':
            return cls.NOP
        elif s == 'LTM':
            return cls.LTM
        elif s == 'MTR':
            return cls.MTR
        elif s == 'RTR':
            return cls.RTR
        elif s == 'SUB':
            return cls.SUB
        elif s == 'JUMP_LESS':
            return cls.JUMP_LESS
        elif s == 'MTRK':
            return cls.MTRK
        elif s == 'RTMK':
            return cls.RTMK
        elif s == 'JMP':
            return cls.JMP
        elif s == 'SUM':
            return cls.SUM
        return None

    @classmethod
    def from_value(cls, value: int):
        for c in cls:
            if c.value == value:
                return c
        return None
