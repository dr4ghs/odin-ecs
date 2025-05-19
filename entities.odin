package ecs

EntityID :: distinct u64

@(private)
EntitiyContainer :: struct {
  curr_id : EntityID,
  deleted : [dynamic]EntityID,
}

@(private)
entity_container_create :: proc() -> (container : EntitiyContainer) {
  container.curr_id = 0
  container.deleted = make([dynamic]EntityID)

  return
}

@(private)
entity_container_free :: proc(
  using container : ^EntitiyContainer,
) {
  delete(container.deleted)
}

@(private)
entity_container_new :: proc(
  using container : ^EntitiyContainer,
) -> (id : EntityID) {
  ok : bool

  if id, ok = pop_front_safe(&deleted); !ok {
    id = curr_id
    curr_id += 1
  }

  return
}

@(private)
entity_container_delete :: proc(
  using container : ^EntitiyContainer,
  id : EntityID,
) -> (ok : bool) {
  for curr in deleted {
    if id == curr {
      return 
    }
  }

  ok = true
  append(&deleted, id)

  return
}

