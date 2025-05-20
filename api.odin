package ecs

// =============================================================================
// QUERIES
// 

query :: proc(
	entries : ..QueryEntry,
) -> (q : Query) {
	q = make(Query)

	for e in entries {
		q[e.type] = e.filter
	}

	return
}

with :: proc(
	type : typeid,
  filter := proc(_: EntityID, _: rawptr) -> bool {
    return true
  },
) -> (entry : QueryEntry) {
	entry.type = type
  entry.filter = filter

	return
}

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

