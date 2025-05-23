package ecs

import "core:fmt"

Archetype :: struct($T : typeid) {
	construct : proc(map[typeid]rawptr) -> T,
	types 		: []typeid,
}

archetype :: proc(
  construct : proc(map[typeid]rawptr) -> $T,
	types     : ..typeid,
) -> (a : Archetype(T)) {
  a.construct = construct
	a.types = types

  return
}

with :: proc(
	component : $T
) -> T {
	return T
}

ArchetypeContainer :: distinct map[typeid]Archetype(rawptr)

@private
new_archetype_container :: proc() -> (c : ArchetypeContainer) {
	c = make(ArchetypeContainer)
	
	return
}

@private
free_archetype_container :: proc(
	container : ^ArchetypeContainer,
) {
	delete(container^)
}

@private
archetype_container_get :: proc(
	archetypes : ArchetypeContainer,
	$T 				 : typeid,
	id 				 : EntityID,
) -> (
	archetype : T, 
	ok 				: bool
) {
	res := transmute(Archetype(T))archetypes[T] or_return

	when ODIN_DEBUG {
		fmt.printfln("FOUND ARCHETYPE OF TYPE %v", typeid_of(T))
	}

	fields := make(map[typeid]rawptr)
	defer delete(fields)

	for type in res.types {
		component := component_container_get(&world.components, type, id) or_return
		fields[type] = component
	}

	archetype, ok = res.construct(fields), true

	return
}

@private
archetype_container_set :: proc(
	container : ^ArchetypeContainer,
	archetype : Archetype($T),
) -> (ok : bool) {
	if hit := T in container; !hit {
		container[T] = transmute(Archetype(rawptr))archetype
		ok = true
	}

	return
}

