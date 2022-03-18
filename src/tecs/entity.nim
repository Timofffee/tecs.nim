import ../bitmask

type
  Entity* = object
    ## Base Entity object 
    version*: uint32
    componentBitmask*: Bigmask

proc getEntityId*(entity: uint64): uint32 {.inline.} =
  ## Returns the entity ID.
  ## In this implementation, the entity identifier is represented as `uint64`, which stores the ID in the upper 32 bits, and the version in the lower 32 bits.
  return (entity shr 32).uint32

proc getEntityVersion*(entity: uint64): uint32 {.inline.} =
  ## Returns the version of the entity.
  ## In this implementation, the entity identifier is represented as `uint64`, which stores the ID in the upper 32 bits, and the version in the lower 32 bits.
  return entity.uint32

proc getNewEntityID(world: var World): uint32 {.inline.} =
  inc world.currentEntityId

  return world.currentEntityId

proc addEntity*(world: var World): uint64 =
  ## Adding a new entity to the world. Returns the entity identifier.
  var id: uint32 = 0
  if world.freeEntities.len > 0:
    id = world.freeEntities.pop
  else:
    id = world.getNewEntityID()
    while id >= world.maxEntityId:
      world.increaseWorld()
  world.entities[id].version += 1

  if world.entities[id].version == 1:
    world.entities[id].componentBitmask = initBigmask(4)

  return id.uint64 shl 32 + world.entities[id].version.uint64

proc freeEntity*(world: var World, entity: uint64) =
  ## Remove an entity from the world. 
  ## In fact, the entity will not be removed, but only clear the bitmask of components 
  ## and tags, and will also be moved to the list of recently released entities.
  let entityId = getEntityId(entity)
  world.entities[entityId].componentBitmask.clear()
  world.freeEntities.add(entityId)