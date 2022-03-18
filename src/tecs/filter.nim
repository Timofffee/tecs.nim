import world, component, ../bitmask, entity

proc with*(world: var World, componentType: typedesc): seq[uint64] =
  ## It is used in systems for initial filtering of entities by components.
  var componentId = world.getComponentID(componentType).int
  for i in 0..<world.entities.len:
    if world.entities[i].componentBitmask.has(componentId) == true:
      result.add i.uint64 shl 32 + world.entities[i].version.uint64

proc with*(entities: seq[uint64], world: var World, componentType: typedesc): seq[uint64] =
  ## It is used in filter chains in systems for initial filtering of entities by components.
  var componentId = world.getComponentID(componentType).int
  for entity in entities.items:
    if world.entities[getEntityId(entity)].componentBitmask.has(componentId):
      result.add entity