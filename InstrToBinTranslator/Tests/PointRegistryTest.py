from Simulator.ParseProgram.ParseProgram import ParseProgram
from Simulator.ParseProgram.PointRegistry import PointRegistry

with open("program.txt", "r") as file:
    program = file.read()
    parse_program = ParseProgram(program)
    point_registry = PointRegistry(parse_program)
    points = point_registry.points
    for point in points:
        print(point.name, point.condition)
    print(point_registry.has_point(points[1].name))
    print(point_registry.has_point(points[1].name + '123'))
    print(point_registry.get_point(points[1].name).name)
    for i in range(len(point_registry.lines)):
        if point_registry.has_point_at_line(i):
            print(i, point_registry.get_point_by_line_number(i).name)
