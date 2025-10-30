class ParseCommandProgram:
    def __init__(self, program):
        self.program = program
        self._parse_program = None

    def get_parse_program(self):
        pass

    @property
    def parse_program(self):
        if self._parse_program is None:
            self._do_parse_program()
        return self._parse_program

    def _do_parse_program(self):
        pass
