from pathlib import Path

from Translator.Translator import Translator
from Simulator.CPU import CPU
from Simulator.Debugger import Debugger
from example.numLength.Tests.RangeTest import RangeTest

if __name__ == "__main__":
    with open("example/numLength/numLength.txt", "r") as file:
        program = file.read()
    translator = Translator(program)
    report = translator.run()
    print(*[(i.name, i.number_line) for i in report.debug_lines])
    translator.save()
    cpu = CPU(report.bin_code)
    debug = Debugger(cpu, report.debug_lines, program, True)
    debug.run()

    # range_test = RangeTest[CPU](template_path=Path("example/numLength/Tests/numLength.txt"))
    # range_test.run()
