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

    check(getEntityId(entityId) == 1)
    check(getEntityVersion(entityId) == 1)

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

      check(component.x == 10)
      check(component.y == 0)
    block:
      var entityId = world.addEntity
      var c = world.addComponent(entityId, PositionComponent)
      var component = world.getComponent(entityId, PositionComponent)

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
  
  test "Remove tag":
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

  test "Free entity":
    var entityId = world.addEntity
    var entityId2 = world.addEntity
    world.addTag(entityId, MovableTag)
    world.addTag(entityId2, MovableTag)
    var filter = world.withTag(MovableTag)

    check(filter.len == 2)

    world.freeEntity(entityId)
    filter = world.withTag(MovableTag)

    check(filter.len == 1)
    check(filter[0] == entityId2)

