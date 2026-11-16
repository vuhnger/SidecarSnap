local obj = {}
obj.__index = obj

obj.name = "SidecarSnap"
obj.version = "0.1.0"
obj.author = "vuhnger"
obj.homepage = "https://github.com/vuhnger/SidecarSnap"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.pushThreshold = 15
obj.namePatterns = { "Sidecar", "iPad" }

local logic = dofile(hs.spoons.resourcePath("logic.lua"))

function obj:ipadScreen()
  for _, s in ipairs(hs.screen.allScreens()) do
    local n = s:name() or ""
    for _, pattern in ipairs(self.namePatterns) do
      if n:match(pattern) then return s end
    end
  end
  return nil
end

function obj:refresh()
  if self:ipadScreen() then self.tap:start() else self.tap:stop() end
end

function obj:start()
  local step = logic.newCounter(self.pushThreshold)
  self.tap = hs.eventtap.new({ hs.eventtap.event.types.mouseMoved }, function()
    local s = self:ipadScreen()
    if not s then return false end
    local main, ipad = hs.screen.primaryScreen():fullFrame(), s:fullFrame()
    local edge = step(logic.blockedEdge(hs.mouse.absolutePosition(), main, ipad))
    if edge then s:setOrigin(logic.origin(edge, main, ipad)) end
    return false
  end)
  self.watcher = hs.screen.watcher.new(function() self:refresh() end):start()
  self:refresh()
  return self
end

function obj:stop()
  if self.watcher then self.watcher:stop() end
  if self.tap then self.tap:stop() end
  return self
end

return obj
