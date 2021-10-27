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
  proc updatePos(world: var World, entity: uint64) =
    if world.hasTag(entity, MovableTag) and world.hasComponent(entity, PositionComponent):
      var position = world.getComponent(entity, PositionComponent)
      position.x += 1


  proc printPos(world: var World, entity: uint64) =
    if world.hasComponent(entity, PositionComponent):
      var position = world.getComponent(entity, PositionComponent)
      echo (position.entity, position.x, position.y)


  # init
  var world = initWorld()

  var entityId = world.addEntity
  world.addComponent(entityId, PositionComponent(x: 10))

  var entityId2 = world.addEntity
  var positionComponent = world.addComponent(entityId2, PositionComponent)
  positionComponent.x = 20
  world.addTag(entityId2, MovableTag)

  world.addSystem updatePos
  world.addSystem printPos

  world.callSystems()
  world.removeTag(entityId2, MovableTag)
  world.callSystems()
  world.removeEntity(entityId2)
  world.callSystems()
