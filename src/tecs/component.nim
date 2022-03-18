import component_list
import world, ../bitmask, entity

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

proc addComponent*[T](world: var World, entity: uint64, componentType: typedesc[T]): ptr T {.discardable.} =
  ## Add a component for an entity located in the world.
  let entityId = getEntityId(entity)
  var componentList = world.getComponentList(componentType)
  componentList[][entityId] = T()
  world.entities[entityId].componentBitmask.add(world.getComponentID(T).int)

  return componentList[][entityId].addr

proc removeComponent*(world: var World, entity: uint64, componentType: typedesc) =
  ## Remove a component from an entity located in the world.
  var componentId = world.getComponentID(componentType).int
  if world.entities[getEntityId(entity)].componentBitmask.has(componentId) == false:
    return
  world.entities[getEntityId(entity)].componentBitmask.remove(componentId)

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