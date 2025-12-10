from pathlib import Path

from Simulator.CPU import CPU
from example.numLength.Tests.RangeTest import RangeTest

if __name__ == "__main__":
    range_test = RangeTest[CPU](template_path=Path("example/numLength/Tests/numLength.txt"))
    range_test.run()
