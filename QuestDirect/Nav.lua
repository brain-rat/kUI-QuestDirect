-- QuestDirect · Navigation
-- Focusing a quest: Blizzard's super-track (so the game's own pin and
-- distance follow it) plus a TomTom waypoint and arrow to its next stop.
-- Without TomTom it falls back to Blizzard's map pin.
-- Plan mode (Plan.lua) can also point the arrow at a spot, such as a quest giver.

local _, ns = ...
local QP = ns.QP

local Nav = {}
QP.Nav = Nav

local sqrt = math.sqrt

local function HasTomTom() return TomTom and TomTom.AddWaypoint and TomTom.RemoveWaypoint end

------------------------------------------------------------------------
-- Waypoint handling
------------------------------------------------------------------------

function Nav:RemoveWaypoint()
  if self.uid and HasTomTom() then pcall(TomTom.RemoveWaypoint, TomTom, self.uid) end
  self.uid, self.target = nil, nil
  if self.userPin and C_Map and C_Map.ClearUserWaypoint then
    pcall(C_Map.ClearUserWaypoint)
    self.userPin = nil
  end
end

local function Same(a, m, x, y)
  return a and a.m == m and math.abs(a.x - x) < 0.002 and math.abs(a.y - y) < 0.002
end

-- Point the arrow at the focused quest's next stop. Called often; only changes on a new target.
function Nav:Update()
  local id = QP.char.focus
  if not id then
    local p = self.point
    if not p then
      self:RemoveWaypoint()
      return
    end
    if Same(self.target, p.m, p.x, p.y) then return end
    self:RemoveWaypoint()
    self.target = { m = p.m, x = p.x, y = p.y, title = p.title }
    self.status = p.title
    self:AddWaypoint(p.m, p.x, p.y, p.title)
    QP:Emit("NAV_CHANGED")
    return
  end
  local q = QP.Quests:Get(id)
  if not q then return end
  local m, x, y, hopText, isHop = QP.Quests:Target(id)
  if not m then
    self:RemoveWaypoint()
    self.status = "no map location"
    QP:Emit("NAV_CHANGED")
    return
  end
  if Same(self.target, m, x, y) then return end
  self:RemoveWaypoint()
  local title = q.title
  if isHop and hopText and hopText ~= "" then
    title = q.title .. ": " .. hopText
  elseif q.complete then
    title = q.title .. " (turn in)"
  end
  self.target = { m = m, x = x, y = y, hop = isHop, title = title }
  self.status = isHop and (hopText or "travel") or (q.complete and "turn in" or "objective")

  self:AddWaypoint(m, x, y, title)
  QP:Emit("NAV_CHANGED")
end

function Nav:AddWaypoint(m, x, y, title)
  if HasTomTom() then
    local opts = { title = title, from = "QuestDirect", persistent = false, silent = true, crazy = true,
                   minimap = true, world = true, cleardistance = 0, arrivaldistance = QP.db.arrival }
    local callbacks = TomTom.DefaultCallbacks and TomTom:DefaultCallbacks(opts) or {}
    callbacks.distance = callbacks.distance or {}
    callbacks.distance[QP.db.arrival] = function() Nav:Arrived() end
    opts.callbacks = callbacks
    local ok, uid = pcall(TomTom.AddWaypoint, TomTom, m, x, y, opts)
    if ok then self.uid = uid end
  elseif C_Map and C_Map.SetUserWaypoint and UiMapPoint then
    -- Fallback: Blizzard's own map pin.
    local ok = pcall(C_Map.SetUserWaypoint, UiMapPoint.CreateFromCoordinates(m, x, y))
    self.userPin = ok or nil
  end
end

-- Point the arrow at a spot rather than a quest (a quest giver, the next hub).
function Nav:FocusPoint(p)
  QP.char.focus = nil
  self.point = p
  self:Update()
  QP:Emit("NAV_CHANGED")
end

function Nav:IsPoint(m, x, y)
  local p = self.point
  return p and not QP.char.focus and Same(p, m, x, y) or false
end

-- Reached the target: a travel hop moves on to the next leg; an objective area stays.
function Nav:Arrived()
  local t = self.target
  if not t then return end
  if t.hop then
    self.target = nil
    C_Timer.After(1, function() Nav:Update() end)
  end
end

------------------------------------------------------------------------
-- Focus
------------------------------------------------------------------------

function Nav:Focus(questID, quiet)
  QP.char.focus = questID
  self.point = nil
  self.syncing = true
  if C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID then pcall(C_SuperTrack.SetSuperTrackedQuestID, questID) end
  self.syncing = false
  self.target = nil
  self:Update()
  local q = QP.Quests:Get(questID)
  if q and not quiet then
    QP:Print("Navigating to %s%s.", q.title, self.target and "" or " (it has no map location yet)")
  end
  QP:Emit("NAV_CHANGED")
end

function Nav:Clear(announce)
  QP.char.focus = nil
  self.point = nil
  self:RemoveWaypoint()
  if C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID then
    self.syncing = true
    pcall(C_SuperTrack.SetSuperTrackedQuestID, 0)
    self.syncing = false
  end
  if announce then QP:Print("Stopped navigating.") end
  QP:Emit("NAV_CHANGED")
end

function Nav:Toggle(questID)
  if QP.char.focus == questID then self:Clear(true) else self:Focus(questID) end
end

