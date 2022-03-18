import component_list
import component, ../bitmask, entity

type 
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
