package ecs

import "core:slice"

World :: struct {
  entities   : EntitiyContainer,
  components : ComponentContainer,
	archetypes : ArchetypeContainer,
  systems    : SystemContainer,
}

new_world :: proc() -> (world : World) {
  world.entities = entity_container_create()
  world.components = component_container_create()
	world.archetypes = new_archetype_container()
  world.systems = make(SystemContainer)

  return
}

free_world :: proc(
	using world : ^World,
) {
  entity_container_free(&entities)
  component_container_free(&components)
	free_archetype_container(&archetypes)
	free_system_container(&systems)
}

@private
add_entity_plain :: proc(
	using world : ^World,
) -> (id : EntityID) {
  id = entity_container_new(&entities)

  return
}

@private
@require_results
add_entity_archetype :: proc(
	using world : ^World,
	value 			: $T,
	archetype 	: Archetype(T),
	register  	: proc(^World, EntityID, T) -> bool,
) -> (id : EntityID, ok : bool) {
	archetype_container_set(&archetypes, archetype)

	id = entity_container_new(&entities)
	ok = register(world, id, value)

	return
}

add_entity :: proc {
	add_entity_plain,
	add_entity_archetype,
}

@require_results
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

@require_results
add_component :: proc(
	using world : ^World,
  id          : EntityID,
  component   : $T,
) -> (ok : bool) {
	ok = component_container_set(&components, id, component)

  return
}

@require_results
get_component :: proc(
	using world : ^World,
  $T          : typeid,
  id          : EntityID,
) -> (^T, bool) {
	if archetype, ok := archetype_container_get(archetypes, T, id); ok {
		return new_clone(archetype), true
	}

	ptr, ok := component_container_get(&components, T, id)
 
  return cast(^T)ptr, ok
}

@require_results
remove_component :: proc(
  using world : ^World,
  $T          : typeid,
  id          : EntityID,
) -> (ok : bool){
  ok = component_container_delete(&components, T, id)

  return
}

@require_results
add_archetype :: proc(
	using world : ^World,
  construct 	: proc(map[typeid]rawptr) -> $T,
	types     	: ..typeid,
) -> (ok : bool) {

	ok = archetype_container_set(&archetypes, archetype(construct, ..types))

	return
}

add_system :: proc(
	using world : ^World,
	system 			: System,
) {
	system_container_register(&systems, system)
}

update :: proc(
	using world : ^World,
) {
	system_container_execute(&systems, &components)
}

