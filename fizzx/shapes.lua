--- Shapes intersection code
-- @module shapes
-- @alias shape

local abs = math.abs
local sqrt = math.sqrt

local shape = {}

-- Constructors

shape.create = {}

--- Creates a new rectangle shape
-- @tparam number x Center x-position 
-- @tparam number y Center y-position 
-- @tparam number hw Half-width extent
-- @tparam number hw Half-height extent
-- @treturn table New shape
function shape.create.rect(x, y, hw, hh)
  return { shape = "rect", x = x, y = y, hw = hw, hh = hh }
end

--- Creates a new circle shape
-- @tparam number x Center x-position 
-- @tparam number y Center y-position 
-- @tparam number r Radius
-- @treturn table New shape
function shape.create.circle(x, y, r)
  return { shape = "circle", x = x, y = y, r = r }
end

--- Creates a new line segment shape
-- @tparam number x Starting point x-position 
-- @tparam number y Starting point y-position 
-- @tparam number x2 Ending point x-position
-- @tparam number y2 Ending point x-position
-- @treturn table New shape
function shape.create.line(x, y, x2, y2)
  return { shape = "line", x = x, y = y, x2 = x2, y2 = y2 }
end

-- Tests

shape.tests = {}

shape.tests.rect = {}

--- Tests two rectangles for intersection
-- @tparam table a First rectangle shape
-- @tparam table b Second rectangle shape
-- @tparam number dt Time interval
-- @treturn number Penetration normal x-component
-- @treturn number Penetration normal y-component
-- @treturn number Penetration depth
function shape.tests.rect.rect(a, b, dt)
  -- vector between the centers of the rects
  local dx, dy = a.x - b.x, a.y - b.y
  -- absolute distance between the centers of the rects
  local adx, ady = abs(dx), abs(dy)
  -- sum of the half-width extents
  local shw, shh = a.hw + b.hw, a.hh + b.hh
  -- no intersection if the distance between the rects
  -- is greater than the sum of the half-width extents
  if adx >= shw or ady >= shh then
    return
  end
  -- shortest separation for both the x and y axis
  local sx, sy = shw - adx, shh - ady
  if dx < 0 then
    sx = -sx
  end
  if dy < 0 then
    sy = -sy
  end
--[[
  -- ignore separation for explicitly defined edges
  if sx > 0 then
    if a.left or b.right then
      sx = 0
    end
  elseif sx < 0 then
    if a.right or b.left then
      sx = 0
    end
  end
  if sy > 0 then
    if a.bottom or b.top then
      sy = 0
    end
  elseif sy < 0 then
    if a.top or b.bottom then
      sy = 0
    end
  end
]]
  -- ignore the longer separation axis
  -- when both sx and sy are non-zero
  if abs(sx) < abs(sy) then
    if sx ~= 0 then
      sy = 0
    end
  else
    if sy ~= 0 then
      sx = 0
    end
  end
  -- penetration depth equals
  -- the length of the separation vector
  local pen = sqrt(sx*sx + sy*sy)
  -- todo: dist == 0 when the two rects have the same position?
  if pen > 0 then
    -- collision normal is the normalized separation vector (sx,sy)
    return sx/pen, sy/pen, pen
  end
end

--- Tests a rectangle versus a circle for intersection
-- @tparam table a Rectangle shape
-- @tparam table b Circle shape
-- @tparam number dt Time interval
-- @treturn number Penetration normal x-component
-- @treturn number Penetration normal y-component
-- @treturn number Penetration depth
function shape.tests.rect.circle(a, b, dt)
  -- vector between the centers of the two shapes
  local dx, dy = a.x - b.x, a.y - b.y
  -- absolute distance between the centers of the two shapes
  local adx, ady = abs(dx), abs(dy)
  -- find the shortest separation and the penetration depth
  local sx, sy = 0, 0
  local pen = 0
  local r = b.r
  local hw, hh = a.hw, a.hh
  if adx <= hw or ady <= hh then
    -- rectangle edge collision
    -- check the x and y axis
    -- no intersection if the distance between the shapes
    -- is greater than the sum of the half-width extents and the radius
    local hwr = hw + r
    local hhr = hh + r
    if adx >= hwr or ady >= hhr then
      return
    end
    -- shortest separation vector
    sx = hwr - adx
    sy = hhr - ady
    -- ignore the longer separation axis
    -- when both sx and sy are non-zero
    if sx < sy then
      if sx ~= 0 then
        sy = 0
      end
    else
      if sy ~= 0 then
        sx = 0
      end
    end
    -- penetration depth
    pen = sqrt(sx*sx + sy*sy)
  else
    -- rectangle corner collision
    -- check the dx and dy axis
    -- find the nearest point on the rect to the circle center
    local px, py = 0, 0
    if adx > hw then
      px = adx - hw
    end
    if ady > hh then
      py = ady - hh
    end
    -- no intersection if point is outside of the circle
    local dist = sqrt(px*px + py*py)
    if dist >= r then
      return
    end
    -- penetration depth equals the circle radius
    -- minus the distance of the nearest point vector
    pen = r - dist
    -- shortest separation vector
    sx, sy = px/dist*pen, py/dist*pen
  end
  -- correct the sign of the separation vector
  if dx < 0 then
    sx = -sx
  end
  if dy < 0 then
    sy = -sy
  end
  return sx/pen, sy/pen, pen
