## TECS is a very simple and tiny ECS implementation. It doesn't try to be fast and productive.
## This implementation tries to be simple and understandable for both the user and the developer.
## 
## Quick Tutorial
## ==============
## 
## At the beginning of use, you should initialize the world. Of course, you can 
## do all this manually, but it's best to use the `initworld()` procedure
## 
## .. code-block:: Nim
##  import tecs
##  
##  var world = initWorld()
##  var entity = world.addEntity
## 
## This implementation uses tags in addition to components. 
## Tags differ from components in that they do not have fields 
## and do not allocate memory when registering a new tag.
## 
## .. code-block:: Nim
##  import tecs
##  
##  type 
##    # component
##    BasicComponent = object
##      entityId: uint64 # required
##      val: int
## 
##    # tag
##    BasicTag = object
##      # no fields
##  
##  var world = initWorld()
##  var entity = world.addEntity
##  
##  var component = world.addComponent(entity, BasicComponent)
##  component.val = 12
##  
##  world.addTag(entity, BasicTag)
## 
## 
## ECS is written in such a way that you can add/remove/change an entity/component/tag at any time. But be careful with this.
## 

type 
  Entity* = object
    ## Base Entity object 
    version*: uint32
    componentBitmask*: uint32
    tagBitmask*: uint32
  
  World* = object
    ## The World contains all entities and components. 
    ## In fact, it is a container that is the foundation for the work 
    ## of everything else. The world is responsible for the storage of entities 
    ## and for the storage of components, 
    ## with their subsequent implementation.
    entities: seq[Entity]
    freeEntities: seq[uint32]
    currentEntityId*: uint32    
    maxEntityId*: uint32
    allocSize*: uint32
    components: seq[pointer]
    componentTypeList: seq[string]
    tagTypeList: seq[string]

proc initWorld*(initAlloc: uint32 = 1000, allocSize: uint32 = 1000): World =
  ## Initialization of a World object. 
  ## You should use this procedure to create a world, as it immediately 
  ## indicates the size of the allocated memory. You can also change `initAlloc` 
  ## for initial memory allocation and `allocSize` to specify how many blocks 
  ## should be allocated in case of insufficient memory.
  result = World()
  result.entities.setLen(initAlloc)
  result.maxEntityId = initAlloc
  result.allocSize = allocSize

proc increaseWorld(world: var World) =
  world.maxEntityId += world.allocSize
  world.entities.setLen(world.maxEntityId)

proc getEntityId*(entity: uint64): uint32 {.inline.} =
  ## Returns the entity ID.
  ## In this implementation, the entity identifier is represented as `uint64`, which stores the ID in the upper 32 bits, and the version in the lower 32 bits.
  return (entity shr 32).uint32


proc getEntityVersion*(entity: uint64): uint32 {.inline.} =
  ## Returns the version of the entity.
  ## In this implementation, the entity identifier is represented as `uint64`, which stores the ID in the upper 32 bits, and the version in the lower 32 bits.
  return entity.uint32


# procedures
proc getNewEntityID(world: var World): uint32 {.inline.} =
  inc world.currentEntityId

  return world.currentEntityId


proc registerComponent(world: var World, componentType: typedesc) {.inline.} =
  world.components.add(allocShared0(sizeof(seq[componentType])))
  cast[var seq[componentType]](world.components[^1]).setLen(world.maxEntityId)
  world.componentTypeList.add($componentType)


proc getComponentID(world: var World, componentType: typedesc): uint32 =
  var componentIdx = world.componentTypeList.find($componentType)
  if componentIdx == -1:
    world.registerComponent(componentType)
    componentIdx = world.componentTypeList.find($componentType)
  return componentIdx.uint32


proc registerTag(world: var World, tagType: typedesc) {.inline.} =
  world.tagTypeList.add($tagType)


proc getTagID(world: var World, tagType: typedesc): uint32 =
  if world.tagTypeList.find($tagType) == -1:
    world.registerTag(tagType)
  
  return world.tagTypeList.find($tagType).uint32


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

  return id.uint64 shl 32 + world.entities[id].version.uint64


proc getComponentList[T](world: var World, componentType: typedesc[T]): ptr seq[T] =
  let componentId = world.getComponentID(componentType)
  if cast[ptr seq[T]](world.components[componentId])[].len != world.maxEntityId.int:
    cast[ptr seq[T]](world.components[componentId])[].setLen(world.maxEntityId)

  return cast[ptr seq[T]](world.components[componentId]) 


proc removeComponent*(world: var World, entity: uint64, componentType: typedesc) =
  ## Remove a component from an entity located in the world.
  var bitmaskId = (1 shl world.getComponentID(componentType)).uint32
  if (world.entities[getEntityId(entity)].componentBitmask and bitmaskId.uint32) != bitmaskId.uint32:
    return
  world.entities[getEntityId(entity)].componentBitmask = world.entities[getEntityId(entity)].componentBitmask xor bitmaskId

  
proc removeTag*(world: var World, entity: uint64, tagType: typedesc) =
  ## Remove a component from an entity located in the world.
  var bitmaskId = (1 shl world.getTagID(tagType)).uint32
  if (world.entities[getEntityId(entity)].tagBitmask and bitmaskId.uint32) != bitmaskId.uint32:
    return
  world.entities[getEntityId(entity)].tagBitmask = world.entities[getEntityId(entity)].tagBitmask xor bitmaskId
  

