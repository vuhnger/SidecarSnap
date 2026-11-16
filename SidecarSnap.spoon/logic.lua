local M = {}

function M.blockedEdge(p, main, ipad)
  if p.x <= main.x and ipad.x >= main.x + main.w then return "left" end
  if p.x >= main.x + main.w - 1 and ipad.x + ipad.w <= main.x then return "right" end
  return nil
end

function M.origin(edge, main, ipad)
  local x = edge == "left" and main.x - ipad.w or main.x + main.w
  return x, main.y + main.h - ipad.h
end

function M.newCounter(threshold)
  local side, count = nil, 0
  return function(edge)
    if edge and edge == side then
      count = count + 1
    else
      side, count = edge, 0
    end
    if count > threshold then
      count = 0
      return edge
    end
    return nil
  end
end

return M
