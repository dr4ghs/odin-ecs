all:
	@mkdir -p bin
	odin build . -out:bin/ecs-test && ./bin/ecs-test

debug:
	@mkdir -p bin
	odin build . -debug -out:bin/ecs-test && valgrind ./bin/ecs-test

