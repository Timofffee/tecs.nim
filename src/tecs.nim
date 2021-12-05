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

import bigmask

type 
  Entity* = object
    ## Base Entity object 
    version*: uint32
    componentBitmask*: Bigmask
  
  ComponentList = object
    list_ptr: pointer
    count: uint32
    component_size: int
  
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
    components: seq[ComponentList]
    componentTypeList: seq[string]

proc `=destroy`(world: var World) =
  for componentList in world.components.mitems:
    deallocShared(componentList.list_ptr)

  `=destroy`(world.entities)
  `=destroy`(world.freeEntities)
  `=destroy`(world.currentEntityId)
  `=destroy`(world.maxEntityId)
  `=destroy`(world.allocSize)
  `=destroy`(world.components)
  `=destroy`(world.componentTypeList)

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
  world.components.add(
    ComponentList(
      list_ptr: allocShared0(sizeof(componentType)*world.maxEntityId.int),
      count: world.maxEntityId,
      component_size: sizeof(componentType)
    ),
  )
  world.componentTypeList.add($componentType)


proc getComponentID(world: var World, componentType: typedesc): uint32 =
  var componentIdx = world.componentTypeList.find($componentType)
  if componentIdx == -1:
    world.registerComponent(componentType)
    componentIdx = world.componentTypeList.find($componentType)
  return componentIdx.uint32


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


proc getComponentList[T](world: var World, componentType: typedesc[T]): ptr UncheckedArray[T] =
  let componentId = world.getComponentID(componentType)
  if (world.components[componentId]).count != world.maxEntityId:
    world.components[componentId].list_ptr = reallocShared0(
      world.components[componentId].list_ptr, 
      world.components[componentId].component_size * world.components[componentId].count.int,
      world.components[componentId].component_size * world.maxEntityId.int
    )
    world.components[componentId].count = world.maxEntityId

  return cast[ptr UncheckedArray[T]](world.components[componentId].list_ptr) 


proc removeComponent*(world: var World, entity: uint64, componentType: typedesc) =
  ## Remove a component from an entity located in the world.
  var componentId = world.getComponentID(componentType).int
  if world.entities[getEntityId(entity)].componentBitmask.has(componentId) == false:
    return
  world.entities[getEntityId(entity)].componentBitmask.remove(componentId)


proc freeEntity*(world: var World, entity: uint64) =
  ## Remove an entity from the world. 
  ## In fact, the entity will not be removed, but only clear the bitmask of components 
  ## and tags, and will also be moved to the list of recently released entities.
  let entityId = getEntityId(entity)
  world.entities[entityId].componentBitmask.clear()
  world.freeEntities.add(entityId)


proc addComponent*[T](world: var World, entity: uint64, componentType: typedesc[T]): ptr T {.discardable.} =
  ## Add a component for an entity located in the world.
  let entityId = getEntityId(entity)
  var componentList = world.getComponentList(componentType)
  componentList[][entityId] = T()
  world.entities[entityId].componentBitmask.add(world.getComponentID(T).int)

  return componentList[][entityId].addr


proc addComponent*[T](world: var World, entity: uint64, component: T): ptr T {.discardable.} =
  ## Add a component for an entity located in the world.
  ## This procedure can help in reducing the amount of code.
  let entityId = getEntityId(entity)
  var componentList = world.getComponentList(T)
  componentList[][entityId] = component
  world.entities[entityId].componentBitmask.add(world.getComponentID(T).int)

  return componentList[][entityId].addr


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


when isMainModule:
  # components
  type 
    PositionComponent = object
      x: int
      y: int
    MovableTag = object

  # systems
  proc updatePos(world: var World) =
    var filter = world.with(PositionComponent).with(world, MovableTag)
    # var filter = with(world, PositionComponent, MovableTag)
    for entity in filter.items:
      var position = world.getComponent(entity, PositionComponent)
      position.x += 1


  proc printPos(world: var World) =
    var filter = world.with(PositionComponent)
    for entity in filter.items:
      var position = world.getComponent(entity, PositionComponent)
      echo (getEntityId(entity), getEntityVersion(entity), position.x, position.y)


  # init
  var world = initWorld()

  var entityId = world.addEntity
  world.addComponent(entityId, PositionComponent(x: 10))

  var entityId2 = world.addEntity
  world.addComponent(entityId2, PositionComponent(x: 20))
  world.addComponent(entityId2, MovableTag)

  proc callSystems =
    updatePos(world)
    printPos(world)

  callSystems()
  world.removeComponent(entityId2, MovableTag)
  callSystems()
  world.freeEntity(entityId2)
  callSystems()
  entityId2 = world.addEntity
  world.addComponent(entityId2, PositionComponent(x: 30))
  world.addComponent(entityId2, MovableTag)
  callSystems()
