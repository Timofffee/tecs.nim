import unittest
import tecs

test "full":
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
  world.freeEntity(entityId2)
  world.callSystems()
  entityId2 = world.addEntity
  world.addComponent(entityId2, PositionComponent(x: 30))
  world.addTag(entityId2, MovableTag)
  world.callSystems()
