package ecs

import "core:slice"

System :: struct {
	query : Query,
	action : proc(EntityID, QueryResult),
	result : QueryResult,
}

system :: proc(
	query : Query,
	action : proc(EntityID, QueryResult),
) -> (s : System) {
	s.query = query
	s.action = action

	return
}

@(private)
SystemContainer :: distinct [dynamic]System

@(private)
free_system_container :: proc(
	container : ^SystemContainer,
) {
	for system in container {
		delete(system.query)

		for id, _ in system.result {
			delete(system.result[id])
		}
		delete(system.result)
	}

	delete(container^)
}

@(private)
system_container_register :: proc(
  container : ^SystemContainer,
  data : System,
) {
	append(container, data)

	return
}

import "core:fmt"

@private
system_container_execute :: proc(
	systems  	 : ^SystemContainer,
	components : ^ComponentContainer,
) {
	for &system in systems {
		ids := component_container_query(components, system.query)
		defer delete(ids)

		types, err := slice.map_keys(system.query)
		defer delete(types)
		if err != nil {
			panic("ERROR: cannot extract types from query")
		}

		if system.result == nil {
			fmt.println("CACHING QUERY RESULT")
			system.result = query_execute(components, ids, types)
		}

		for id, _ in system.result {
			system.action(id, system.result)
		}
	}
}

