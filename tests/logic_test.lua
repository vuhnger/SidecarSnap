package.path = "./SidecarSnap.spoon/?.lua;" .. package.path
local logic = require("logic")

local main = { x = 0, y = 0, w = 1728, h = 1117 }
local ipadLeft = { x = -1180, y = 297, w = 1180, h = 820 }
local ipadRight = { x = 1728, y = 297, w = 1180, h = 820 }

local function eq(actual, expected, label)
  if actual ~= expected then
    error(("%s: expected %s, got %s"):format(label, tostring(expected), tostring(actual)), 2)
  end
end

eq(logic.blockedEdge({ x = 0, y = 500 }, main, ipadRight), "left", "push left with iPad on right")
eq(logic.blockedEdge({ x = 1727.98, y = 500 }, main, ipadLeft), "right", "push right with iPad on left")
eq(logic.blockedEdge({ x = 1727.98, y = 500 }, main, ipadRight), nil, "right edge leads to the iPad")
eq(logic.blockedEdge({ x = 0, y = 500 }, main, ipadLeft), nil, "left edge leads to the iPad")
eq(logic.blockedEdge({ x = 800, y = 500 }, main, ipadLeft), nil, "cursor away from any edge")

local x, y = logic.origin("right", main, ipadLeft)
eq(x, 1728, "right origin x")
eq(y, 297, "right origin y aligns bottoms")
x, y = logic.origin("left", main, ipadRight)
eq(x, -1180, "left origin x")
eq(y, 297, "left origin y aligns bottoms")

local step = logic.newCounter(3)
eq(step("right"), nil, "push 1")
eq(step("right"), nil, "push 2")
eq(step("right"), nil, "push 3")
eq(step("right"), nil, "push 4")
eq(step("right"), "right", "push 5 fires")
eq(step("right"), nil, "counter resets after firing")

step = logic.newCounter(3)
for _ = 1, 4 do step("right") end
eq(step(nil), nil, "leaving the edge")
eq(step("right"), nil, "leaving the edge resets the count")

step = logic.newCounter(3)
for _ = 1, 4 do step("right") end
eq(step("left"), nil, "switching sides resets the count")

local sleep = logic.newSleepTracker()
sleep.willSleep(true)
eq(sleep.didWake(), true, "reconnect when the iPad was connected at sleep")
eq(sleep.didWake(), false, "a second wake does not reconnect again")

sleep = logic.newSleepTracker()
sleep.willSleep(false)
eq(sleep.didWake(), false, "no reconnect when the iPad was not connected at sleep")

sleep = logic.newSleepTracker()
eq(sleep.didWake(), false, "no reconnect on a wake without a recorded sleep")

print("all tests passed")
