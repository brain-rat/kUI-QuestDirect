-- QuestDirect · Plan
-- One ordered plan for the zone you're in: which quest givers to visit, what to
-- hand in and pick up at each, which objectives to do. Then where to head next
-- once the zone is done.
--
-- Quests right for your level come first, then harder ones, then the rest (see
-- Offers:Band). Inside that, the order is the shortest walk that keeps its rules (do
-- it before handing it in; hand in A before picking up its follow-up), with a lean
-- towards picking up and handing in early, so you leave town with everything you can
-- do on the way.
-- It's deterministic and sticky: the same situation gives the same plan, and a
-- re-plan keeps the order you had unless a change saves a real amount of walking.

local _, ns = ...
local QP = ns.QP

local P = { stops = nil, current = nil, elsewhere = {}, hub = nil, skipItems = {}, doneState = {} }
QP.Plan = P

local sqrt, floor, max, min = math.sqrt, math.floor, math.max, math.min
local MERGE_YARDS = 15     -- stops this close are one stop
local SAME_NPC_YARDS = 60  -- the same NPC name this close is the same NPC
local OBJ_MERGE_YARDS = 40 -- objectives this close are one "Do" stop
local EARLY_WEIGHT = 0.35  -- how strongly pick-ups and hand-ins are pulled forward
local AT_LEVEL_WEIGHT = 0.1 -- a smaller pull towards quests closest to your level
local STICKY_YARDS = 60    -- a re-plan only changes order to save at least this much
local STICKY_SHARE = 0.04  -- ...or this share of the walk, whichever is more

function P:Active() return QP.char.planOn and self.stops ~= nil end

------------------------------------------------------------------------
-- Ordering with "this before that" rules
------------------------------------------------------------------------

