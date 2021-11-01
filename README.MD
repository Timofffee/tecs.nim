# TECS
TECS - Simple ECS implementation for Nim. TECS is aimed at speed, simplicity and convenience in operation. Also TECS is overly light and simple. It is written without using macros and has no dependencies.

Docs: https://timofffee.github.io/tecs.nim/

## Example
```Nim
type 
  # Component
  PositionComponent = object
    entity: uint64
    x: int
    y: int
  # Tag
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
```

## Known issues:
* The code is not divided into submodules. This really sucks, because if there is a desire to use only a part of TECS in several files, you will have to import the entire TECS into a file every time. This is a primary task that should be solved. 
* The code is not fully understood. Although this implementation is extremely tiny, however, in some places there are no necessary checks and/or the code is written too clumsily.