end

--- Tests a rectangle versus a line segment for intersection
-- @tparam table a Rectangle shape
-- @tparam table b Line segment shape
-- @tparam number dt Time interval
-- @treturn number Penetration normal x-component
-- @treturn number Penetration normal y-component
-- @treturn number Penetration depth
function shape.tests.rect.line(a, b, dt)
  -- normalize segment
  local x1, y1 = b.x, b.y
  local x2, y2 = b.x2, b.y2
  local dx, dy = x2 - x1, y2 - y1
  local d = sqrt(dx*dx + dy*dy)
  -- segment is degenerate
  if d == 0 then
    return
  end
  --local ndx, ndy = dx/d, dy/d
  -- rotate the segment axis
  -- 90 degrees counter-clockwise and normalize
  local nx, ny = -dy/d, dx/d

  -- test along the normal axis
  -- project velocity
  local xv, yv = a.xv or 0, a.yv or 0
  local v = -(nx*xv + ny*yv)
  -- ignore collision for one-sided segments
  if v <= 0 then
    return
  end
  -- project segment origin point
  local o = nx*x2 + ny*y2
  -- project rect center
  local x, y = a.x, a.y
  local c = nx*x + ny*y
  -- project rect extents
  local hw, hh = a.hw, a.hh
  local h = abs(nx*hw) + abs(ny*hh)
  -- find the penetration depth
  local pen = -(c - h - o)
  -- entirely on one side of the segment?
  if pen <= 0 or pen > h*2 then
    return
  end
  --[[
  -- was it previously on one side of the segment?
  local v2 = v*dt
  if v2 > 0 and pen - v2 > 1 then
    return
  end
  ]]
  -- segment axis elimination
  if x1 > x2 then
    x1, x2 = x2, x1
  end
  if y1 > y2 then
    y1, y2 = y2, y1
  end
  local cx = x + nx*pen
  if cx + hw < x1 or cx - hw > x2 then
    return
  end
  local cy = y + ny*pen
  if cy + hh < y1 or cy - hh > y2 then
    return
  end

  return nx, ny, pen
end

shape.tests.circle = {}

--- Tests two circles for intersection
-- @tparam table a Circle shape
-- @tparam table b Circle shape
-- @tparam number dt Time interval
-- @treturn number Penetration normal x-component
-- @treturn number Penetration normal y-component
-- @treturn number Penetration depth
function shape.tests.circle.circle(a, b, dt)
  -- vector between the centers of the circles
  local dx, dy = a.x - b.x, a.y - b.y
  -- squared distance between the centers of the circles
  local distSq = dx*dx + dy*dy
  -- sum of the radii
  local radii = a.r + b.r
  -- no intersection if the distance between the circles
  -- is greater than the sum of the radii
  if distSq >= radii*radii then
    return
  end
  -- distance between the centers of the circles
  local dist = sqrt(distSq)
  -- distance is zero when the two circles have the same position
  local nx, ny = 0, 1
  if dist > 0 then
    nx, ny = dx/dist, dy/dist
  end
  -- penetration depth equals the sum of the radii
  -- minus the distance between the intersecting circles
  local pen = radii - dist
  -- collision normal is the normalized vector between the circles
  return nx, ny, pen
end