-- The nearest quest you can see in the tracker (objective or turn-in, whichever is closer).
function Nav:Nearest(except)
  local best, bestD
  for _, q in ipairs(QP.Quests.list) do
    if q.id ~= except and not QP.char.hidden[q.id] and q.distance then
      if not bestD or q.distance < bestD then best, bestD = q, q.distance end
    end
  end
  return best
end

function Nav:FocusNearest()
  local q = self:Nearest(QP.char.focus)
  if q then self:Focus(q.id) else QP:Print("No quest with a known distance.") end
end

------------------------------------------------------------------------
-- Route mode
------------------------------------------------------------------------

-- Open path from the player through every point: nearest neighbour, then 2-opt.
function Nav.PlanPath(start, pts, w, h)
  local function d(a, b)
    local dx, dy = (a.x - b.x) * w, (a.y - b.y) * h
    return sqrt(dx * dx + dy * dy)
  end
  local left, path, cur = {}, {}, start
  for i, p in ipairs(pts) do left[i] = p end
  while #left > 0 do
    local bi, bd = 1, nil
    for i, p in ipairs(left) do
      local dd = d(cur, p)
      if not bd or dd < bd then bi, bd = i, dd end
    end
    cur = table.remove(left, bi)
    path[#path + 1] = cur
  end
  -- 2-opt on the open path (start fixed at the player)
  local n = #path
  local full = { start }
  for i = 1, n do full[i + 1] = path[i] end
  for _ = 1, 20 do
    local improved = false
    for i = 1, #full - 2 do
      for j = i + 1, #full - 1 do
        local a, b, c = full[i], full[i + 1], full[j + 1]
        local e = full[j + 2]
        local before = d(a, b) + (e and d(c, e) or 0)
        local after = d(a, c) + (e and d(b, e) or 0)
        if after < before - 0.01 then
          local lo, hi = i + 1, j + 1
          while lo < hi do
            full[lo], full[hi] = full[hi], full[lo]
            lo, hi = lo + 1, hi - 1
          end
          improved = true
        end
      end
    end
    if not improved then break end
  end
  table.remove(full, 1)
  local len, prev = 0, start
  for _, p in ipairs(full) do
    len = len + d(prev, p)
    prev = p
  end
  return full, len
end

-- Route button / /qd route: the full plan (pick-ups, hand-ins, objectives).
function Nav:PlanRoute() QP.Plan:Build(true) end
function Nav:ToggleRoute() QP.Plan:Toggle() end

function Nav:RouteNext(after)
  local route = QP.char.route
  if not route then return nil end
  local seen = after == nil
  for _, id in ipairs(route) do
    local q = QP.Quests:Get(id)
    if seen and q and id ~= after then return id end
    if id == after then seen = true end
  end
  return nil
end

-- Drop finished quests from the route; move focus on.
function Nav:Advance(fromID)
  if QP.Plan:Active() then return QP.Plan:Check() end
  local route = QP.char.route
  if route then
    for i = #route, 1, -1 do
      if not QP.Quests:Get(route[i]) then table.remove(route, i) end
    end
    if #route == 0 then
      QP.char.route = nil
      QP:Print("Route finished.")
    end
  end
  if not QP.db.autoNext then return self:Clear() end
  local nextID = self:RouteNext(fromID)
  if nextID then return self:Focus(nextID) end
  local q = self:Nearest(fromID)
  if q then self:Focus(q.id) else self:Clear() end
end

------------------------------------------------------------------------
-- Events
------------------------------------------------------------------------

local lastComplete = {}

QP:Listen("QUESTS_CHANGED", function()
  if QP.Plan:Active() then
    QP.Plan:Check()
    Nav:Update()
    return
  end
  local focus = QP.char.focus
  if focus and not QP.Quests:Get(focus) then
    Nav:Advance(focus)
    return
  end
  -- Focused quest just became complete: the target becomes the turn-in.
  -- In route mode, a completed quest that turns in elsewhere stays focused until handed in.
  if focus then
    local q = QP.Quests:Get(focus)
    if q and q.complete and not lastComplete[focus] then Nav.target = nil end
    lastComplete[focus] = q and q.complete
  end
  Nav:Update()
end)

QP:Listen("QUEST_GONE", function(questID)
  if QP.Plan:Active() then
    C_Timer.After(0.5, function()
      QP.Quests:Refresh()
      QP.Plan:Check()
    end)
    return
  end
  if questID == QP.char.focus then
    C_Timer.After(0.5, function()
      QP.Quests:Refresh()
      Nav:Advance(questID)
    end)
  end
end)

-- Focusing a quest on Blizzard's map or quest log follows here too.
QP:On("SUPER_TRACKING_CHANGED", function()
  if not QP.db or Nav.syncing then return end
  local id = C_SuperTrack.GetSuperTrackedQuestID and C_SuperTrack.GetSuperTrackedQuestID()
  if id and id > 0 and id ~= QP.char.focus and QP.Quests:Get(id) then
    QP.char.focus = id
    Nav.target = nil
    Nav:Update()
    QP:Emit("NAV_CHANGED")
  end
end)

QP:Listen("LOGIN", function()
  -- TomTom has its own quest-objective waypoint; let QuestDirect drive the arrow instead.
  if TomTom and TomTom.SuppressFeature then pcall(TomTom.SuppressFeature, TomTom, "QuestDirect", "poi") end
  C_Timer.After(2, function()
    QP.Quests:Refresh()
    if QP.char.focus and QP.Quests:Get(QP.char.focus) then Nav:Focus(QP.char.focus, true) end
  end)
end)
