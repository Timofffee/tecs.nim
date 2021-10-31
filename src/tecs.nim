import sequtils

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
    allocSize*: uint32
    components: seq[pointer]
    componentTypeList: seq[string]
    tagTypeList: seq[string]
    systems: seq[proc(world: var World)]

proc initWorld*(initAlloc: uint32 = 1000, allocSize: uint32 = 1000): World =
  result = World()
  result.entities.setLen(initAlloc)
  result.maxEntityId = initAlloc
  result.allocSize = allocSize

proc increaseWorld(world: var World) =
  world.maxEntityId += world.allocSize
  world.entities.setLen(world.maxEntityId)

proc getEntityId*(entity: uint64): uint32 {.inline.} =
  return (entity shr 32).uint32


proc getEntityVersion*(entity: uint64): uint32 {.inline.} =
  return entity.uint32


# procedures
proc getNewEntityID(world: var World): uint32 {.inline.} =
  inc world.currentEntityId

  return world.currentEntityId


proc registerComponent*(world: var World, componentType: typedesc) {.inline.} =
  world.components.add(allocShared0(sizeof(seq[componentType])))
  cast[var seq[componentType]](world.components[^1]).setLen(world.maxEntityId)
  world.componentTypeList.add($componentType)


proc getComponentID(world: var World, componentType: typedesc): uint32 =
  var componentIdx = world.componentTypeList.find($componentType)
  if componentIdx == -1:
    world.registerComponent(componentType)
    componentIdx = world.componentTypeList.find($componentType)
  return componentIdx.uint32


proc registerTag*(world: var World, tagType: typedesc) {.inline.} =
  world.tagTypeList.add($tagType)


proc getTagID(world: var World, tagType: typedesc): uint32 =
  if world.tagTypeList.find($tagType) == -1:
    world.registerTag(tagType)
  
  return world.tagTypeList.find($tagType).uint32


proc addEntity*(world: var World): uint64 =
  var id: uint32 = 0
  if world.freeEntities.len > 0:
    id = world.freeEntities.pop
  else:
    id = world.getNewEntityID()
    while id >= world.maxEntityId:
      world.increaseWorld()
  world.entities[id].version += 1

  return id.uint64 shl 32 + world.entities[id].version.uint64


proc getComponentList[T](world: var World, componentType: typedesc[T]): ptr seq[T] =
  let componentId = world.getComponentID(componentType)
  if cast[ptr seq[T]](world.components[componentId])[].len != world.maxEntityId.int:
    cast[ptr seq[T]](world.components[componentId])[].setLen(world.maxEntityId)

  return cast[ptr seq[T]](world.components[componentId]) 


proc removeComponent*(world: var World, entity: uint64, componentType: typedesc) =
  var bitmaskId = (1 shl world.getComponentID(componentType)).uint32
  if (world.entities[getEntityId(entity)].componentBitmask and bitmaskId.uint32) != bitmaskId.uint32:
    return
  world.entities[getEntityId(entity)].componentBitmask = world.entities[getEntityId(entity)].componentBitmask xor bitmaskId

  
proc removeTag*(world: var World, entity: uint64, tagType: typedesc) =
  var bitmaskId = (1 shl world.getTagID(tagType)).uint32
  if (world.entities[getEntityId(entity)].tagBitmask and bitmaskId.uint32) != bitmaskId.uint32:
    return
  world.entities[getEntityId(entity)].tagBitmask = world.entities[getEntityId(entity)].tagBitmask xor bitmaskId
  

proc removeEntity*(world: var World, entity: uint64) =
  let entityId = getEntityId(entity)
  world.entities[entityId].componentBitmask = 0
  world.freeEntities.add(entityId)


proc addComponent*[T](world: var World, entity: uint64, componentType: typedesc[T]): ptr T {.discardable.} =
  let entityId = getEntityId(entity)
  var componentList = world.getComponentList(componentType)
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


