local obj = {}
obj.__index = obj

obj.name = "SidecarSnap"
obj.version = "0.2.0"
obj.author = "vuhnger"
obj.homepage = "https://github.com/vuhnger/SidecarSnap"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.pushThreshold = 15
obj.namePatterns = { "Sidecar", "iPad" }
obj.reconnectOnWake = true
obj.deviceName = nil
obj.reconnectAttempts = 5
obj.reconnectDelay = 3

local logic = dofile(hs.spoons.resourcePath("logic.lua"))
local helper = hs.spoons.resourcePath("bin/sidecar-connect")
local log = hs.logger.new("SidecarSnap", "info")

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

function obj:reconnect(attempt)
  attempt = attempt or 1
  if self:ipadScreen() then return end
  if not hs.fs.attributes(helper) then
    log.w("bin/sidecar-connect is missing, run install.sh again to build it")
    return
  end
  local args = self.deviceName and { self.deviceName } or {}
  self.task = hs.task.new(helper, function(code, _, stderr)
    if code == 0 then return end
    log.i(("reconnect attempt %d failed: %s"):format(attempt, stderr))
    if attempt < self.reconnectAttempts then
      self.retryTimer = hs.timer.doAfter(self.reconnectDelay, function() self:reconnect(attempt + 1) end)
    end
  end, args):start()
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

  local sleep = logic.newSleepTracker()
  local events = hs.caffeinate.watcher
  self.sleepWatcher = events.new(function(event)
    if event == events.systemWillSleep then
      sleep.willSleep(self:ipadScreen() ~= nil)
    elseif event == events.systemDidWake and self.reconnectOnWake and sleep.didWake() then
      self.retryTimer = hs.timer.doAfter(self.reconnectDelay, function() self:reconnect() end)
    end
  end):start()

  self:refresh()
  return self
end

function obj:stop()
  for _, k in ipairs({ "watcher", "tap", "sleepWatcher", "retryTimer" }) do
    if self[k] then self[k]:stop() end
  end
  if self.task and self.task:isRunning() then self.task:terminate() end
  return self
end

return obj
