from pathlib import Path
from typing import TypeVar, Generic, Type
from rich.console import Console
from rich.text import Text

from Simulator.CPU import CPU
from Translator.Translator import Translator

_CPU = TypeVar('_CPU', bound=CPU)

class RangeTest(Generic[_CPU]):
    _cpu_class: Type[_CPU] = CPU

    def __class_getitem__(cls, item):
        class SpecializedRangeTest(cls):
            _cpu_class = item

        return SpecializedRangeTest

    def __init__(self, template_path: Path = Path("numLength.txt")):
        with open(template_path, "r", encoding="utf-8") as f:
            self.program = f.read()

    def _run_test(self, value: int):
        program = self.program.format(value=value)
        translator = Translator(program)
        report = translator.run()
        cpu = self._cpu_class(report.bin_code)
        cpu.run()
        return cpu.RF[4]

    def run(self):
        console = Console()
        passed = 0
        failed = 0

        for i in range(0, 2 ** 10):
            expected = len(str(abs(i)))
            result = self._run_test(i)
            ok = result == expected

            if ok:
                status = Text("OK", style="bold green")
                passed += 1
            else:
                status = Text("FAIL", style="bold red")
                failed += 1

            line = Text()
            line.append(f"[{i:04}] ", style="bold cyan")
            line.append(f"expected={expected}, got={result} — ")
            line.append(status)

            console.print(line)

        # Итоги
        console.print()
        console.rule("ИТОГИ")
        console.print(Text(f"Успешно: {passed}", style="bold green"))
        console.print(Text(f"Провалы: {failed}", style="bold red"))
        console.print(Text(f"Всего: {passed + failed}", style="bold white"))
        console.rule()
