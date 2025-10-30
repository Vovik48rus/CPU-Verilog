from rich.console import Console
from rich.table import Table
from rich import print

console = Console()

table = Table(show_header=True, header_style="bold blue")
table.add_column("Command", justify="center")
table.add_column("Description", justify="center")

table.add_row(*[])
table.add_row(*[])

print(table)