proc freeEntity*(world: var World, entity: uint64) =
  ## Remove an entity from the world. 
  ## In fact, the entity will not be removed, but only clear the bitmask of components 
  ## and tags, and will also be moved to the list of recently released entities.
  let entityId = getEntityId(entity)
  world.entities[entityId].componentBitmask = 0
  world.entities[entityId].tagBitmask = 0
  world.freeEntities.add(entityId)


proc addComponent*[T](world: var World, entity: uint64, componentType: typedesc[T]): ptr T {.discardable.} =
  ## Add a component for an entity located in the world.
  let entityId = getEntityId(entity)
  var componentList = world.getComponentList(componentType)
  componentList[][entityId] = T()
  world.entities[entityId].componentBitmask = world.entities[entityId].componentBitmask or (1 shl world.getComponentID(T)).uint32

  return componentList[][entityId].addr


proc addComponent*[T](world: var World, entity: uint64, component: T): ptr T {.discardable.} =
  ## Add a component for an entity located in the world.
  ## This procedure can help in reducing the amount of code.
  let entityId = getEntityId(entity)
  var componentList = world.getComponentList(T)
  componentList[][entityId] = component
  world.entities[entityId].componentBitmask = world.entities[entityId].componentBitmask or (1 shl world.getComponentID(T)).uint32

  return componentList[][entityId].addr


proc addTag*(world: var World, entity: uint64, tagType: typedesc) =
  ## Add a tag for an entity located in the world. 
  ## Tags, like entities, are objects, but they do not contain 
  ## fields and no memory is allocated for them. 
  ## In fact, they are stored only in the entity bitmask. 
  ## Use them if you need to mark any object. They will help you save 
  ## performance and memory, unlike if you were using a borderless component.
  let entityId = getEntityId(entity)
  world.entities[entityId].tagBitmask = world.entities[entityId].tagBitmask or (1 shl world.getTagID(tagType)).uint32


proc getComponent*[T](world: var World, entity: uint64, componentType: typedesc[T]): ptr T =
  ## Returns a pointer to the component. Used in systems. 
  ## 
  ## **Important!** This procedure does not check for the presence of a component 
  ## in an entity, so if used incorrectly, you can get a component 
  ## from an entity that no longer exists (that is, garbage instead of a component).
  let entityId = getEntityId(entity)
  var componentList = world.getComponentList(componentType)
  # Commented for optimization
  # var bitmaskId = (1 shl world.getComponentID(T)).uint32
  # if (world.entities[entityId].componentBitmask and bitmaskId) != bitmaskId:
  #   return nil

  return componentList[][entityId].addr


proc withTag*(world: var World, tagType: typedesc): seq[uint64] =
  ## It is used in systems for initial filtering of entities by tag.
  var bitmaskId = (1 shl world.getTagID(tagType)).uint32
  for i in 0..<world.entities.len:
    if (world.entities[i].tagBitmask and bitmaskId) == bitmaskId:
      result.add i.uint64 shl 32 + world.entities[i].version.uint64

proc withTag*(entities: seq[uint64], world: var World, tagType: typedesc): seq[uint64] =
  ## It is used in filter chains in systems for initial filtering of entities by tag.
  var bitmaskId = (1 shl world.getTagID(tagType)).uint32
  for entity in entities.items:
    if (world.entities[getEntityId(entity)].tagBitmask and bitmaskId) == bitmaskId:
      result.add entity


proc withComponent*(world: var World, componentType: typedesc): seq[uint64] =
  ## It is used in systems for initial filtering of entities by components.
  var bitmaskId = (1 shl world.getComponentID(componentType)).uint32
  for i in 0..<world.entities.len:
    if (world.entities[i].componentBitmask and bitmaskId) == bitmaskId:
      result.add i.uint64 shl 32 + world.entities[i].version.uint64

proc withComponent*(entities: seq[uint64], world: var World, componentType: typedesc): seq[uint64] =
  ## It is used in filter chains in systems for initial filtering of entities by components.
  var bitmaskId = (1 shl world.getComponentID(componentType)).uint32
  for entity in entities.items:
    if (world.entities[getEntityId(entity)].componentBitmask and bitmaskId) == bitmaskId:
      result.add entity


when isMainModule:
  # components
  type 
    PositionComponent = object
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
      echo (getEntityId(entity), getEntityVersion(entity), position.x, position.y)


  # init
  var world = initWorld()

  var entityId = world.addEntity
  world.addComponent(entityId, PositionComponent(x: 10))

  var entityId2 = world.addEntity
  world.addComponent(entityId2, PositionComponent(x: 20))
  world.addTag(entityId2, MovableTag)

  proc callSystems =
    updatePos(world)
    printPos(world)

  callSystems()
  world.removeTag(entityId2, MovableTag)
  callSystems()
  world.freeEntity(entityId2)
  callSystems()
  entityId2 = world.addEntity
  world.addComponent(entityId2, PositionComponent(x: 30))
  world.addTag(entityId2, MovableTag)
  callSystems()
