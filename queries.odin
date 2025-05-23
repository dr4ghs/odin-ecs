package ecs

QueryEntry :: struct {
	type   : typeid,
	filter : proc(EntityID, rawptr) -> bool,
}

has :: proc(
	type : typeid,
  filter := proc(_: EntityID, _: rawptr) -> bool {
    return true
  },
) -> (entry : QueryEntry) {
	entry.type = type
  entry.filter = filter

	return
}

QueryResult :: distinct map[EntityID]map[typeid]rawptr

get :: proc(
	result : QueryResult,
	$T     : typeid,
	id     : EntityID,
) -> (val : ^T, ok : bool) {
	components := result[id] or_return
	ptr := components[T] or_return

	val = cast(^T)ptr
	ok = true

	return
}

Query :: distinct map[typeid]proc(EntityID, rawptr) -> bool

query :: proc(
	entries : ..QueryEntry,
) -> (q : Query) {
	q = make(Query)

	for e in entries {
		q[e.type] = e.filter
	}

	return
}

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

