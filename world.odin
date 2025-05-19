package ecs

World :: struct {
  entities    : EntitiyContainer,
  componenets : ComponentContainer,
  systems     : SystemContainer,
}

new_world :: proc() -> (world : World) {
  world.entities = entity_container_create()
  world.componenets = component_container_create()
  world.systems = make(SystemContainer)

  return
}

free_world :: proc(
  using world : ^World,
) {
  entity_container_free(&entities)
  component_container_free(&componenets)
  delete(systems)
}

new_entity :: proc(
  using world : ^World,
) -> (id : EntityID) {
  id = entity_container_new(&entities)

  return
}

delete_entity :: proc(
  using world : ^World,
  id          : EntityID,
) -> (ok : bool) {
  if ok = entity_container_delete(&entities, id); ok {
    for key, _ in componenets {
      component_container_delete(&componenets, key, id)
    }
  }

  return
}

add_component :: proc(
  using world : ^World,
  id          : EntityID,
  component   : $T,
) -> bool {
  return component_container_set(&componenets, id, component)
}

get_component :: proc(
  using world : ^World,
  $T          : typeid,
  id          : EntityID,
) -> (^T, bool) {
  return component_container_get(&componenets, T, id)
}

remove_component :: proc(
  using world : ^World,
  $T          : typeid,
  id          : EntityID,
) -> (ok : bool){
  ok = component_container_delete(&componenets, T, id)

  return
}

@(private)
add_component_system :: proc(
  using world : ^World,
  name : string,
  action : proc(res : QueryResult),
  type : typeid,
) {
  system_container_register(&systems, ComponentSystem {
    name = name,
    type = type,
    action = action,
  })
}

@(private)
add_archetype_system :: proc(
  using world : ^World,
  name : string,
  action : proc(QueryResult),
  types : ..typeid,
) {
  system := ArchetypeSystem{
    name = name,
    action = action,
  }
  system.types = make([]typeid, len(types))
  i : int
  for t in types {
    system.types[i] = t
    i += 1
  }

  system_container_register(&systems, system)
}

add_system :: proc {
  add_component_system,
  add_archetype_system,
}

query_component :: proc(
  using world : ^World,
  type : typeid,
) -> (res : [dynamic]ComponentQueryResult) {
  res = make([dynamic]ComponentQueryResult)

  pool := &componenets[type]
  for key, val in &pool.components {
    append_elem(&res, ComponentQueryResult {
      id = key,
      value = val,
    })
  }

  return
}

query_archetype :: proc(
  using world : ^World,
  types : ..typeid,
) -> (res : [dynamic]ArchetypeQueryResult) {
  res = make([dynamic]ArchetypeQueryResult)

  ids := component_container_archetypes(&componenets, ..types)
  defer delete(ids)

  for id in ids {
    archetype := ArchetypeQueryResult {
      id = id,
    }
    archetype.values = make(map[typeid]rawptr, len(types))

    for type, index in types {
      ptr, _ := component_container_get(&componenets, type, id)
      archetype.values[type] = ptr
    }

    append(&res, archetype)
  }

  return
}

update :: proc(
  using world : ^World,
) {
  for key, value in systems {
    switch v in value {
    case ComponentSystem:
      res := query_component(world, v.type)
      defer delete(res)

      for r in res {
        v.action(r)
      }
    case ArchetypeSystem:
      res := query_archetype(world, ..v.types)
      defer {
        for i := 0; i < len(res); i += 1 {
          delete(res[i].values)
        }

        delete(res)
      }
      
      for r in res {
        v.action(r)
      }
    case BaseSystem:
      panic("ERROR")
    }
  }
}

