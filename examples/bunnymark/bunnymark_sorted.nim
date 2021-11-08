# ******************************************************************************************
#
#    raylib [textures] example - Bunnymark
#
#    This example has been created using raylib 1.6 (www.raylib.com)
#    raylib is licensed under an unmodified zlib/libpng license (View raylib.h for details)
#
#    Copyright (c) 2014-2019 Ramon Santamaria (@raysan5)
#    Converted in 2021 by greenfork
#    Converted in tecs by timofffee
#
# ******************************************************************************************

# This code differs from the original `bunnimark.nim` in that it tries to sort bunnies by Y.

import lenientops
import nimraylib_now
import ../../src/tecs
import std/algorithm

const
  MAX_BUNNIES = 50000

const
  MAX_BATCH_ELEMENTS = 8192

type
  PositionComponent = object
    position: Vector2
  MovableComponent = object
    speed: Vector2
  SpriteComponent = object
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


proc drawBunnies(world: var World) =
  let filter = withComponent(world, PositionComponent).withComponent(world, MovableComponent)
  var components = newSeq[tuple[pos: ptr PositionComponent, spr: ptr SpriteComponent]](filter.len)
  for eid in 0..<filter.len:
    let entity = filter[eid]
    components[eid] = (pos: world.getComponent(entity, PositionComponent), spr: world.getComponent(entity, SpriteComponent))
  components.sort do (x, y: tuple[pos: ptr PositionComponent, spr: ptr SpriteComponent]) -> int:
    result = cmp(x.pos.position.y, y.pos.position.y)
    if result == 0:
      result = cmp(x.pos.position.x, y.pos.position.x)

  clearBackground(Raywhite)
  for eid in 0..<components.len:
    drawTexture(components[eid].spr.texture, components[eid].pos.position.x.cint, components[eid].pos.position.y.cint,
              components[eid].spr.color)
  

proc drawUI(world: var World) =
  drawRectangle(0, 0, screenWidth, 40, Black)
  drawText(textFormat("bunnies: %i", bunniesCount), 120, 10, 20, Green)
  drawText(textFormat("batched draw calls: %i",
                      1 + bunniesCount div MAX_BATCH_ELEMENTS), 320, 10, 20, Maroon)
  drawFPS(10, 10)


var world = initWorld()

proc callSystems {.inline.} =
  world.addBunnies
  world.updateBunnies
  beginDrawing:
    world.drawBunnies
    world.drawUI

while not windowShouldClose(): ##  Detect window close button or ESC key
  callSystems()
unloadTexture(texBunny)
closeWindow()

