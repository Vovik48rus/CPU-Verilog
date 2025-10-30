from CMD import CMD
from INSTR import Instruction


def ReadMemory(input_filename):
    global PC
    instrSet = []
    try:
        with open(input_filename, 'r', encoding='utf-8') as in_file:
            for line in in_file:
                instrSet.append(line)
        return instrSet

    except FileNotFoundError:
        print(f"Файл {input_filename} не найден!")
    except Exception as e:
        print(f"Ошибка при обработке файла: {e}")


def Fetch(PC):
    global IMEM
    command = IMEM[PC].strip()
    return command


def Decode(command):
    instruction = Instruction()
    instruction.opCode = int(command[:4], 2)
    instruction.literal = int(command[4:14], 2)
    instruction.addr_r_1 = int(command[4:8], 2)
    instruction.addr_r_2 = int(command[8:12], 2)
    instruction.addr_r_3 = int(command[12:16], 2)
    instruction.addr_m_1 = int(command[14:24], 2)
    instruction.addr_to_jump = int(command[14:24], 2)
    return instruction


def Op1Fetch(instruction):
    global DMEM, RF
    if instruction.opCode == CMD.NOP.value:
        return 0
    elif instruction.opCode == CMD.LTM.value:
        return instruction.literal
    elif instruction.opCode == CMD.MTR.value:
        return DMEM[instruction.addr_m_1]
    elif instruction.opCode in {CMD.RTR.value, CMD.MTRK.value}:
        return RF[instruction.addr_r_2]
    elif instruction.opCode in {CMD.SUB.value, CMD.JUMP_LESS.value,
                                CMD.RTMK.value, CMD.SUM.value}:
        return RF[instruction.addr_r_1]
    elif instruction.opCode == CMD.JMP.value:
        return instruction.addr_to_jump
    else:
        raise Exception("Некорректный код инструкции: " +
                        str(instruction.opCode))


def Op2Fetch(instruction):
    global RF
    if instruction.opCode in {CMD.NOP.value, CMD.LTM.value, CMD.MTR.value,
                              CMD.RTR.value, CMD.MTRK.value, CMD.RTMK.value,
                              CMD.JMP.value}:
        return 0
    elif instruction.opCode in {CMD.SUB.value, CMD.JUMP_LESS.value,
                                CMD.SUM.value}:
        return RF[instruction.addr_r_2]
    else:
        raise Exception("Некорректный код инструкции: " +
                        str(instruction.opCode))


def Execute(instruction, op1, op2):
    global RF
    if instruction.opCode == CMD.NOP.value:
        return 0
    elif instruction.opCode in {CMD.LTM.value, CMD.MTR.value, CMD.RTR.value,
                                CMD.MTRK.value, CMD.RTMK.value, CMD.JMP.value}:
        return op1
    elif instruction.opCode == CMD.SUB.value:
        return op1 - op2
    elif instruction.opCode == CMD.JUMP_LESS.value:
        return op1 < op2
    elif instruction.opCode == CMD.SUM.value:
        return op1 + op2
    else:
        raise Exception("Некорректный код инструкции: " +
                        str(instruction.opCode))


def Writeback(instruction, res):
    global PC, DMEM, RF
    if instruction.opCode == CMD.NOP.value:
        PC += 1
    elif instruction.opCode == CMD.LTM.value:
        DMEM[instruction.addr_m_1] = res
        PC += 1
    elif instruction.opCode in {CMD.MTR.value, CMD.RTR.value}:
        RF[instruction.addr_r_1] = res
        PC += 1
    elif instruction.opCode in {CMD.SUB.value, CMD.SUM.value}:
        RF[instruction.addr_r_3] = res
        PC += 1
    elif instruction.opCode == CMD.JUMP_LESS.value:
        if not res:
            PC = instruction.addr_to_jump
        else:
            PC += 1
    elif instruction.opCode == CMD.MTRK.value:
        RF[instruction.addr_r_1] = DMEM[res]
        PC += 1
    elif instruction.opCode == CMD.RTMK.value:
        DMEM[res] = RF[instruction.addr_r_2]
        PC += 1
    elif instruction.opCode == CMD.JMP.value:
        PC = res
    else:
        raise Exception("Некорректный код инструкции: " +
                        str(instruction.opCode))


PC = 0
IMEM = ReadMemory('program.mem')
DMEM = [0]*1024
RF = [0]*17
RF[1] = 1
while PC < len(IMEM):
    command = Fetch(PC)
    instruction = Decode(command)
    op1 = Op1Fetch(instruction)
    op2 = Op2Fetch(instruction)
    res = Execute(instruction, op1, op2)
    Writeback(instruction, res)
print("DONE")
