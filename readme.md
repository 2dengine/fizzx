# Fizz documentation 
Fizz is a lightweight collision library in Lua.
Fizz is designed specifically for old-school platformers and overhead action games.

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

Fizz uses flat grid partitioning to reduce the number of collision tests.
You can adjust the default grid cell size if the performance is not up to par.

# Files
## fizz.lua
The main module that you need to require in your game:

    fizz = require("fizzx.fizz")

## shapes.lua
Shapes intersection code.

## partition.lua
Broad-phase partitioning code.

# Functions
## fizz.setGravity(x, y)
Sets the global gravity.

## fizz.getGravity()
Returns the global gravity.

## fizz.addStatic("rect", x, y, hw, hh)
## fizz.addStatic("circle", x, y, r)
## fizz.addStatic("line", x, y, x2, y2)
Creates a static shape.
Static shapes are immovable.

## fizz.addKinematic("rect", x, y, hw, hh)
## fizz.addKinematic("circle", x, y, r)
## fizz.addKinematic("line", x, y, x2, y2)
Creates a kinematic shape.
Kinematic shapes have a velocity but do not respond to collisions.
This can be useful for simulating moving platforms.

## fizz.addDynamic("rect", x, y, hw, hh)
## fizz.addDynamic("circle", x, y, r)
Creates a dynamic shape.
Dynamic shapes can move and collide with other shapes.

## fizz.removeShape(s)
Removes a shape from the simulation.

## fizz.setDensity(s, d)
Sets the mass of a shape based on density.

## fizz.setMass(s, m)
Sets the mass of a shape based on mass.

## fizz.setPosition(s, x, y)
Moves the shape to a given position.
This function is used to "teleport" shapes.

## fizz.getPosition(s, x, y)
Returns the position of a shape.

## fizz.getVelocity(s)
Returns the velocity of a shape.

## fizz.setVelocity(s, xv, yv)
Sets the velocity of a shape.

## fizz.getDisplacement(s)
Returns the accumulated separation vector of a shape for the last collision step.

## fizz.update(dt)
Updates the simulation.
To avoid tunneling, you want to use a constant delta value.

# Shapes
## shape.x, shape.y
Center position of circle and rectangle shapes.
Starting point for line segments.

## shape.x2, shape.y2
Ending point for line segments.

## shape.r
Radius for circle shapes.

## shape.hw, shape.hh
Half-width and half-height extents for rectangle shapes.

## shape.xv, shape.yv
Velocity of a dynamic or kinematic shape.

## shape.sx, shape.sy
Accumulated displacement vector of the shape.

## shape.mass, shape.imass
Mass and inverse mass of the shape.

## shape.friction
Friction value applied when the edges of two shapes are touching.
As this value increases, the shape will slow down when sliding on top of other shapes.
Must be between 0 and 1.

## shape.bounce
Bounce or restitution value of the shape.
As this value increases, the shape will bounce more elastically when colliding with other shapes.
Must be between 0 and 1.

## shape.damping
Linear damping of the shape.
The damping value slows the velocity of moving shapes over time.
Must be between 0 and infinity.

## shape.gravity
Gravity scale of the shape which is multiplied by the global gravity value.
Set this to 0 and your shape will not be affected by gravity.
When negative, the shape will levitate.

## shape.onCollide(a, b, nx, ny, pen)
Collision callback providing the two colliding shapes, the collision normal and the penetration depth.
If this callback returns false the collision will be ignored.
Shapes should not be moved or destroyed during this callback.


# Limitations
## Torque
Torque and rotation are not supported.
This has several implications, most notably with circle shapes.
Circle shapes are axis-aligned, so they never "spin" or "roll".
Axis-aligned circles with friction behave like the wheels of a car while the breaks are on.
If you want to simulate torque, I would suggest a more sophisticated library, like Box2D.
For simple platform games, you could always draw or animate your objects as if they are rotating.

## Tunneling
![Tunneling](https://bytebucket.org/itraykov/fizzx/raw/master/images/tunnel.gif)

Since the library uses non-continuous collision detection, it's possible for shapes that move at a high velocity to "tunnel" or pass through other shapes.
This problem can be accommodated in a few ways.
First, make sure fizz.maxVelocity is defined within a reasonable range.
Second, set up your game loop to update the simulation with a constant time step.
This will make sure that the game will play the same on any machine.
Here is an example of how to update the simulation with a constant time step:

      accum = 0
      step = 1/60
      function update(dt)
        accum = accum + dt
        while accum >= step do
          fizz.update(step)
          accum = accum - step
        end
      end

## Repartitioning
Manually changing the position of shapes affects the partitioning system.
After modifying these values, you have to repartition the particular shape, for example:

      shape.x = 100
      shape.y = 100
      fizz.repartition(shape)

An alternative approach is to use the built in functions:

      fizz.positionShape(100, 100)

Note that changing the size of shapes affects the partition system as well:

      circle.r = circle.r + 5
      fizz.repartition(circle)

If you explicitly disable partitioning, then you can ignore this limitation.

## Stacking
![Stacking](https://bytebucket.org/itraykov/fizzx/raw/master/images/stack.gif)

Piling two or more dynamic shapes results in jittery behavior, because there is no simple way to figure out which collision pair should be resolved first.
This may cause one shape to overlap another in the stack even after their collisions have been resolved.

## Ledges
![Ledges](https://bytebucket.org/itraykov/fizzx/raw/master/images/ledge.gif)

This issue occurs with rows of static rectangle shapes.
When a dynamic shape is sliding on top of the row it may get "blocked" by the ledge between rects.
The best solution is to use line segments to represent platforms.

# License
The MIT License (MIT)

Copyright (c) 2014

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.