-- Open path from start through every stop.
--   stop.after  = { [stopIndex] = true }: stops that must come earlier
--   stop.weight = how much it matters to get there early (0 = only distance)
--   stop.key    = stable name, used to keep the previous order (seed)
--   stop.band   = stops in a lower band all come before stops in a higher one
-- Cost = walking distance + sum of weight x distance walked before reaching it.
-- Start: the seed order (new stops inserted where they cost least) or nearest
-- neighbour; then relocate and 2-opt moves that keep every rule.
function P.Order(start, stops, w, h, seed)
  local function d(a, b)
    local dx, dy = (a.x - b.x) * w, (a.y - b.y) * h
    return sqrt(dx * dx + dy * dy)
  end
  local n = #stops
  local function valid(p)
    local pos = {}
    for k, i in ipairs(p) do pos[i] = k end
    local top = 0
    for k, i in ipairs(p) do
      for j in pairs(stops[i].after or {}) do
        if pos[j] and pos[j] > k then return false end
      end
      local band = stops[i].band or 1
      if band < top then return false end
      top = band
    end
    return true
  end
  local function cost(p)
    local walked, total, prev = 0, 0, start
    for _, i in ipairs(p) do
      local s = stops[i]
      walked = walked + d(prev, s)
      total = total + (s.weight or 0) * walked
      prev = s
    end
    return walked + total, walked
  end

  local path = {}
  if seed then
    -- the order you had, then anything new where it fits best
    local old, new = {}, {}
    for i, s in ipairs(stops) do
      if s.rank then old[#old + 1] = i else new[#new + 1] = i end
    end
    table.sort(old, function(a, b) return stops[a].rank < stops[b].rank end)
    path = old
    if not valid(path) then path = {} for _, i in ipairs(old) do new[#new + 1] = i end end
    table.sort(new, function(a, b) return (stops[a].key or "") < (stops[b].key or "") end)
    for _, i in ipairs(new) do
      local bestPos, bestCost
      for pos = 1, #path + 1 do
        local cand = {}
        for k = 1, pos - 1 do cand[#cand + 1] = path[k] end
        cand[#cand + 1] = i
        for k = pos, #path do cand[#cand + 1] = path[k] end
        if valid(cand) then
          local c = cost(cand)
          if not bestCost or c < bestCost - 1e-6 then bestPos, bestCost = pos, c end
        end
      end
      table.insert(path, bestPos or (#path + 1), i)
    end
  else
    local placed, cur = {}, start
    for _ = 1, n do
      local bi, bd
      local lowest
      for i, s in ipairs(stops) do
        if not placed[i] and (not lowest or (s.band or 1) < lowest) then lowest = s.band or 1 end
      end
      for pass = 1, 2 do
        for i, s in ipairs(stops) do
          if not placed[i] then
            local ready = true
            if pass == 1 then
              if (s.band or 1) > lowest then ready = false end
              for j in pairs(s.after or {}) do
                if not placed[j] then ready = false break end
              end
            end
            if ready then
              local dd = d(cur, s) * (1 - min(0.5, s.weight or 0))
              if not bd or dd < bd - 1e-6 then bi, bd = i, dd end
            end
          end
        end
        if bi then break end -- pass 2 only if the rules loop
      end
      placed[bi] = true
      path[#path + 1] = bi
      cur = stops[bi]
    end
  end

  local best = cost(path)
  local function threshold()
    if not seed then return 0.5 end
    return max(STICKY_YARDS, STICKY_SHARE * best)
  end
  for _ = 1, (n > 45 and 2 or n > 30 and 4 or 10) do
    local improved = false
    -- move one stop somewhere else
    for i = 1, n do
      for j = 1, n do
        if i ~= j then
          local cand = {}
          for k = 1, n do if k ~= i then cand[#cand + 1] = path[k] end end
          table.insert(cand, j, path[i])
          local c = cost(cand)
          if c < best - threshold() and valid(cand) then path, best, improved = cand, c, true end
        end
      end
    end
    -- reverse a stretch
    for i = 1, n - 1 do
      for j = i + 1, n do
        local cand = {}
        for k = 1, i - 1 do cand[k] = path[k] end
        for k = i, j do cand[k] = path[j - (k - i)] end
        for k = j + 1, n do cand[k] = path[k] end
        local c = cost(cand)
        if c < best - threshold() and valid(cand) then path, best, improved = cand, c, true end
      end
    end
    if not improved then break end
  end
  local out = {}
  for k, i in ipairs(path) do out[k] = stops[i] end
  local _, walked = cost(path)
  return out, walked
end

------------------------------------------------------------------------
-- Building the plan
------------------------------------------------------------------------

local function FreeSlots()
  local maxQ = C_QuestLog.GetMaxNumQuestsCanAccept and C_QuestLog.GetMaxNumQuestsCanAccept() or 20
  return math.max(0, maxQ - #QP.Quests.list)
end

-- fresh: ignore the previous order (Re-plan from here).
function P:Build(announce, fresh)
  local Q, O = QP.Quests, QP.Offers
  local mapID, px, py = Q:PlayerPos()
  if not mapID then
    if announce then QP:Print("Can't plan here: your position isn't available.") end
    return
  end
  Q:Refresh()
  O:ReadLog()
  local w, h = O:MapSize(mapID)
  local function yards(a, b) return O:Yards(mapID, a.x, a.y, b.x, b.y) end

  local stops, objStop, turnStop = {}, {}, {}
  local elsewhere = {}
  local ready = {} -- Classic ids of quests ready to hand in
  local me = O:Me()

  -- NPC stops merge when they're on the same spot. later (a band) is for hand-ins of
  -- quests you haven't finished: that's a second visit, so it doesn't hold up what
  -- you can already pick up or hand in there.
  local function NpcStop(name, x, y, later)
    local generic = name == "Quest giver" or name == "Turn-in"
    for _, s in ipairs(stops) do
      local d = s.kind == "npc" and s.later == later and yards(s, { x = x, y = y })
      if d and (d <= MERGE_YARDS or (not generic and s.name == name and d <= SAME_NPC_YARDS)) then
        if s.name == "Quest giver" or s.name == "Turn-in" then s.name = name end
        return s
      end
    end
    local s = { kind = "npc", name = name, m = mapID, x = x, y = y, turnins = {}, pickups = {}, after = {}, later = later }
    s.key = generic and ("n:" .. floor(x * 100) .. "," .. floor(y * 100)) or ("n:" .. name)
    if later then s.key = s.key .. ":later" .. later end
    stops[#stops + 1] = s
    return s
  end

  -- Objectives close together are one stop, if they suit you equally: a harder quest
  -- doesn't get done early just because it's next to an easier one.
  local function ObjStop(q, x, y, band)
    for _, s in ipairs(stops) do
      if s.kind == "obj" and s.band == band and yards(s, { x = x, y = y }) <= OBJ_MERGE_YARDS then
        table.insert(s.quests, q.id)
        return s
      end
    end
    local s = { kind = "obj", quest = q.id, quests = { q.id }, key = "o:" .. q.id, m = mapID, x = x, y = y, after = {}, band = band }
    stops[#stops + 1] = s
    return s
  end

  local skip = self.skipItems
  local quests = {}
  for _, q in ipairs(Q.list) do quests[#quests + 1] = q end
  table.sort(quests, function(a, b) return a.id < b.id end)
  for _, q in ipairs(quests) do
    if not QP.char.hidden[q.id] and not q.failed and not skip[q.id] then
      local m, x, y, _, hop = Q:Target(q.id)
      local here = m == mapID and not hop
      if q.complete then
        if q.dbid then ready[q.dbid] = true end
        local spot = here and { name = (O:Ender(q, mapID) or {}).name or "Turn-in", x = x, y = y }
        if not spot then
          local e = O:Ender(q, mapID)
          if e and e.m == mapID then spot = e end
        end
        if spot then
          local s = NpcStop(spot.name, spot.x, spot.y)
          table.insert(s.turnins, q.id)
          turnStop[q.id] = s
        else
          local e = O:Ender(q)
          elsewhere[#elsewhere + 1] = { quest = q.id, title = q.title, zone = e and O.ZoneName(e.m), npc = e and e.name, m = e and e.m, x = e and e.x, y = e and e.y }
        end
      elseif here then
        local band = O:QuestBand(q, me)
        objStop[q.id] = ObjStop(q, x, y, band)
        -- Its turn-in, if that's in this zone too, comes after.
        local e = O:Ender(q, mapID)
        if e and e.m == mapID then
          local t = NpcStop(e.name, e.x, e.y, band)
          table.insert(t.turnins, q.id)
          t.pending = t.pending or {}
          t.pending[q.id] = true
          turnStop[q.id] = t
        end
      end
    end
  end

  -- Pick-ups from the whole zone: as many as your log has room for (hand-ins free up
  -- room too), the best for your level first, then nearest. /qd plan radius narrows it.
  local pickups = 0
  if QP.db.pickups then
    local room = FreeSlots()
    for _ in pairs(ready) do room = room + 1 end
    local offers = O:ForMap(mapID, ready)
    local list = {}
    for _, o in ipairs(offers) do
      o.distance = O:Yards(mapID, o.giver.x, o.giver.y, px, py)
      o.band = O:Band(o.level, me, o.elite)
      local range = QP.db.pickupRange
      if not range or range <= 0 or o.distance <= range then list[#list + 1] = o end
    end
    table.sort(list, function(a, b)
      if a.band ~= b.band then return a.band < b.band end
      if math.abs(a.distance - b.distance) > 1 then return a.distance < b.distance end
      return a.title < b.title
    end)
    for _, o in ipairs(list) do
      if pickups >= room then break end
      if not skip[o.title:lower()] then
      local s = NpcStop(o.giver.name, o.giver.x, o.giver.y)
      table.insert(s.pickups, o)
      pickups = pickups + 1
      if o.unlockedBy then
        local lq = O.log and O.log[o.unlockedBy]
        o.unlockQuest = lq and lq.id
      end
      end
    end
  end

  -- Stable, unique names for the stops (two stops for one NPC name get #2, #3...).
  local used = {}
  table.sort(stops, function(a, b)
    if a.kind ~= b.kind then return a.kind < b.kind end
    if (a.key or "") ~= (b.key or "") then return (a.key or "") < (b.key or "") end
    if a.x ~= b.x then return a.x < b.x end
    return a.y < b.y
  end)
  for _, s in ipairs(stops) do
    if s.key then
      used[s.key] = (used[s.key] or 0) + 1
      if used[s.key] > 1 then s.key = s.key .. "#" .. used[s.key] end
    end
  end

  -- Rules: objective before its turn-in; a turn-in before the follow-up it unlocks.
  local index = {}
  for i, s in ipairs(stops) do index[s] = i end
  for i, s in ipairs(stops) do
    if s.kind == "npc" then
      for qid in pairs(s.pending or {}) do
        local o = objStop[qid]
        if o and o ~= s then s.after[index[o]] = true end
      end
      for _, o in ipairs(s.pickups) do
        local t = o.unlockQuest and turnStop[o.unlockQuest]
        if t and t ~= s then s.after[index[t]] = true end
      end
    end
  end
  for i, s in ipairs(stops) do s.after[i] = nil end

  -- How much each stop wants to come early, and its place in the previous plan.
  local seedRank = {}
  local prev = not fresh and QP.char.planMap == mapID and QP.char.planOrder
  for i, k in ipairs(prev or {}) do seedRank[k] = seedRank[k] or i end
  local seeded = false
  for _, s in ipairs(stops) do
    if s.kind == "obj" then
      s.weight = 0
      for _, qid in ipairs(s.quests) do
        local r = seedRank["o:" .. qid]
        if r and (not s.rank or r < s.rank) then s.rank = r end
        local q = Q:Get(qid)
        local diff = q and (q.level or 0) > 0 and q.level - me.level
        if diff and diff >= -2 and diff <= 1 then s.weight = AT_LEVEL_WEIGHT end
      end
      s.key = "o:" .. s.quests[1]
    else
      local ready = 0
      for _, qid in ipairs(s.turnins) do if not (s.pending and s.pending[qid]) then ready = ready + 1 end end
      s.weight = (#s.pickups > 0 or ready > 0) and EARLY_WEIGHT or 0
      s.rank = seedRank[s.key]
      -- A second visit waits with its quest. Otherwise hand-ins are worth doing now,
      -- and pick-ups go by the best quest on offer.
      s.band = s.later or (ready > 0 and 1) or nil
      if not s.band then
        for _, o in ipairs(s.pickups) do
          if not s.band or o.band < s.band then s.band = o.band end
        end
      end
    end
    if s.rank then seeded = true end
  end

  local ordered, walked = P.Order({ x = px, y = py }, stops, w, h, seeded or nil)
  for _, s in ipairs(ordered) do s.after, s.rank = nil, nil end
  self.walked = walked

  -- Remember the order, so the next plan keeps it.
  local keys = {}
  for _, s in ipairs(ordered) do
    if s.kind == "obj" then
      for _, qid in ipairs(s.quests) do keys[#keys + 1] = "o:" .. qid end
    else
      keys[#keys + 1] = s.key
    end
  end
  QP.char.planOrder, QP.char.planMap = keys, mapID

  self.stops, self.mapID, self.elsewhere = ordered, mapID, elsewhere
  self.hub = O:NextHub(true)
  QP.char.planOn = true
  self:SyncRoute()

  if announce then
    local npcs, objs, ins, late = 0, 0, 0, 0
    for _, s in ipairs(ordered) do
      if s.kind == "obj" then objs = objs + 1 else npcs = npcs + 1; ins = ins + #s.turnins end
      if (s.band or 1) > 1 then late = late + 1 end
    end
    if #ordered == 0 then
      QP:Print("Nothing to do in this zone%s.", self.hub and (". Next: " .. self.hub.zone) or "")
    else
      QP:Print("Plan: %d stops, about %d yards. %d to pick up, %d to hand in, %d to do.%s", #ordered, floor((walked or 0) + 0.5), pickups, ins, objs,
        late > 0 and (" %d that aren't right for your level come last."):format(late) or "")
    end
  end
  self.current, self.doneState, self.built, self.focused, self.hubAnnounced = nil, {}, false, false, false
  self:Check()
end

-- The quest list's numbers follow the plan.
function P:SyncRoute()
  local route, seen = {}, {}
  for _, s in ipairs(self.stops or {}) do
    local ids = s.kind == "obj" and s.quests or s.turnins
    for _, id in ipairs(ids) do
      if not seen[id] then
        seen[id] = true
        route[#route + 1] = id
      end
    end
  end
  QP.char.route = #route > 0 and route or nil
end

------------------------------------------------------------------------
-- Progress
------------------------------------------------------------------------

function P:Done(s)
  local Q, skip = QP.Quests, self.skipItems
  if s.kind == "obj" then
    for _, id in ipairs(s.quests) do
      local q = Q:Get(id)
      if q and not q.complete and not skip[id] then return false end
    end
    return true
  end
  for _, id in ipairs(s.turnins) do
    if Q:Get(id) and not skip[id] then return false end
  end
  for _, o in ipairs(s.pickups) do
    local inLog = Q:Get(o.id) or (QP.Offers.logTitles and QP.Offers.logTitles[o.title:lower()])
    if not inLog and not skip[o.title:lower()] and not QP.Offers:Ignored(o.id, o.title) and not QP.char.done[o.id] then
      return false
    end
  end
  return true
end

-- Called on quest log changes: tick off stops; when one gets finished, plan again
-- from where you are (that adds the objectives of quests you just took).
function P:Check()
  if not self.stops then return end
  QP.Offers:ReadLog()
  local state, newly = self.doneState, false
  for _, s in ipairs(self.stops) do
    local d = self:Done(s)
    if d and not state[s] then newly = true end
    state[s] = d
  end
  if newly and self.built and not self.rebuilding then
    self.rebuilding = true
    self:Build(false)
    self.rebuilding = false
    return
  end
  self.built = true
  local cur = self.current and self.stops[self.current]
  if not cur or state[cur] then
    local first
    for i, s in ipairs(self.stops) do
      if not state[s] then first = i break end
    end
    if first ~= self.current or not self.focused then
      self.current, self.focused = first, true
      self:FocusCurrent()
    end
  end
  QP:Emit("PLAN_CHANGED")
end

function P:StopTitle(s)
  if s.kind == "obj" then
    local q = QP.Quests:Get(P.ObjQuest(s) or s.quest)
    return q and q.title or "Objective"
  end
  local parts = {}
  if #s.turnins > 0 then parts[#parts + 1] = "hand in " .. #s.turnins end
  if #s.pickups > 0 then parts[#parts + 1] = "pick up " .. #s.pickups end
  return s.name .. ": " .. table.concat(parts, ", ")
end

-- The first quest at a "Do" stop that still needs doing.
function P.ObjQuest(s)
  for _, id in ipairs(s.quests or { s.quest }) do
    local q = QP.Quests:Get(id)
    if q and not q.complete and not P.skipItems[id] then return id end
  end
end

function P:FocusCurrent()
  local s = self.current and self.stops[self.current]
  if s then
    if s.kind == "obj" then
      local id = P.ObjQuest(s) or s.quest
      if QP.char.focus ~= id then QP.Nav:Focus(id, true) end
    else
      QP.Nav:FocusPoint({ m = s.m, x = s.x, y = s.y, title = self:StopTitle(s) })
    end
  elseif self.hub then
    QP.Nav:FocusPoint({ m = self.hub.m, x = self.hub.x, y = self.hub.y, title = "Next: " .. self.hub.zone .. " (" .. self.hub.npc .. ")" })
    if not self.hubAnnounced then
      self.hubAnnounced = true
      QP:Print("Zone done. Next: %s, near %s.", self.hub.zone, self.hub.npc)
    end
  else
    QP.Nav:Clear()
  end
end

function P:FocusStop(i)
  if not (self.stops and self.stops[i]) then return end
  self.current = i
  self:FocusCurrent()
  QP:Emit("PLAN_CHANGED")
end

-- Skip a stop for this session: its quests stay out of the plan.
function P:Skip(i)
  local s = self.stops and self.stops[i]
  if not s then return end
  local skip = self.skipItems
  if s.kind == "obj" then
    for _, id in ipairs(s.quests) do skip[id] = true end
  else
    for _, id in ipairs(s.turnins) do skip[id] = true end
    for _, o in ipairs(s.pickups) do skip[o.title:lower()] = true end
  end
  self:Check()
end

function P:Stop(announce)
  QP.char.planOn = nil
  self.stops, self.current, self.hub = nil, nil, nil
  QP.char.route = nil
  QP.Nav:Clear()
  if announce then QP:Print("Plan stopped.") end
  QP:Emit("QUESTS_CHANGED")
end

function P:Toggle()
  if QP.char.planOn then self:Stop(true) else self:Build(true) end
end

-- A new level changes which quests are right for you.
QP:On("PLAYER_LEVEL_UP", function()
  if QP.db and QP.char.planOn then
    C_Timer.After(1, function() if QP.char.planOn then P:Build(false) end end)
  end
end)

-- A new zone gets a new plan.
QP:On("ZONE_CHANGED_NEW_AREA", function()
  if QP.db and QP.char.planOn then
    C_Timer.After(1.5, function() if QP.char.planOn then P:Build(false, true) end end)
  end
end)

QP:Listen("LOGIN", function()
  if QP.char.planOn then
    C_Timer.After(5, function() if QP.char.planOn then P:Build(false) end end)
  end
end)
