package ecs

import "base:runtime"

import "core:mem"
import "core:reflect"
import "core:slice"

@(private)
ComponentPool :: struct($T : typeid) {
	components: map[EntityID]T,
}

@(private = "file")
component_pool_create :: proc(
  $T: typeid,
) -> (pool: ComponentPool(T)) {
	pool.components = make(map[EntityID]T)

	return
}

@(private = "file")
component_pool_free :: proc(
  using pool: ^ComponentPool($T),
) {
  for key, _ in components {
    free(components[key])
  }

	delete(components)
}

@(private = "file")
component_pool_get :: proc(
	using pool: ^ComponentPool($T),
	id: EntityID,
) -> (
	component: ^T,
	ok: bool,
) {
  val := components[id] or_return

	ok = true
  component = &val

	return
}

@(private = "file")
component_pool_set :: proc(
  using pool: ^ComponentPool($T), 
  id: EntityID, 
  component: T,
) -> (ok: bool) {
	if _, hit := components[id]; hit {
		return
	}

	ok = true
	components[id] = component

	return
}

@(private = "file")
component_pool_delete :: proc(
  using pool : ^ComponentPool($T),
  id : EntityID,
) -> (ok : bool) {
  if _, ok = components[id]; ok {
    free(components[id])
    delete_key(&components, id)
  }

  return
}

@(private)
ComponentContainer :: distinct map[typeid]ComponentPool(rawptr)

@(private)
component_container_create :: proc() -> (container : ComponentContainer) {
  container = make(ComponentContainer)

  return
}

@(private)
component_container_free :: proc(
  container : ^ComponentContainer,
) {
  for key, _ in container {
    component_pool_free(&container[key])
  }

  delete(container^)
}

@(private)
component_container_get :: proc(
  container : ^ComponentContainer,
  type : typeid,
  id : EntityID,
) -> (rawptr, bool) {
  if pool, hit := &container[type]; hit {
    val, ok := pool.components[id]

    return val, ok
  }

  return nil, false
}

@(private)
component_container_set :: proc(
  container : ^ComponentContainer,
  id : EntityID,
  component : $T,
) -> (ok: bool) {
  if _, hit := container[T]; !hit {
    container[T] = transmute(ComponentPool(rawptr))component_pool_create(T)
  }

  pool := &container[T]
  ok = component_pool_set(pool, id, new_clone(component))

  return
}

@(private)
component_container_delete :: proc(
  container : ^ComponentContainer,
  type : typeid,
  id : EntityID,
) -> (ok : bool) {
  _ = container[type] or_return

  ok = component_pool_delete(&container[type], id)

  return
}

@(private)
component_container_query :: proc(
  container : ^ComponentContainer,
  query : Query,
) -> (s : []EntityID) {
  res := make([dynamic]EntityID)

	for type, filter in query {
		pool := &container[type]

		ids, _ := slice.map_keys(pool.components)
		defer delete(ids)

		for id in ids {
			if val, ok := pool.components[id]; ok && filter(id, val) {
				append(&res, id)
			}
		}
	}

	s = res[:]
	slice.sort(s)
	s = slice.unique(s)

	return 
}

