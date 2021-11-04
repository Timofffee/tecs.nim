import std/unittest
import tecs

test "Init world":
    var world = initWorld()
    check(world.maxEntityId.int == 1000)

suite "Full test":
  setup:
    type 
      PositionComponent = object
        entity: uint64
        x: int
        y: int
      MovableTag = object
    
    var world = initWorld()
  
  # teardown:
  #   discard
  
  test "Add entity":
    var entityId = world.addEntity

    check(entityId == 1'u64 shl 32 + 1)

  test "Add component as object":
    var entityId = world.addEntity
    world.addComponent(entityId, PositionComponent(x: 10))
  
  test "Add component as typedesc":
    var entityId = world.addEntity
    var c = world.addComponent(entityId, PositionComponent)
  
  test "Get component":
    block:
      var entityId = world.addEntity
      world.addComponent(entityId, PositionComponent(x: 10))
      var component = world.getComponent(entityId, PositionComponent)

      check(component.entity == entityId)
      check(component.x == 10)
      check(component.y == 0)
    block:
      var entityId = world.addEntity
      var c = world.addComponent(entityId, PositionComponent)
      var component = world.getComponent(entityId, PositionComponent)

      check(component.entity == entityId)
      check(component.x == 0)
      check(component.y == 0)

  test "Add tag":
    var entityId = world.addEntity
    world.addTag(entityId, MovableTag)
  
  test "Filter with component":
    var entityId = world.addEntity
    var entityId2 = world.addEntity
    world.addTag(entityId2, MovableTag)
    world.addComponent(entityId, PositionComponent(x: 10))
    var filter = world.withComponent(PositionComponent)

    check(filter.len == 1)
    check(filter[0] == entityId)
  
  test "Filter with tag":
    var entityId = world.addEntity
    var entityId2 = world.addEntity
    world.addTag(entityId2, MovableTag)
    world.addComponent(entityId, PositionComponent(x: 10))
    var filter = world.withTag(MovableTag)

    check(filter.len == 1)
    check(filter[0] == entityId2)
  
  test "Remove component":
    var entityId = world.addEntity
    var entityId2 = world.addEntity
    world.addComponent(entityId, PositionComponent(x: 10))
    world.addComponent(entityId2, PositionComponent)
    var filter = world.withComponent(PositionComponent)

    check(filter.len == 2)

    world.removeComponent(entityId, PositionComponent)
    filter = world.withComponent(PositionComponent)

    check(filter.len == 1)
    check(filter[0] == entityId2)
  
  test "Remove component":
    var entityId = world.addEntity
    var entityId2 = world.addEntity
    world.addTag(entityId, MovableTag)
    world.addTag(entityId2, MovableTag)
    var filter = world.withTag(MovableTag)

    check(filter.len == 2)

    world.removeTag(entityId, MovableTag)
    filter = world.withTag(MovableTag)

    check(filter.len == 1)
    check(filter[0] == entityId2)

# test "full":

#   # systems
#   proc updatePos(world: var World) =
#     var filter = withTag(world, MovableTag).withComponent(world, PositionComponent)
#     for entity in filter.items:
#       var position = world.getComponent(entity, PositionComponent)
#       position.x += 1


#   proc printPos(world: var World) =
#     var filter = world.withComponent(PositionComponent)
#     for entity in filter.items:
#       var position = world.getComponent(entity, PositionComponent)
#       echo (getEntityId(position.entity), getEntityVersion(position.entity), position.x, position.y)


#   world.callSystems()
#   world.removeTag(entityId2, MovableTag)
#   world.callSystems()
#   world.freeEntity(entityId2)
#   world.callSystems()
#   entityId2 = world.addEntity
#   world.addComponent(entityId2, PositionComponent(x: 30))
#   world.addTag(entityId2, MovableTag)
#   world.callSystems()
