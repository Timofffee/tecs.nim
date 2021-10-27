# TECS
TECS - Simple ECS implementation for Nim. TECS is aimed at speed, simplicity and convenience in operation. Also TECS is overly light and simple. It is written without using macros and has no dependencies.

## Example
```Nim
import tecs

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
var world = initWorld(10000) # 10000 == max entities

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
```

## Known issues:
* Irrational use of memory. The early implementation supported a dynamic number of components and entities, but for the sake of optimization, we had to abandon dynamic memory allocation. In the future, I will try to add block allocation, which will solve another problem.
* At the start of the world, a huge amount of memory is allocated, equal to the maximum number of children.  With the addition of a new component, even more memory is allocated. This will also be fixed thanks to block memory allocation in the future.
* The code is not divided into submodules. This really sucks, because if there is a desire to use only a part of TECS in several files, you will have to import the entire TECS into a file every time. This is a primary task that should be solved. 
* The code is not fully understood. Although this implementation is extremely tiny, however, in some places there are no necessary checks and/or the code is written too clumsily.