proc addTag*(world: var World, entity: uint64, tagType: typedesc) =
  let entityId = getEntityId(entity)
  world.entities[entityId].tagBitmask = world.entities[entityId].tagBitmask or (1 shl world.getTagID(tagType)).uint32


proc hasComponent*(world: var World, entity: uint64, componentType: typedesc): bool =
  var bitmaskId = (1 shl world.getComponentID(componentType)).uint32
  return (world.entities[getEntityId(entity)].componentBitmask and bitmaskId) == bitmaskId


proc hasTag*(world: var World, entity: uint64, tagType: typedesc): bool =
  var bitmaskId = (1 shl world.getTagID(tagType)).uint32
  return (world.entities[getEntityId(entity)].tagBitmask and bitmaskId) == bitmaskId


proc getComponent*[T](world: var World, entity: uint64, componentType: typedesc[T]): ptr T =
  let entityId = getEntityId(entity)
  var componentList = world.getComponentList(componentType)
  # var bitmaskId = (1 shl world.getComponentID(T)).uint32
  # if (world.entities[entityId].componentBitmask and bitmaskId) != bitmaskId:
  #   return nil

  return componentList[][entityId].addr


proc withTag*(world: var World, tagType: typedesc): seq[uint64] =
  var bitmaskId = (1 shl world.getTagID(tagType)).uint32
  for i in 0..<world.entities.len:
    if (world.entities[i].tagBitmask and bitmaskId) == bitmaskId:
      result.add i.uint64 shl 32 + world.entities[i].version.uint64

proc withTag*(entities: seq[uint64], world: var World, tagType: typedesc): seq[uint64] =
  var bitmaskId = (1 shl world.getTagID(tagType)).uint32
  for entity in entities.items:
    if (world.entities[getEntityId(entity)].tagBitmask and bitmaskId) == bitmaskId:
      result.add entity


proc withComponent*(world: var World, componentType: typedesc): seq[uint64] =
  var bitmaskId = (1 shl world.getComponentID(componentType)).uint32
  for i in 0..<world.entities.len:
    if (world.entities[i].componentBitmask and bitmaskId) == bitmaskId:
      result.add i.uint64 shl 32 + world.entities[i].version.uint64

proc withComponent*(entities: seq[uint64], world: var World, componentType: typedesc): seq[uint64] =
  var bitmaskId = (1 shl world.getComponentID(componentType)).uint32
  for entity in entities.items:
    if (world.entities[getEntityId(entity)].componentBitmask and bitmaskId) == bitmaskId:
      result.add entity


proc addSystem*(world: var World, system: proc(world: var World)) {.inline.} =
  world.systems.add system

  
template callSystems*(world: var World): untyped =
  for systemCall in world.systems.items:
    systemCall(world)


      
when isMainModule:
  # components
  type 
    PositionComponent = object
      entity: uint64
      x: int
      y: int
    MovableTag = object

  # systems
  proc updatePos(world: var World) =
    var filter = withTag(world, MovableTag).withComponent(world, PositionComponent)
    for entity in filter.items:
      var position = world.getComponent(entity, PositionComponent)
      position.x += 1


  proc printPos(world: var World) =
    var filter = world.withComponent(PositionComponent)
    for entity in filter.items:
      var position = world.getComponent(entity, PositionComponent)
      echo (getEntityId(position.entity), getEntityVersion(position.entity), position.x, position.y)


  # init
  var world = initWorld()

  var entityId = world.addEntity
  world.addComponent(entityId, PositionComponent(x: 10))

  var entityId2 = world.addEntity
  world.addComponent(entityId2, PositionComponent(x: 20))
  world.addTag(entityId2, MovableTag)

  world.addSystem updatePos
  world.addSystem printPos

  world.callSystems()
  world.removeTag(entityId2, MovableTag)
  world.callSystems()
  world.removeEntity(entityId2)
  world.callSystems()
  entityId2 = world.addEntity
  world.addComponent(entityId2, PositionComponent(x: 30))
  world.addTag(entityId2, MovableTag)
  world.callSystems()
