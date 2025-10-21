from math import log2
from CMD import CMD


def clog2(SIZE):
    return int(log2(SIZE)) if 2 ** int(log2(SIZE)) == SIZE else int(log2(SIZE)) + 1


CMD_SIZE = 24
CMD_MEM_SIZE = 1024
LIT_SIZE = 10
DATA_MEM_SIZE = 1024
RF_SIZE = 16
ADDR_CMD_MEM_SIZE = clog2(DATA_MEM_SIZE)
ADDR_DATA_MEM_SIZE = clog2(DATA_MEM_SIZE)
ADDR_RF_SIZE = clog2(RF_SIZE)
KOP_SIZE = 4


def int_to_bin(value: int, size):
    if len(bin(value)[2::]) > size:
        print(f"Warning {value} is too big, max size is {size}")
    return bin(value)[2:].rjust(size, '0')


with open("insertion_sort9.txt", encoding="UTF-8") as f:
    bin_code = ""
    for i in f.read().replace(";\n", ";").split(';')[:-1:]:
        operands_lst = []
        if len(i.split(' ', maxsplit=1)) > 1:
            command_str, operands_str = i.split(' ', maxsplit=1)
            operands_lst.extend(list(map(int, operands_str.split(', '))))
        else:
            command_str = i

        command = CMD.get_command(command_str)
        s = int_to_bin(command.value, KOP_SIZE)

        print(command.value, *operands_lst)

        # print(command, operands_lst)
        match command:
            case CMD.NOP:
                pass
            case CMD.LTM:
                s += int_to_bin(operands_lst[1], LIT_SIZE)
                s += int_to_bin(operands_lst[0], ADDR_DATA_MEM_SIZE)
            case CMD.MTR:
                s += int_to_bin(operands_lst[1], ADDR_RF_SIZE)
                s += '0' * (LIT_SIZE - ADDR_RF_SIZE)
                s += int_to_bin(operands_lst[0], ADDR_DATA_MEM_SIZE)
            case CMD.RTR:
                s += int_to_bin(operands_lst[0], ADDR_RF_SIZE)
                s += int_to_bin(operands_lst[1], ADDR_RF_SIZE)
            case CMD.SUB:
                s += int_to_bin(operands_lst[0], ADDR_RF_SIZE)
                s += int_to_bin(operands_lst[1], ADDR_RF_SIZE)
                s += int_to_bin(operands_lst[2], ADDR_RF_SIZE)
            case CMD.JUMP_LESS:
                s += int_to_bin(operands_lst[0], ADDR_RF_SIZE)
                s += int_to_bin(operands_lst[1], ADDR_RF_SIZE)
                s += int_to_bin(operands_lst[2], ADDR_CMD_MEM_SIZE)
            case CMD.MTRK:
                s += int_to_bin(operands_lst[0], ADDR_RF_SIZE)
                s += int_to_bin(operands_lst[1], ADDR_RF_SIZE)
            case CMD.RTMK:
                s += int_to_bin(operands_lst[0], ADDR_RF_SIZE)
                s += int_to_bin(operands_lst[1], ADDR_RF_SIZE)
            case CMD.JMP:
                s += "0" * (2 * ADDR_RF_SIZE)
                s += int_to_bin(operands_lst[0], ADDR_CMD_MEM_SIZE)
            case CMD.SUM:
                s += int_to_bin(operands_lst[0], ADDR_RF_SIZE)
                s += int_to_bin(operands_lst[1], ADDR_RF_SIZE)
                s += int_to_bin(operands_lst[2], ADDR_RF_SIZE)

        if len(s) > CMD_SIZE:
            raise Exception(f"Command {command} too big, max size is {CMD_SIZE}")
        # print(s)
        bin_code += s.ljust(CMD_SIZE, '0') + '\n'
    bin_code = bin_code[:-1:]

    with open("program.mem", "w", encoding="UTF-8") as f2:
        f2.write(bin_code)
