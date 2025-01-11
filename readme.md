# Fizz X 

## Introduction
Fizz X is a 2D axis-aligned physics library written in the [Lua](https://lua.org) programming language.
Fizz X is useful in environments where external option like [Box2D](https://box2d.org) are unavailable.

The source code is available on [GitHub](https://github.com/2dengine/fizzx) and the documentation is hosted on [2dengine.com](https://2dengine.com/doc/fizzx.html)


## Example
```Lua
fizz = require("fizzx")
fizz.setGravity(0, 100)

ball = fizz.addDynamic('circle', 300, 100, 10)
wall = fizz.addStatic('rect', 300, 400, 200, 10)

ball.bounce = 0.5

function love.update(dt)
  fizz.update(dt)
end

function love.draw()
  love.graphics.circle("fill", ball.x, ball.y, ball.r)
  love.graphics.rectangle("fill", wall.x - wall.hw, wall.y - wall.hh, wall.hw*2, wall.hh*2)
end
```

## Shapes
Fizz supports three different shape types: circles, rectangles and line segments.
Note that rectangles are represented by a center point and half-width and half-height extents.
Rectangles are always axis-aligned and cannot have rotation.
Line segments are useful for making slopes and possibly "one-sided" platforms.
The direction of line segments affects how they handle collisions.
Line segments "push" other intersecting shapes at 90 degrees counter-clockwise of the segment slope.

In addition, there are three classes of shapes: static, kinematic and dynamic.
Static shapes are immobile and do not respond to collisions or gravity.
Static shapes can be used to represent walls and platforms in your game.
Kinematic shapes do not respond to collisions or gravity, but can be moved by manually changing their velocity.
Kinematic shapes can be used to simulate moving platforms and doors.
Dynamic shapes respond to collisions and gravity.
Dynamic shapes can be used to simulate the moving objects in your game.

Shapes have the following properties:

### shape.x, shape.y
Center position of circle and rectangle shapes.
Starting point for line segments.

### shape.x2, shape.y2
Ending point for line segments.

### shape.r
Radius for circle shapes.

### shape.hw, shape.hh
Half-width and half-height extents for rectangle shapes.

### shape.xv, shape.yv
Velocity of a dynamic or kinematic shape.

### shape.sx, shape.sy
Accumulated displacement vector of the shape.

### shape.mass, shape.imass
Mass and inverse mass of the shape.

### shape.friction
Friction value applied when the edges of two shapes are touching.
As this value increases, the shape will slow down when sliding on top of other shapes.
Must be between 0 and 1.

### shape.bounce
Bounce or restitution value of the shape.
As this value increases, the shape will bounce more elastically when colliding with other shapes.
Must be between 0 and 1.

### shape.damping
Linear damping of the shape.
The damping value slows the velocity of moving shapes over time.
Must be between 0 and infinity.

### shape.gravity
Gravity scale of the shape which is multiplied by the global gravity value.
Set this to 0 and your shape will not be affected by gravity.
When negative, the shape will levitate.

### shape.onCollide(a, b, nx, ny, pen)
Collision callback providing the two colliding shapes, the collision normal and the penetration depth.
If this callback returns false the collision will be ignored.
Shapes should not be moved or destroyed during this callback.


## Limitations
### Torque
Torque and rotation are not supported.
This has several implications, most notably with circle shapes.
Circle shapes are axis-aligned, so they never "spin" or "roll".
Axis-aligned circles with friction behave like the wheels of a car while the breaks are on.
If you want to simulate torque, I would suggest a more sophisticated library, like Box2D.
For simple platform games, you could always draw or animate your objects as if they are rotating.

### Tunneling
Since the library uses non-continuous collision detection, it's possible for shapes that move at a high velocity to "tunnel" or pass through other shapes.
This problem can be accommodated in a few ways.
First, make sure fizz.maxVelocity is defined within a reasonable range.
Second, set up your game loop to update the simulation with a constant time step.
This will make sure that the game will play the same on any machine.
Here is an example of how to update the simulation with a constant time step:
```Lua
accum = 0
step = 1/60
function update(dt)
  accum = accum + dt
  while accum >= step do
    fizz.update(step)
    accum = accum - step
  end
end
```

### Partitioning
Fizz uses flat grid partitioning to reduce the number of collision tests.
You can adjust the default grid cell size if the performance is not up to par.

Manually changing the position of shapes affects the partitioning system.
After modifying these values, you have to repartition the particular shape, for example:
```Lua
shape.x = 100
shape.y = 100
fizz.repartition(shape)
```
An alternative approach is to use the built-in functions:
```Lua
fizz.positionShape(100, 100)
```
Note that changing the size of shapes affects the partition system as well:
```Lua
circle.r = circle.r + 5
fizz.repartition(circle)
```
If you explicitly disable partitioning, then you can ignore this limitation.

### Stacking
Piling two or more dynamic shapes results in jittery behavior, because there is no simple way to figure out which collision pair should be resolved first.
This may cause one shape to overlap another in the stack even after their collisions have been resolved.

### Ledges
This issue occurs with rows of static rectangle shapes.
When a dynamic shape is sliding on top of the row it may get "blocked" by the ledge between rects.
The best solution is to use line segments to represent platforms.

## Credits
This library is based and builds upon the original work of [Taehl](https://github.com/Taehl)

Please support our work so we can release more free software in the future.