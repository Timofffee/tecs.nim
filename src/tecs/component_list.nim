import world, component

type 
  ComponentList = object
    list_ptr: pointer
    count: uint32
    component_size: int

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