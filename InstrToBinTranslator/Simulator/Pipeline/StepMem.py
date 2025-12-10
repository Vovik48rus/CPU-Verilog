class StepMem:
    def __init__(self, mem: list[int]):
        self.mem: list[int] = mem
        self.write_indexes: list[int] = []  # адреса записей
        self.read_indexes: list[int] = []  # адреса чтений

    def step(self):
        """Начать новый такт — очистить списки чтения/записи."""
        self.write_indexes.clear()
        self.read_indexes.clear()

    def __getitem__(self, index: int) -> int:
        """Чтение mem[index]"""
        if index in self.read_indexes:
            raise BlockingIOError(
                f"Чтение невозможно: регистр уже был записан в этом такте. "
                f"{index=}, value={self.mem[index]}"
            )
        self.read_indexes.append(index)
        return self.mem[index]

    def __setitem__(self, index: int, value: int) -> None:
        """Запись mem[index] = value"""
        if index in self.read_indexes:
            raise BlockingIOError(
                f"Запись невозможна: регистр уже был прочитан в этом такте. "
                f"{index=}, current_value={self.mem[index]}, try_to_set={value}"
            )
        elif index in self.write_indexes:
            raise BlockingIOError(
                f"Запись невозможна: регистр уже был записан в этом такте. "
                f"{index=}, current_value={self.mem[index]}, try_to_set={value}"
            )

        self.write_indexes.append(index)
        self.mem[index] = value

    def __len__(self):
        return len(self.mem)

    def __iter__(self):
        for i in range(len(self.mem)):
            yield self[i]

    def __repr__(self):
        return f"StepMem({self.mem})"