--- Tests a circle versus a line segment for intersection
-- @tparam table a Circle shape
-- @tparam table b Line segment shape
-- @tparam number dt Time interval
-- @treturn number Penetration normal x-component
-- @treturn number Penetration normal y-component
-- @treturn number Penetration depth
function shape.tests.circle.line(a, b, dt)
  -- normalize segment
  local x1, y1 = b.x, b.y
  local x2, y2 = b.x2, b.y2
  local dx, dy = x2 - x1, y2 - y1
  local d = sqrt(dx*dx + dy*dy)
  -- segment is degenerate
  if d == 0 then
    return
  end
  local ndx, ndy = dx/d, dy/d
  -- test along the segment axis
  local s1 = ndx*x1 + ndy*y1
  local s2 = ndx*x2 + ndy*y2
  local cx, cy = a.x, a.y
  local c2 = ndx*cx + ndy*cy
  if c2 < s1 or c2 > s2 then
    return
  end
  -- test along the normal axis
  -- rotate the segment axis 90 degrees counter-clockwise
  local nx, ny = -ndy, ndx
  -- project velocity
  local xv, yv = a.xv or 0, a.yv or 0
  local v = -(nx*xv + ny*yv)--*dt
  -- ignore collision for one-sided segments
  if v <= 0 then
    return
  end
  -- project segment origin
  local o = nx*b.x + ny*b.y
  -- project circle center
  local c = nx*cx + ny*cy
  -- find separation
  local r = a.r
  local pen = -(c - r - o)
  -- entirely on one side of the segment?
  if pen <= 0 or pen > r*2 then
    return
  end
  --[[
  -- was it previously on one side of the segment?
  if v*dt > 0 and pen - v*dt > 1 then
    return
  end
  ]]
  return nx, ny, pen
end

shape.tests.line = {}

--- Tests two line segments for intersection
-- @tparam table a First line segment
-- @tparam table b Second line segment
-- @tparam number dt Time interval
function shape.tests.line.line(a, b, dt)
  -- assert(false, "dynamic line collision unsupported")
end


--- Tests two shapes for intersection
-- @tparam table a First shape
-- @tparam table b Second shape
-- @tparam number dt Time interval
-- @treturn number Penetration normal x-component
-- @treturn number Penetration normal y-component
-- @treturn number Penetration depth
local tests = shape.tests
function shape.test(a, b, dt)
  local sa = a.shape
  local sb = b.shape
  -- find collision function
  local test = tests[sa][sb]
  local r = false
  -- swap the colliding shapes?
  if test == nil then
    test = tests[sb][sa]
    a, b = b, a
    r = true
  end
  local x, y, p = test(a, b, dt)
  -- reverse direction of the collision normal
  if r == true and x and y then
    x, y = -x, -y
  end
  return x, y, p
end

--- Utility functions

--- Tests two shapes for intersection
-- @tparam table shape Shape
-- @treturn number Total area of the shape
local pi = math.pi
function shape.area(s)
  local t = s.shape
  local a = 0
  if t == "rect" then
    a = s.hw*s.hh*4
  elseif t == "circle" then
    a = s.r*s.r*pi
  end
  return a
end

--- Returns center position and half width/height extents for any shape
-- @tparam table shape Shape
-- @treturn number X-position
-- @treturn number Y-position
-- @treturn number Width extent
-- @treturn number Height extent
function shape.bounds(s)
  local x, y = s.x, s.y
  local hw, hh
  local t = s.shape
  if t == "rect" then
    hw, hh = s.hw, s.hh
  elseif t == "circle" then
    hw, hh = s.r, s.r
  elseif t == "line" then
    -- figure out extents
    local x2, y2 = s.x2, s.y2
    if x > x2 then
      x, x2 = x2, x
    end
    if y > y2 then
      y, y2 = y2, y
    end
    hw = (x2 - x)/2
    hh = (y2 - y)/2
    -- get the midpoint
    x = x + hw
    y = y + hh
  end
  return x, y, hw, hh
end

--- Changes the position of a shape
-- @tparam table shape Shape
-- @tparam number dx Change in x-position
-- @tparam number dy Change in y-position
function shape.translate(a, dx, dy)
  a.x = a.x + dx
  a.y = a.y + dy
  if a.shape == 'line' then
    a.x2 = a.x2 + dx
    a.y2 = a.y2 + dy
  end
end

return shape