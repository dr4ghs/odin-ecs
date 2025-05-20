package ecs

import "core:slice"

World :: struct {
  entities    : EntitiyContainer,
  components : ComponentContainer,
  systems     : SystemContainer,
}

new_world :: proc() -> (world : World) {
  world.entities = entity_container_create()
  world.components = component_container_create()
  world.systems = make(SystemContainer)

  return
}

free_world :: proc(
  using world : ^World,
) {
  entity_container_free(&entities)
  component_container_free(&components)
	free_system_container(&systems)
}

add_entity :: proc(
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
    for key, _ in components {
      component_container_delete(&components, key, id)
    }
  }

  return
}

add_component :: proc(
  using world : ^World,
  id          : EntityID,
  component   : $T,
) -> bool {
  return component_container_set(&components, id, component)
}

get_component :: proc(
  using world : ^World,
  $T          : typeid,
  id          : EntityID,
) -> (^T, bool) {
  return component_container_get(&components, T, id)
}

remove_component :: proc(
  using world : ^World,
  $T          : typeid,
  id          : EntityID,
) -> (ok : bool){
  ok = component_container_delete(&components, T, id)

  return
}

add_system :: proc(
	using world : ^World,
	system : System,
) {
	system_container_register(&world.systems, system)
}

update :: proc(
  using world : ^World,
) {
	system_container_execute(&systems, &components)
}

