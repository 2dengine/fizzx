-- let's calculate some constant!
-- jump heights
local maxjumpH = 16*4
local minjumpH = 16*1
-- jump time to apex
local maxjumpT = 0.4
-- gravity
local g = (2*maxjumpH)/(maxjumpT^2)
-- initial jump velocity
local initjumpV = math.sqrt(2*g*maxjumpH)
-- jump termination velocity
local termjumpV = math.sqrt(initjumpV^2 + 2*-g*(maxjumpH - minjumpH))
-- jump termination time
local termjumpT = maxjumpT - (2*(maxjumpH - minjumpH)/(initjumpV + termjumpV))
-- default jump termination
local jumpTerm = termjumpV

-- fizz module
local fizz = require("fizzx")
fizz.setGravity(0, g)

local player

-- give us some stuff to play with
function love.load()
  -- tile size
  local tile = 16
  local tile2 = tile/2
  -- map
  local map =
  {
    1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 
    1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 
    1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 2, 2, 2, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 
    1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 
    1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 2, 2, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 
    1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 
    1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 2, 2, 2, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 
    1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 
    1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 
    1, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 4, 1, 
    1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 4, 1, 1, 
    1, 2, 2, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 5, 0, 0, 0, 0, 0, 0, 4, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 4, 1, 1, 1, 
    1, 0, 0, 0, 1, 1, 1, 1, 0, 0, 5, 5, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 4, 1, 1, 1, 1, 1, 0, 0, 0, 5, 0, 0, 0, 5, 0, 4, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 1, 1, 1, 1, 
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
  }
  local h = 16
  local w = #map/h
  
  -- adjust window to map size
  love.window.setMode((w - 1)*tile, (h - 1)*tile)

  -- what each number means on the map
  local shapes =
  {
    -- solid block
    [1] = { 'static', 'rect', 0, 0, tile2, tile2 },
    -- one-sided platform: _
    [2] = { 'static', 'line', tile2, tile2, -tile2, tile2 },
    -- right slope: \
    [3] = { 'static', 'line', tile2, tile2, -tile2, -tile2 },
    -- left slope: /
    [4] = { 'static', 'line', tile2, -tile2, -tile2, tile2 },
    -- dynamic circle: O
    [5] = { 'dynamic', 'circle', 0, 0, tile2 }
  }
  
  -- create shapes
  for x = 0, w - 1 do
    for y = 0, h - 1 do
      local i = map[y*w + x + 1]
      local wx, wy = x*tile + tile2, y*tile - tile2
      local s2 = shapes[i]
      if s2 then
        -- copy
        local t = { unpack(s2) }
        local s = table.remove(t, 1)
        -- transform
        t[2] = t[2] + wx
        t[3] = t[3] + wy
        if t[1] == "line" then
          t[4] = t[4] + wx
          t[5] = t[5] + wy
        end
        -- create
        local shape
        if s == 'dynamic' then
          shape = fizz.addDynamic(unpack(t))
          shape.friction = 0.1
        else
          shape = fizz.addStatic(unpack(t))
        end
      end
    end
  end

  -- player
  player = fizz.addDynamic('rect', 3*tile, 10*tile, tile2/2, tile2/2)
  player.friction = 0.15
  -- player flags
  player.grounded = false
  player.jumping = false
  player.moving = false

  -- callback for player collisions
  function player:onCollide(b, nx, ny, pen)
    -- return false if you want to ignore the collision
    return true
  end

  -- process user input
  function player:checkInput(dt)
    -- get user input
    local left = love.keyboard.isDown('left')
    local right = love.keyboard.isDown('right')
    local jump = love.keyboard.isDown('space')

    -- get player velocity
    local vx, vy = fizz.getVelocity(player)
    -- get the player displacement
    local sx, sy = fizz.getDisplacement(player)

    -- something is pushing the player up?
    player.grounded = false
    if sy < 0 then
      player.grounded = true
      player.jumping = false
    end

    -- running (horizontal movement)
    player.moving = left or right
    if player.moving then
      -- movement vector
      local move = 1000
      if left then
        move = -1000
      end
      -- slower movement while in the air
      if not player.grounded then
        move = move/8
      end
      -- add to player velocity
      vx = vx + move*dt
    end

    -- jumping (vertical movement)
    if jump and not player.jumping and player.grounded then
      -- initiating a jump
      player.jumping = true
      vy = -initjumpV
    elseif not jump and player.jumping and not player.grounded then
      -- terminating a jump
      if player.yv < 0 and player.yv < -jumpTerm then
        vy = -jumpTerm
      end
      player.jumping = false
    end
    
    -- update player velocity
    fizz.setVelocity(player, vx, vy)
  end

  -- kinematic platform
  k = fizz.addKinematic('rect', 16*tile, 10*tile, 30, 10)
  k.yv = -50
end

-- update interval in seconds
local interval = 1/60
-- maximum frame skip
local maxsteps = 5
-- accumulator
local accum = 0

-- nothing too heavy
function love.update(dt)
  local steps = 0
  -- update the simulation
  accum = accum + dt
  while accum >= interval do
    -- handle player input
    player:checkInput(interval)
    
    -- update the simulation
    fizz.update(interval)

    accum = accum - interval
    steps = steps + 1
    if steps >= maxsteps then
      break
    end
  end
  
  -- warp the kinematic platform
  if k.y < -50 then
    k.y = 300
  end
end

function drawObject(v, r, g, b)
  local lg = love.graphics
  if v.shape == 'rect' then
    local x, y, w, h = v.x, v.y, v.hw, v.hh
    lg.setColor(r, g, b, 255)
    lg.rectangle("fill", x - w, y - h, w*2, h*2)
  elseif v.shape == 'circle' then
    local x, y, radius = v.x, v.y, v.r
    lg.setColor(r, g, b, 255)
    lg.circle("fill", x, y, radius, 32)
  elseif v.shape == 'line' then
    local x, y, x2, y2 = v.x, v.y, v.x2, v.y2
    lg.setColor(r, g, b, 255)
    lg.line(x, y, x2, y2)
  end
end

function love.draw()
  local lg = love.graphics
  for i, v in ipairs(fizz.statics) do
    drawObject(v, 127, 127, 127)
  end
  for i, v in ipairs(fizz.dynamics) do
    drawObject(v, 255, 127, 127)
  end
  for i, v in ipairs(fizz.kinematics) do
    drawObject(v, 255, 127, 255)
  end
  lg.setColor(255, 255, 255, 255)
  love.graphics.print("col checks:" .. fizz.getCollisionCount(), 0, 0)
  local mem = collectgarbage('count')
  mem = math.ceil(mem)
  love.graphics.print("memory:" .. mem, 0, 15)
  love.graphics.print("grounded: " .. tostring(player.grounded), 0, 30)
  love.graphics.print("jumping: " .. tostring(player.jumping), 0, 45)
  local jt = "instant"
  if jumpTerm > 0 then
    jt = "gradual"
  end
  love.graphics.print("jump-termination: " .. jt .. " (press j to toggle)", 0, 60)
end

function love.keypressed(k)
  if k == "p" then
    local p = fizz.getPartition()
    if p == "quad" then
      p = "none"
    else
      p = "quad"
    end
    fizz.setPartition(p)
  elseif k == "j" then
    if jumpTerm == 0 then
      jumpTerm = termjumpV
    else
      jumpTerm = 0
    end
  end
end