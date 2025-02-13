--- The main module that you need to require in your game
-- @module fizz
-- @alias fizz
local lib = (...)
lib = lib:gsub('%.init$', '')

local tremove = table.remove
local sqrt = math.sqrt

-- Partitioning
local part = require(lib..".partition")
local qinsert = part.insert
local qremove = part.remove
local qcheck = part.check

-- Collisions

local shape = require(lib..".shapes")
local screate = shape.create
local sarea = shape.area
local sbounds = shape.bounds
local stranslate = shape.translate
local stest = shape.test

-- Internal data

-- list of shapes
local statics = {}
local dynamics = {}
local kinematics = {}

-- global gravity
local gravityx = 0
local gravityy = 0
-- positional correction
-- treshold between 0.01 and 0.1
--local slop = 0.01
-- correction between 0.2 to 0.8
--local percentage = 0.2

-- maximum velocity limit of moving shapes
local maxVelocity = 1000
-- some stats
local nchecks = 0

-- Internal functionality

-- repartition moved or modified shapes
local function repartition(s)
  -- reinsert
  local x, y, hw, hh = sbounds(s)
  qinsert(s, x, y, hw, hh)
end

local function addShapeType(list, t, ...)
  local func = screate[t]
  assert(func, "invalid shape type")
  local s = func(...)
  s.list = list
  list[#list + 1] = s
  repartition(s)
  return s
end

-- changes the position of a shape
local function changePosition(a, dx, dy)
  stranslate(a, dx, dy)
  repartition(a)
end

local function changePositionSafe(a, dx, dy)
  local d = dx*dx + dy*dy
  if d > maxVelocity*maxVelocity then
    local n = maxVelocity/sqrt(d)
    dx = dx*n
    dy = dy*n
  end
  changePosition(a, dx, dy)
end

-- resolves collisions
local function solveCollision(a, b, nx, ny, pen)
  -- shape a must be dynamic
  --assert(a.list == dynamics, "collision pair error")
  -- relative velocity
  local avx = a.xv
  local avy = a.yv
  local bvx = b.xv or 0
  local bvy = b.yv or 0
  local vx = avx - bvx
  local vy = avy - bvy

  -- penetration component
  -- dot product of the velocity and collision normal
  local ps = vx*nx + vy*ny
  -- objects moving apart?
  if ps > 0 then
    return
  end
  -- restitution [1-2]
  -- r = max(r1, r2)
  local r = a.bounce
  local r2 = b.bounce
  if r2 and r2 > r then
    r = r2
  end
  ps = ps*(r + 1)

  -- tangent component
  local ts = vx*ny - vy*nx
  -- friction [0-1]
  -- r = r/(1/mass1 + 1/mass2)
  local f = a.friction
  local f2 = b.friction
  if f2 and f2 < f then
    f = f2
  end
  ts = ts*f
  
  -- coulomb's law (optional)
  -- clamps the tangent component so that
  -- it doesn't exceed the separation component
  if ts < 0 then
    if ts < ps then
      ts = ps
    end
  elseif -ts < ps then
    ts = -ps
  end

  -- integration
  local jx = nx*ps + ny*ts
  local jy = ny*ps - nx*ts
  -- impulse
  local ma = a.imass
  local mb = b.imass or 0
  local mc = ma + mb
  jx = jx/mc
  jy = jy/mc

  -- adjust the velocity of shape a
  a.xv = avx - jx*ma
  a.yv = avy - jy*ma
  if b.list == dynamics then
    -- adjust the velocity of shape b
    b.xv = bvx + jx*mb
    b.yv = bvy + jy*mb
--[[
    -- positional correction (wip)
    if pen > slop then
      local pc = (pen - slop)/mc*percentage
      local pcA = pc*ma
      local pcB = pc*mb
      local sx, sy = -nx*pcB, -ny*pcB
      -- store the separation for shape b
      b.sx = b.sx + sx
      b.sy = b.sy + sy
      changePosition(b, sx, sy)
      --pen = pen*pcA
      pen = pcA
    end
    ]]
  end

  -- separation
  local sx, sy = nx*pen, ny*pen
  -- store the separation for shape a
  a.sx = a.sx + sx
  a.sy = a.sy + sy
  -- separate the pair by moving shape a
  changePosition(a, sx, sy)
end

-- check and report collisions
local function collision(a, b, dt)
  -- track the number of collision checks (optional)
  nchecks = nchecks + 1
  local nx, ny, pen = stest(a, b, dt)
  if pen == nil then
    return
  end
  --assert(pen > 0, "collision depth error")
  -- collision callbacks
  -- ignores collision if either callback returned false
  local func1 = a.onCollide
  if func1 then
    if func1(a, b, nx, ny, pen) == false then
      return
    end
  end
  local func2 = b.onCollide
  if func2 then
    if func2(b, a, -nx, -ny, pen) == false then
      return
    end
  end
  solveCollision(a, b, nx, ny, pen)
end

-- Public functionality

local fizz = {}

--- Updates the simulation.
-- To avoid tunneling, you want to use a fixed time step.
-- @tparam number delta Delta value
-- @tparam number iterations Number of iterations
function fizz.update(dt, it)
  it = it or 1
  -- track the number of collision checks (optional)
  nchecks = 0

  -- update velocity vectors
  local xg = gravityx*dt
  local yg = gravityy*dt
  for i = 1, #dynamics do
    local d = dynamics[i]
    -- damping
    local c = 1 + d.damping*dt
    local xv = d.xv/c
    local yv = d.yv/c
    -- gravity
    local g = d.gravity
    d.xv = xv + xg*g
    d.yv = yv + yg*g
    -- reset separation
    d.sx = 0
    d.sy = 0
  end
  
  -- iterations
  dt = dt/it
  for j = 1, it do
    -- move kinematic shapes
    for i = 1, #kinematics do
      local k = kinematics[i]
      changePositionSafe(k, k.xv*dt, k.yv*dt)
    end
    -- move dynamic shapes
    for i = 1, #dynamics do
      local d = dynamics[i]
      -- move to new position
      changePositionSafe(d, d.xv*dt, d.yv*dt)
      -- check and resolve collisions
      -- query for potentially colliding shapes
      qcheck(d, collision, dt)
    end
  end
end

--- Gets the global gravity
-- @treturn number X-component of gravity
-- @treturn number Y-component of gravity
function fizz.getGravity()
  return gravityx, gravityy
end

-- Sets the global gravity
-- @tparam number gx X-component of gravity
-- @tparam number gy Y-component of gravity
function fizz.setGravity(x, y)
  gravityx, gravityy = x, y
end

--- Creates a static shape.
-- Static shapes are immovable and do not move or respond to collisions
-- @tparam tstring shape Shape type: "rect", "circle" or "line"
-- @tparam arg Center position and extents for rectangles, radius for circles or starting and ending point for lines
-- @treturn shape New shape object
function fizz.addStatic(s, ...)
  return addShapeType(statics, s, ...)
end

--- Creates a kinematic shape.
-- Kinematic shapes have a velocity but do not respond to collisions.
-- This can be useful for simulating moving platforms.
-- @tparam tstring shape Shape type: "rect", "circle" or "line"
-- @tparam arg Center position and extents for rectangles, radius for circles or starting and ending point for lines
-- @treturn shape New shape object
function fizz.addKinematic(s, ...)
  local o = addShapeType(kinematics, s, ...)
  o.xv, o.yv = 0, 0
  return o
end

--- Creates a dynamic shape.
-- Dynamic shapes can move and collide with other shapes.
-- @tparam tstring shape Shape type: "rect", "circle" or "line"
-- @tparam arg Center position and extents for rectangles, radius for circles or starting and ending point for lines
-- @treturn shape New shape object
function fizz.addDynamic(s, ...)
  local o = addShapeType(dynamics, s, ...)
  o.friction = 1
  o.bounce = 0
  o.damping = 0
  o.gravity = 1
  o.xv, o.yv = 0, 0
  o.sx, o.sy = 0, 0
  fizz.setDensity(o, 1)
  return o
end

-- Sets the mass of a shape based on its area.
-- @tparam table shape Shape
-- @tparam number density Density
-- @treturn number Mass
function fizz.setDensity(s, d)
  local m = sarea(s)*d
  fizz.setMass(s, m)
  return m
end

--- Sets the mass of shape.
-- @tparam table shape Shape
-- @tparam number mass Mass
function fizz.setMass(s, m)
  s.mass = m
  local im = 0
  if m > 0 then
    im = 1/m
  end
  s.imass = im
end

--- Gets the mass of shape.
-- @tparam table shape Shape
-- @tparam number mass Mass value
-- @treturn number Mass
function fizz.getMass(s, m)
  return s.mass
end

--- Removes a shape from the simulation.
-- @tparam table shape Shape
function fizz.removeShape(s)
  local t = s.list
  for i = 1, #t do
    if t[i] == s then
      s.list = nil
      tremove(t, i)
      qremove(s)
      break
    end
  end
end

--- Gets the position of a shape (starting point for line shapes).
-- @tparam table shape Shape
-- @treturn number X position
-- @treturn number Y position
function fizz.getPosition(a)
  return a.x, a.y
end

--- Moves the shape to a given position.
-- This function is used to "teleport" shapes.
-- @tparam table shape Shape
-- @tparam number X position
-- @tparam number Y position
function fizz.setPosition(a, x, y)
  changePosition(a, x - a.x, y - a.y)
end

--- Returns the velocity of a shape.
-- @tparam table shape Shape
-- @treturn number X velocity
-- @treturn number Y velocity
function fizz.getVelocity(a)
  return a.xv, a.yv
end

--- Sets the velocity of a shape
-- @tparam table shape Shape
-- @tparam number xv X velocity
-- @tparam number yv Y velocity
function fizz.setVelocity(a, xv, yv)
  a.xv = xv
  a.yv = yv
end

--- Returns the accumulated separation vector of a shape for the last collision step.
-- @tparam table shape Shape
-- @treturn number X separation
-- @treturn number Y separation
function fizz.getDisplacement(a)
  return a.sx, a.sy
end

--- Gets the number of collision checks performed between pairs of shapes during the last update.
-- @treturn number Number of collision checks
function fizz.getCollisionCount()
  return nchecks
end

--- Sets the maximum velocity treshold.
-- @tparam number velocity Maximum velocity
function fizz.setMaxVelocity(v)
  maxVelocity = v
end

--- Sets the default cell size used for partitioning.
-- @tparam number size Cell size
fizz.setCellsize = part.setCellsize

--- Gets the default cell size used for partitioning.
-- @treturn number Cell size
fizz.getCellsize = part.getCellsize

-- Public access to some tables
fizz.repartition = repartition
fizz.statics = statics
fizz.dynamics = dynamics
fizz.kinematics = kinematics

return fizz