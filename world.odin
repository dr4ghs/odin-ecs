package ecs

import "core:slice"

world : World

World :: struct {
  entities    : EntitiyContainer,
  components : ComponentContainer,
  systems     : SystemContainer,
}

@init
ecs_init :: proc() {
  world.entities = entity_container_create()
  world.components = component_container_create()
  world.systems = make(SystemContainer)

  return
}

@fini
ecs_free :: proc() {
	using world

  entity_container_free(&entities)
  component_container_free(&components)
	free_system_container(&systems)
}

add_entity :: proc() -> (id : EntityID) {
	using world

  id = entity_container_new(&entities)

  return
}

delete_entity :: proc(
  id          : EntityID,
) -> (ok : bool) {
	using world

  if ok = entity_container_delete(&entities, id); ok {
    for key, _ in components {
      component_container_delete(&components, key, id)
    }
  }

  return
}

add_component :: proc(
  id          : EntityID,
  component   : $T,
) -> bool {
	using world

  return component_container_set(&components, id, component)
}

get_component :: proc(
  $T          : typeid,
  id          : EntityID,
) -> (^T, bool) {
	using world

  return component_container_get(&components, T, id)
}

remove_component :: proc(
  $T          : typeid,
  id          : EntityID,
) -> (ok : bool){
  using world

  ok = component_container_delete(&components, T, id)

  return
}

add_system :: proc(
	system : System,
) {
	using world

	system_container_register(&world.systems, system)
}

update :: proc() {
	using world

	system_container_execute(&systems, &components)
}

