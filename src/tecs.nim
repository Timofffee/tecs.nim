import component_list, component, world, entity
export component_list, component, world, entity

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
