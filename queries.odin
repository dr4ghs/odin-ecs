package ecs

Query :: distinct map[typeid]proc(EntityID, rawptr) -> bool

QueryEntry :: struct {
	type   : typeid,
	filter : proc(EntityID, rawptr) -> bool,
}

QueryResult :: distinct map[EntityID]map[typeid]rawptr

@(private)
query_execute :: proc(
  container : ^ComponentContainer,
	ids   : []EntityID,
  types : []typeid,
) -> (res : QueryResult) {
	res = make(QueryResult)

	for id in ids {
		res[id] = make(map[typeid]rawptr)

		components := &res[id]
		for type in types {
			ptr, _ := component_container_get(container, type, id)
			components[type] = ptr
		}
	}

  return
}

