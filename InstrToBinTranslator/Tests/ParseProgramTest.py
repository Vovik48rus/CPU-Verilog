from Simulator.ParseProgram.ParseProgram import ParseProgram

with open("program.txt", "r") as file:
    program = file.read()
    parse_program = ParseProgram(program)
    print(parse_program)
