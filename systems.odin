package ecs

QueryResult ::union {
  ComponentQueryResult,
  ArchetypeQueryResult,
}

ComponentQueryResult :: struct {
  id    : EntityID,
  value : rawptr,
}

ArchetypeQueryResult :: struct {
  id     : EntityID,
  values : map[typeid]rawptr,
}

System :: union {
  BaseSystem,
  ComponentSystem,
  ArchetypeSystem,
}

BaseSystem :: struct {
  name    : string,
  action  : proc(QueryResult),
  next    : ^string,
}

ComponentSystem :: struct {
  using _ : BaseSystem,
  type    : typeid,
}

ArchetypeSystem :: struct {
  using _ : BaseSystem,
  types   : []typeid,
}

@(private)
SystemContainer :: distinct map[string]System

@(private)
system_container_free :: proc(
	container : ^SystemContainer,
) {
	for key, _ in container {
		#partial switch &v in container[key] {
		case ArchetypeSystem:
			delete(v.types)
		}
	}

	delete(container^)
}

@(private)
system_container_register :: proc(
  container : ^SystemContainer,
  data : System,
) -> (ok : bool) {
  key : string

  switch v in data {
  case ComponentSystem:
    key = v.name
  case ArchetypeSystem:
    key = v.name
  case BaseSystem:
    panic("ERROR: cannot register BaseSystem")
  }

  if _, hit := container[key]; !hit {
    container[key] = data
    ok = true
  }

  return
}

