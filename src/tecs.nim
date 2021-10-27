# types
type 
  Entity* = object
    version*: uint32
    componentBitmask*: uint32
    tagBitmask*: uint32
  
  World* = object
    entities: seq[Entity]
    freeEntities: seq[uint32]
    currentEntityId*: uint32    
    maxEntityId*: uint32
    components: seq[pointer]
    componentTypeList: seq[string]
    tagTypeList: seq[string]
    systems: seq[proc(world: var World, entity: uint64)]

proc initWorld*(maxEntities: uint32 = 10000): World =
  result = World()
  result.entities.setLen(maxEntities)
  result.maxEntityId = maxEntities


proc getEntityId(entity: uint64): uint32 =
  return (entity shr 32).uint32


proc getEntityVersion(entity: uint64): uint32 =
  return entity.uint32


# procedures
proc getNewEntityID(world: var World): uint32 =
  inc world.currentEntityId

  return world.currentEntityId


proc registerComponent[T](world: var World, t: typedesc[T]) =
  var ts: string = $T
  world.components.add(allocShared0(sizeof(seq[T])))
  cast[var seq[T]](world.components[^1]).setLen(world.maxEntityId)
  world.componentTypeList.add(ts)


proc getComponentID[T](world: var World, t: typedesc[T]): uint32 =
  if world.componentTypeList.find($T) == -1:
    world.registerComponent(T)
  
  return world.componentTypeList.find($T).uint32


proc registerTag[T](world: var World, t: typedesc[T]) =
  var ts: string = $T
  world.tagTypeList.add(ts)


proc getTagID[T](world: var World, t: typedesc[T]): uint32 =
  if world.tagTypeList.find($T) == -1:
    world.registerTag(T)
  
  return world.tagTypeList.find($T).uint32


proc addEntity*(world: var World): uint64 =
  var id: uint32 = 0
  if world.freeEntities.len > 0:
    id = world.freeEntities.pop
  else:
    id = world.getNewEntityID
    if id > world.maxEntityId:
      return 0
  world.entities[id].version += 1

  return id.uint64 shl 32 + world.entities[id].version.uint64


proc getComponentList[T](world: var World, t: typedesc[T]): ptr seq[T] =
  let componentId = world.getComponentID(T)

  return cast[ptr seq[T]](world.components[componentId]) 


proc removeComponent*[T](world: var World, entity: uint64, t: typedesc[T]) =
  var bitmaskId = (1 shl world.getComponentID(T)).uint32
  if (world.entities[getEntityId(entity)].componentBitmask and bitmaskId.uint32) != bitmaskId.uint32:
    return
  world.entities[getEntityId(entity)].componentBitmask = world.entities[getEntityId(entity)].componentBitmask xor bitmaskId

  
proc removeTag*[T](world: var World, entity: uint64, t: typedesc[T]) =
  var bitmaskId = (1 shl world.getTagID(T)).uint32
  if (world.entities[getEntityId(entity)].tagBitmask and bitmaskId.uint32) != bitmaskId.uint32:
    return
  world.entities[getEntityId(entity)].tagBitmask = world.entities[getEntityId(entity)].tagBitmask xor bitmaskId
  

proc removeEntity*(world: var World, entity: uint64) =
  let entityId = getEntityId(entity)
  world.entities[entityId].componentBitmask = 0
  world.freeEntities.add(entityId)


proc addComponent*[T](world: var World, entity: uint64, t: typedesc[T]): ptr T {.discardable.} =
  let entityId = getEntityId(entity)
  var componentList = world.getComponentList(T)
  componentList[][entityId] = T()
  componentList[][entityId].entity = entity
  world.entities[entityId].componentBitmask = world.entities[entityId].componentBitmask or (1 shl world.getComponentID(T)).uint32

  return componentList[][entityId].addr


proc addComponent*[T](world: var World, entity: uint64, component: T): ptr T {.discardable.} =
  let entityId = getEntityId(entity)
  var componentList = world.getComponentList(T)
  componentList[][entityId] = component
  componentList[][entityId].entity = entity
  world.entities[entityId].componentBitmask = world.entities[entityId].componentBitmask or (1 shl world.getComponentID(T)).uint32

  return componentList[][entityId].addr


proc addTag*[T](world: var World, entity: uint64, t: typedesc[T]) =
  let entityId = getEntityId(entity)
  world.entities[entityId].tagBitmask = world.entities[entityId].tagBitmask or (1 shl world.getTagID(T)).uint32


proc hasComponent*[T](world: var World, entity: uint64, t: typedesc[T]): bool =
  var bitmaskId = (1 shl world.getComponentID(T)).uint32
  return (world.entities[getEntityId(entity)].componentBitmask and bitmaskId.uint32) == bitmaskId.uint32


proc hasTag*[T](world: var World, entity: uint64, t: typedesc[T]): bool =
  var bitmaskId = (1 shl world.getTagID(T)).uint32
  return (world.entities[getEntityId(entity)].tagBitmask and bitmaskId.uint32) == bitmaskId.uint32


proc getComponent*[T](world: var World, entity: uint64, t: typedesc[T]): ptr T =
  let entityId = getEntityId(entity)
  var componentList = world.getComponentList(T)
  var bitmaskId = (1 shl world.getComponentID(T)).uint32
  if (world.entities[entityId].componentBitmask and bitmaskId.uint32) != bitmaskId.uint32:
    return nil

  return componentList[][entityId].addr


proc addSystem*(world: var World, system: proc(world: var World, entity: uint64)) =
  world.systems.add system

  
template callSystems*(world: var World): untyped =
  for i in 0..<len(world.entities):
    if world.entities[i].componentBitmask == 0:
      continue
    for systemCall in world.systems.items:
      systemCall(world, i.uint64 shl 32 + world.entities[i].version)


      
when isMainModule:
  # components
  type 
    PositionComponent = object
      entity: uint64
      x: int
      y: int
    MovableTag = object

  # systems
  proc updatePos(world: var World, entity: uint64) =
    if world.hasTag(entity, MovableTag) and world.hasComponent(entity, PositionComponent):
      var position = world.getComponent(entity, PositionComponent)
      position.x += 1


  proc printPos(world: var World, entity: uint64) =
    if world.hasComponent(entity, PositionComponent):
      var position = world.getComponent(entity, PositionComponent)
      echo (position.entity, position.x, position.y)


  # init
  var world = World()
  world.entities.setLen(10000)
  world.maxEntityId = 10000

  var entityId = world.addEntity
  world.addComponent(entityId, PositionComponent(x: 10))

  var entityId2 = world.addEntity
  var positionComponent = world.addComponent(entityId2, PositionComponent)
  positionComponent.x = 20
  world.addTag(entityId2, MovableTag)

  world.systems.add updatePos
  world.systems.add printPos

  world.callSystems()
  world.removeTag(entityId2, MovableTag)
  world.callSystems()
  world.removeEntity(entityId2)
  world.callSystems()