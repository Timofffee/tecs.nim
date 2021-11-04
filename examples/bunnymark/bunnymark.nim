import lenientops
import nimraylib_now
import ../../src/tecs
import std/algorithm

const
  MAX_BUNNIES = 50000

##  This is the maximum amount of elements (quads) per batch
##  NOTE: This value is defined in [rlgl] module and can be changed there

const
  MAX_BATCH_ELEMENTS = 8192

type
  PositionComponent = object
    entity: uint64
    position: Vector2
  MovableComponent = object
    entity: uint64
    speed: Vector2
  SpriteComponent = object
    entity: uint64
    color: Color
    texture: Texture2D

const screenWidth = 800
const screenHeight = 450

##  Initialization
## --------------------------------------------------------------------------------------
initWindow(screenWidth, screenHeight, "raylib [textures] example - bunnymark")
setTargetFPS(60)

var bunniesCount = 0
var texBunny: Texture2D = loadTexture("resources/wabbit_alpha.png")


proc addBunnies(world: var World) =
  if isMouseButtonDown(Left_Button):
    ##  Create more bunnies
    for i in 0..<100:
      if bunniesCount < MAX_BUNNIES:
        var eid = world.addEntity()
        world.addComponent(eid, PositionComponent(position: getMousePosition()))

        var movableComponent = world.addComponent(eid, MovableComponent)
        movableComponent.speed.x = (getRandomValue(-250, 250).float / 60.0)
        movableComponent.speed.y = (getRandomValue(-250, 250).float / 60.0)

        var spriteComponent = world.addComponent(eid, SpriteComponent)
        spriteComponent.color = Color(
          r: getRandomValue(50, 240).uint8,
          g: getRandomValue(80, 240).uint8,
          b: getRandomValue(100, 240).uint8,
          a: 255
        )
        spriteComponent.texture = texBunny
        
        inc(bunniesCount)

proc updateBunnies(world: var World) =
  let filter = withComponent(world, PositionComponent).withComponent(world, MovableComponent)

  for eid in 0..<filter.len:
    let entity = filter[eid]
    var pos = world.getComponent(entity, PositionComponent)
    var mov = world.getComponent(entity, MovableComponent)
    pos.position.x += mov.speed.x
    pos.position.y += mov.speed.y
    if ((pos.position.x + texBunny.width / 2.0) > getScreenWidth()) or
        ((pos.position.x + texBunny.width div 2) < 0):
      mov.speed.x = mov.speed.x * -1
    if ((pos.position.y + texBunny.height div 2) > getScreenHeight()) or
        ((pos.position.y + texBunny.height div 2 - 40) < 0):
      mov.speed.y = mov.speed.y * -1


proc drawBunnies(world: World) =
  let filter = withComponent(world, PositionComponent).withComponent(world, MovableComponent)
  
  clearBackground(Raywhite)
  for eid in 0..<filter.len:
    let entity = filter[eid]
    var pos = world.getComponent(entity, PositionComponent)
    var spr = world.getComponent(entity, SpriteComponent)
    drawTexture(spr.texture, pos.position.x.cint, pos.position.y.cint,
              spr.color)


proc drawUI() =
  drawRectangle(0, 0, screenWidth, 40, Black)
  drawText(textFormat("bunnies: %i", bunniesCount), 120, 10, 20, Green)
  drawText(textFormat("batched draw calls: %i",
                      1 + bunniesCount div MAX_BATCH_ELEMENTS), 320, 10, 20, Maroon)
  drawFPS(10, 10)


var world = initWorld()


while not windowShouldClose(): ##  Detect window close button or ESC key
  addBunnies(world)
  updateBunnies(world)
  beginDrawing:
    drawBunnies(world)
    drawUI()
unloadTexture(texBunny)
closeWindow()

