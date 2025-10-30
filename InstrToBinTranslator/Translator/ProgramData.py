from math import log2


def clog2(SIZE):
    return int(log2(SIZE)) if 2 ** int(log2(SIZE)) == SIZE else int(log2(SIZE)) + 1


def int_to_bin(value: int, size):
    if len(bin(value)[2::]) > size:
        print(f"Warning {value} is too big, max size is {size}")
    return bin(value)[2:].rjust(size, '0')


class ProgramData:
    CMD_SIZE = 24
    CMD_MEM_SIZE = 1024
    LIT_SIZE = 10
    DATA_MEM_SIZE = 1024
    RF_SIZE = 16
    ADDR_CMD_MEM_SIZE = clog2(DATA_MEM_SIZE)
    ADDR_DATA_MEM_SIZE = clog2(DATA_MEM_SIZE)
    ADDR_RF_SIZE = clog2(RF_SIZE)
    KOP_SIZE = 4
