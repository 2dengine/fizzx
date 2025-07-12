--[[
This file is part of the Fizz X library.
https://2dengine.com/doc/fizzx.html

MIT License

Copyright (c) 2012 2dengine LLC

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
]]

--- Broad-phase partitioning code
-- @module part
-- @alias partition

local grid = {}
local default = {}
local lookup = {}
local metadata = {}
local size = 100
local floor = math.floor

local function checkAgainst(cell, shape, func, ...)
  for other in pairs(cell) do
    if other ~= shape then
      func(shape, other, ...)
    end
  end
end

local function getCell(x, y, hw, hh)
  if hw > size or hh > size then
    return default
  end
  local i = floor(x/size)
  local j = floor(y/size)
  local row = grid[i]
  if not row then
    row = {}
    grid[i] = row
  end
  local cell = row[j]
  if not cell then
    cell = {}
    metadata[cell] = { i = i, j = j, n = 0 }
    row[j] = cell
  end
  return cell
end

local part = {}

--- Inserts a shape in the partitioned space.
-- @tparam Shape shape Shape
-- @tparam number x X-position
-- @tparam number y Y-position
-- @tparam number hw Half-width extents
-- @tparam number hh Half-height extents
function part.insert(shape, x, y, hw, hh)
  local new = getCell(x, y, hw, hh)
  local cell = lookup[shape]
  if cell == new then
    return
  end
  if cell then
    part.remove(shape)
  end
  new[shape] = shape
  lookup[shape] = new
  local meta = metadata[new]
  if meta then
    meta.n = meta.n + 1
  end
end

--- Removes a specific shape from the partitioned space.
-- @tparam Shape shape Shape
function part.remove(shape)
  local cell = lookup[shape]
  local meta = metadata[cell]
  if meta then
    meta.n = meta.n - 1
    if meta.n == 0 then
      grid[meta.i][meta.j] = nil
    end
  end
  cell[shape] = nil
  lookup[shape] = nil
end

--- Checks if a shape intersects with other shapes.
-- @tparam Shape shape Shape
-- @tparam function func Callback function
-- @tparam arguments ... Additional arguments passed to the callback function
function part.check(shape, func, ...)
  local cell = lookup[shape]
  if cell == default then
    checkAgainst(lookup, shape, func, ...)
  else
    local meta = metadata[cell]
    local i = meta.i
    local j = meta.j
    for x = i - 1, i + 1 do
      local row = grid[x]
      for y = j - 1, j + 1 do
        if row then
          local cell2 = row[y]
          if cell2 then
            checkAgainst(cell2, shape, func, ...)
          end
        end
      end
    end
    checkAgainst(default, shape, func, ...)
  end
end

--- Sets the current cell size of the partitioned space.
-- @tparam number cellsize Partition cell size
function part.setCellsize(cellsize)
  size = cellsize
end

--- Returns the current cell size of the partitioned space.
-- @treturn number Partition cell size
function part.getCellsize()
  return size
end

return part