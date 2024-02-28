# default recipe to display help
default:
	@just --list

# builds the project
build:
	zig build -Doptimize=ReleaseSafe run

# runs the project
run:
	zig build -Doptimize=ReleaseSafe run
