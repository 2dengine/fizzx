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

function part.check(shape, ...)
  local cell = lookup[shape]
  if cell == default then
    checkAgainst(lookup, shape, ...)
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
            checkAgainst(cell2, shape, ...)
          end
        end
      end
    end
    checkAgainst(default, shape, ...)
  end
end

function part.setCellsize(cellsize)
  size = cellsize
end

function part.getCellsize()
  return size
end

return part