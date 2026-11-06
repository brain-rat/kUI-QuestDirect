-- QuestDirect · Offers
-- Quests you could pick up: where their givers stand, whether you can take them
-- (level, race, class, earlier quests in the chain), and where to go next once a
-- zone is done.
--
-- Three sources, best first:
--   game     Blizzard's own available-quest map data, when the client has it
--   learned  what you've seen in game: who offered what, where (saved for all characters)
--   classic  the Classic database in QuestData.lua (may differ in Forever)

local _, ns = ...
local QP = ns.QP

local O = { info = {}, npcPos = {}, byMap = {}, cache = {}, ready = false }
QP.Offers = O

local floor, abs, sqrt, max, min = math.floor, math.abs, math.sqrt, math.max, math.min
local lower = string.lower
local ALLIANCE, HORDE = 77, 178
local CONTINENT = (Enum and Enum.UIMapType and Enum.UIMapType.Continent) or 2
local ZONE = (Enum and Enum.UIMapType and Enum.UIMapType.Zone) or 3
local CANDIDATE_CONTINENTS = { 1415, 1414, 13, 12 }
local POINTS_PER_FRAME = 300
local HUB_RADIUS = 120 -- yards: givers this close count as one hub

local function band(a, b)
  if bit and bit.band then return bit.band(a, b) end
  local r, p = 0, 1
  while a > 0 and b > 0 do
    if a % 2 == 1 and b % 2 == 1 then r = r + p end
    a, b, p = floor(a / 2), floor(b / 2), p * 2
  end
  return r
end
O.band = band

local function Safe(fn, ...)
  if not fn then return nil end
  local ok, a, b, c, d, e = pcall(fn, ...)
  if ok then return a, b, c, d, e end
end

local function XY(v)
  if not v then return nil end
  if v.GetXY then return v:GetXY() end
  return v.x, v.y
end

------------------------------------------------------------------------
-- Quest data
------------------------------------------------------------------------

local function Split(s)
  local t = {}
  for n in (s or ""):gmatch("%-?%d+") do t[#t + 1] = tonumber(n) end
  return t
end

-- Parsed quest record (cached), or nil if the quest isn't in the Classic data.
function O:Info(id)
  local c = self.info[id]
  if c ~= nil then return c or nil end
  local r = ns.QuestData and ns.QuestData.q[id]
  if not r then self.info[id] = false return nil end
  c = { id = id, title = r[1], level = r[2], min = r[3], races = r[4], classes = r[5], pre = Split(r[6]),
        excl = r[7], bread = r[8], type = r[9], givers = Split(r[10]), enders = Split(r[11]) }
  self.info[id] = c
  return c
end

function O:Groups()
  if self.groups then return self.groups end
  local g = {}
  for id, r in pairs(ns.QuestData and ns.QuestData.q or {}) do
    if r[7] ~= 0 then
      g[r[7]] = g[r[7]] or {}
      table.insert(g[r[7]], id)
    end
  end
  self.groups = g
  return g
end

function O:ByTitle()
  if self.titles then return self.titles end
  local t = {}
  for id, r in pairs(ns.QuestData and ns.QuestData.q or {}) do
    local k = lower(r[1])
    t[k] = t[k] or {}
    table.insert(t[k], id)
  end
  self.titles = t
  return t
end

------------------------------------------------------------------------
-- Placing NPCs on zone maps (world -> continent -> zone, via the client)
------------------------------------------------------------------------

function O:FindContinents()
  local found = {}
  local function try(uiMap)
    local info = uiMap and C_Map.GetMapInfo(uiMap)
    if not info or info.mapType ~= CONTINENT then return end
    local instance = Safe(C_Map.GetWorldPosFromMapPos, uiMap, CreateVector2D(0.5, 0.5))
    if instance and found[instance] == nil then found[instance] = uiMap end
  end
  local m = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
  for _ = 1, 6 do
    local info = m and not QP.Secret(m) and C_Map.GetMapInfo(m)
    if not info then break end
    if info.mapType == CONTINENT then try(m) break end
    m = info.parentMapID
  end
  for _, id in ipairs(CANDIDATE_CONTINENTS) do try(id) end
  return found
end

local function Place(instance, continent, wx, wy, swap)
  local vec = swap and CreateVector2D(wy, wx) or CreateVector2D(wx, wy)
  local _, cpos = Safe(C_Map.GetMapPosFromWorldPos, instance, vec, continent)
  local cx, cy = XY(cpos)
  if not cx or cx < 0 or cx > 1 or cy < 0 or cy > 1 then return nil end
  local info = C_Map.GetMapInfoAtPosition(continent, cx, cy)
  if not info or info.mapType ~= ZONE then return nil end
  local _, zpos = Safe(C_Map.GetMapPosFromWorldPos, instance, vec, info.mapID)
  local zx, zy = XY(zpos)
  if not zx or zx < 0 or zx > 1 or zy < 0 or zy > 1 then return nil end
  return info.mapID, zx, zy
end
O.Place = Place

local function Points(s)
  local t = {}
  for x, y in (s or ""):gmatch("(%-?[%d%.]+),(%-?[%d%.]+)") do t[#t + 1] = { tonumber(x), tonumber(y) } end
  return t
end

function O:DetectAxes(continents)
  local hits = { [false] = 0, [true] = 0 }
  local tried = 0
  for _, r in pairs(ns.QuestData.n) do
    local continent = continents[r[2]]
    local p = continent and Points(r[3])[1]
    if p then
      for _, swap in ipairs({ false, true }) do
        if Place(r[2], continent, p[1], p[2], swap) then hits[swap] = hits[swap] + 1 end
      end
      tried = tried + 1
      if tried >= 120 then break end
    end
  end
  return hits[true] > hits[false]
end

-- Place every quest NPC, a few hundred per frame so logging in doesn't stutter.
function O:Build(onDone)
  if self.building or not ns.QuestData then return end
  if not (C_Map and C_Map.GetMapPosFromWorldPos and C_Map.GetMapInfoAtPosition and CreateVector2D) then return end
  self.building = true
  local continents = self:FindContinents()
  local swap = self:DetectAxes(continents)
  local queue = {}
  for id, r in pairs(ns.QuestData.n) do
    if continents[r[2]] then queue[#queue + 1] = id end
  end
  table.sort(queue)
  local i = 0
  local function step()
    local stop = min(#queue, i + POINTS_PER_FRAME)
    while i < stop do
      i = i + 1
      local id = queue[i]
      local r = ns.QuestData.n[id]
      local spots = {}
      for _, p in ipairs(Points(r[3])) do
        local m, x, y = Place(r[2], continents[r[2]], p[1], p[2], swap)
        if m then
          local wx, wy = p[1], p[2]
          if swap then wx, wy = wy, wx end
          spots[#spots + 1] = { m = m, x = x, y = y, inst = r[2], wx = wx, wy = wy }
        end
      end
      if #spots > 0 then self.npcPos[id] = spots end
    end
    if i < #queue then
      C_Timer.After(0, step)
    else
      self:IndexMaps()
      self.building, self.ready = false, true
      self:Invalidate()
      if onDone then onDone() end
    end
  end
  step()
end

-- byMap[uiMapID] = quest ids with a giver standing on that map
function O:IndexMaps()
  local byMap = {}
  for id, r in pairs(ns.QuestData.q) do
    local seen = {}
    for _, g in ipairs(Split(r[10])) do
      for _, s in ipairs(self.npcPos[g] or {}) do
        if not seen[s.m] then
          seen[s.m] = true
          byMap[s.m] = byMap[s.m] or {}
          table.insert(byMap[s.m], id)
        end
      end
    end
  end
  self.byMap = byMap
end

-- Map size in yards (map x runs along world y).
local sizes = {}
function O:MapSize(mapID)
  if sizes[mapID] then return sizes[mapID][1], sizes[mapID][2] end
  local w, h
  if CreateVector2D and C_Map.GetWorldPosFromMapPos then
    local _, a = Safe(C_Map.GetWorldPosFromMapPos, mapID, CreateVector2D(0, 0))
    local _, b = Safe(C_Map.GetWorldPosFromMapPos, mapID, CreateVector2D(1, 1))
    local ax, ay = XY(a)
    local bx, by = XY(b)
    if ax and bx then
      w, h = abs(by - ay), abs(bx - ax)
      if w < 1 or h < 1 then w, h = abs(bx - ax), abs(by - ay) end
    end
  end
  if not w or w < 1 or h < 1 then w, h = 1000, 667 end
  sizes[mapID] = { w, h }
  return w, h
end

function O:Yards(mapID, x1, y1, x2, y2)
  local w, h = self:MapSize(mapID)
  local dx, dy = (x1 - x2) * w, (y1 - y2) * h
  return sqrt(dx * dx + dy * dy)
end

------------------------------------------------------------------------
-- You: level, race, class, what's done, what's in the log
------------------------------------------------------------------------

local function GreenRange(l)
  if UnitQuestTrivialLevelRange then
    local r = Safe(UnitQuestTrivialLevelRange, "player")
    if type(r) == "number" and r > 0 then return r end
  end
  if l <= 5 then return 5 elseif l <= 39 then return floor(l / 10) + 5 elseif l <= 59 then return floor(l / 5) + 1 end
  return 9
end

function O:Me()
  local level = UnitLevel("player") or 1
  local _, _, raceID = UnitRace("player")
  local _, _, classID = UnitClass("player")
  return {
    level = level,
    race = raceID and 2 ^ (raceID - 1) or 0,
    class = classID and 2 ^ (classID - 1) or 0,
    side = UnitFactionGroup and UnitFactionGroup("player"),
    green = GreenRange(level),
  }
end

-- The log, keyed by Classic id and by title, plus whether the game's quest ids
-- match the Classic ones (if not, matching falls back to titles).
function O:ReadLog()
  local byDB, titles, matched, total = {}, {}, 0, 0
  local offsets = {}
  for _, q in ipairs(QP.Quests.list) do
    local t = lower(q.title)
    titles[t] = q
    -- Quests new in Forever aren't in the Classic data at all, so they say nothing
    -- about whether ids match; only count quests the Classic data knows by name.
    local known = self:ByTitle()[t] ~= nil
    if known then total = total + 1 end
    local info = self:Info(q.id)
    if info and lower(info.title) == t then
      matched = matched + 1
      q.dbid = q.id
    else
      local best, bestD
      for _, id in ipairs(self:ByTitle()[t] or {}) do
        local d = abs(self:Info(id).level - (q.level or 0))
        if not bestD or d < bestD then best, bestD = id, d end
        local off = q.id - id
        offsets[off] = (offsets[off] or 0) + 1
      end
      q.dbid = best
    end
    if q.dbid then byDB[q.dbid] = q end
    QP.char.logTitles[q.id] = q.title
  end
  self.log, self.logTitles = byDB, titles
  if total >= 1 then
    self.idsMatch = matched / total >= 0.6
    -- Forever's ids might be Classic's plus a fixed number.
    self.idOffset = nil
    if not self.idsMatch then
      for off, n in pairs(offsets) do
        if off ~= 0 and n >= 2 and n / total >= 0.6 then self.idOffset = off end
      end
    end
  end
end

-- The game's id for a Classic quest id, when that can be worked out.
function O:GameID(id)
  if self.idsMatch ~= false then return id end
  if self.idOffset then return id + self.idOffset end
end

-- Classic record for a quest the game shows you (its game id and title).
function O:InfoForGame(id, title)
  local t = title and lower(title)
  if self.idsMatch ~= false then
    local info = self:Info(id)
    if info and (not t or lower(info.title) == t) then return info end
  end
  if self.idOffset then
    local info = self:Info(id - self.idOffset)
    if info and (not t or lower(info.title) == t) then return info end
  end
  local cand = t and self:ByTitle()[t]
  return cand and self:Info(cand[1]) or nil
end

function O:IsDone(id)
  local c = QP.char
  if c.done[id] then return true end
  local gid = self:GameID(id)
  if gid and C_QuestLog.IsQuestFlaggedCompleted and Safe(C_QuestLog.IsQuestFlaggedCompleted, gid) then
    return true
  end
  local info = self:Info(id)
  if not info then return false end
  local t = lower(info.title)
  return (c.doneTitles[t] or self.completedTitles[t]) and true or false
end

------------------------------------------------------------------------
-- Quests this character finished before (by name, so it works whatever the ids)
------------------------------------------------------------------------

O.completedTitles = {}
local SCAN_PER_FRAME = 60

function O:ScanCompleted()
  if self.scanning then return end
  local ids
  if C_QuestLog.GetAllCompletedQuestIDs then
    ids = Safe(C_QuestLog.GetAllCompletedQuestIDs)
  elseif GetQuestsCompleted then
    local t = Safe(GetQuestsCompleted)
    if t then
      ids = {}
      for id in pairs(t) do ids[#ids + 1] = id end
    end
  end
  local titleOf = C_QuestLog.GetTitleForQuestID or C_QuestLog.GetQuestInfo
  if not (ids and titleOf) then return end
  self.scanning = true
  self.waiting = {}
  local i, found = 0, 0
  local function step()
    local stop = min(#ids, i + SCAN_PER_FRAME)
    while i < stop do
      i = i + 1
      local id = ids[i]
      local title = Safe(titleOf, id)
      if type(title) == "string" and title ~= "" then
        self.completedTitles[lower(title)] = true
        found = found + 1
      elseif C_QuestLog.RequestLoadQuestByID then
        self.waiting[id] = true
        Safe(C_QuestLog.RequestLoadQuestByID, id)
      end
    end
    if i < #ids then
      C_Timer.After(0, step)
    else
      self.scanning = false
      self.completedCount = #ids
      self:Invalidate()
      self.hubCache = nil
      QP:Emit("QUESTS_CHANGED")
    end
  end
  step()
end

-- Titles that weren't loaded yet arrive here.
QP:On("QUEST_DATA_LOAD_RESULT", function(questID, ok)
  local w = O.waiting
  if not (w and w[questID]) then return end
  w[questID] = nil
  local titleOf = C_QuestLog.GetTitleForQuestID or C_QuestLog.GetQuestInfo
  local title = ok and titleOf and Safe(titleOf, questID)
  if type(title) == "string" and title ~= "" then
    O.completedTitles[lower(title)] = true
    O:Invalidate()
    QP:EmitSoon("QUESTS_CHANGED", 1)
  end
end)

function O:InLog(id)
  if self.log and self.log[id] then return true end
  local info = self:Info(id)
  return info and self.logTitles and self.logTitles[lower(info.title)] ~= nil or false
end

function O:Ignored(id, title)
  local ig = QP.char.ignored
  return ig[id] or (title and ig[lower(title)]) or false
end

------------------------------------------------------------------------
-- Can you take this quest?
------------------------------------------------------------------------

-- Any one finished prerequisite is enough, except "all of a group" chains.
-- assume: quest ids treated as done (quests ready to hand in). Returns ok, unlockedBy.
function O:PrereqOK(info, assume)
  if #info.pre == 0 then return true end
  local unlockedBy
  for _, p in ipairs(info.pre) do
    if p > 0 then
      local real = self:IsDone(p)
      local done = real or (assume and assume[p])
      if done then
        local pinfo = self:Info(p)
        local ok = true
        if pinfo and pinfo.excl < 0 then
          for _, gid in ipairs(self:Groups()[pinfo.excl] or {}) do
            if not (self:IsDone(gid) or (assume and assume[gid])) then ok = false break end
          end
        end
        if ok then
          if real then return true end
          unlockedBy = unlockedBy or p
        end
      end
    elseif self:InLog(-p) then
      return true
    end
  end
  if unlockedBy then return true, unlockedBy end
  return false
end

function O:ExclusiveOK(info)
  if info.excl <= 0 then return true end
  for _, gid in ipairs(self:Groups()[info.excl] or {}) do
    if gid ~= info.id and (self:IsDone(gid) or self:InLog(gid)) then return false end
  end
  return true
end

-- Level check: not grey (unless you asked for grey), not far above you.
function O:LevelOK(level, minLevel, me)
  local db = QP.db
  if minLevel and minLevel > me.level then return false end
  if not level or level <= 0 then return true end
  if level > me.level + db.maxAbove then return false end
  if not db.showGrey and level < me.level - me.green then return false end
  return true
end

-- Why you can't take a quest, or nil if you can. assume as for PrereqOK.
function O:Check(info, me, assume)
  if self:InLog(info.id) then return "in log" end
  if self:IsDone(info.id) then return "done" end
  if self:Ignored(info.id, info.title) then return "ignored" end
  if info.races ~= 0 and band(info.races, me.race) == 0 then return "race" end
  if info.classes ~= 0 and band(info.classes, me.class) == 0 then return "class" end
  if not self:LevelOK(info.level, info.min, me) then return "level" end
  if info.bread ~= 0 and (self:IsDone(info.bread) or self:InLog(info.bread)) then return "breadcrumb" end
  if not self:ExclusiveOK(info) then return "exclusive" end
  local ok, by = self:PrereqOK(info, assume)
  if not ok then return "prereq" end
  return nil, by
end

------------------------------------------------------------------------
-- Offers on a map
------------------------------------------------------------------------

local function NpcName(id)
  local r = ns.QuestData and ns.QuestData.n[id]
  return r and r[1] or "Quest giver"
end

-- The nearest placed spot of any of these NPCs on this map.
function O:Spot(npcs, mapID, px, py)
  local best, bestD, bestNpc
  for _, g in ipairs(npcs) do
    for _, s in ipairs(self.npcPos[g] or {}) do
      if s.m == mapID then
        local d = px and self:Yards(mapID, s.x, s.y, px, py) or 0
        if not bestD or d < bestD then best, bestD, bestNpc = s, d, g end
      end
    end
  end
  return best, bestNpc
end

function O:Invalidate() wipe(self.cache) end

-- Quests you can pick up on this map, merged from all three sources.
-- assume: quest ids treated as done (for "turn in X, then pick up Y").
function O:ForMap(mapID, assume)
  if not mapID then return {} end
  local key = mapID .. (assume and ":a" or "")
  if self.cache[key] then return self.cache[key] end
  self:ReadLog()
  local me = self:Me()
  local out, byTitle = {}, {}
  local function add(o)
    local k = lower(o.title)
    local prev = byTitle[k]
    if prev then
      -- keep the better source, but fill in what it lacks
      prev.level = prev.level or o.level
      prev.min = prev.min or o.min
      prev.dbid = prev.dbid or o.dbid
      prev.unlockedBy = prev.unlockedBy or o.unlockedBy
      return
    end
    byTitle[k] = o
    out[#out + 1] = o
  end

  -- 1. The game's own map data
  if C_QuestLine and C_QuestLine.GetAvailableQuestLines then
    if not self.requested then self.requested = {} end
    if not self.requested[mapID] then
      self.requested[mapID] = true
      Safe(C_QuestLine.RequestQuestLinesForMap, mapID)
    end
    for _, l in ipairs(Safe(C_QuestLine.GetAvailableQuestLines, mapID) or {}) do
      if l.questID and l.questName and l.x and not l.isHidden and not self:Ignored(l.questID, l.questName) then
        local info = self:InfoForGame(l.questID, l.questName)
        add({ id = l.questID, title = l.questName, level = info and info.level, min = info and info.min,
              dbid = info and info.id, source = "game",
              giver = { name = NpcName(info and info.givers[1]), m = mapID, x = l.x, y = l.y } })
      end
    end
  end

  -- 2. What you've seen offered in game
  for id, g in pairs(QuestDirectDB.learned.g) do
    if g.m == mapID and g.t and not QP.Quests:Get(id) and not self.logTitles[lower(g.t)]
       and not QP.char.done[id] and not QP.char.doneTitles[lower(g.t)]
       and not (C_QuestLog.IsQuestFlaggedCompleted and Safe(C_QuestLog.IsQuestFlaggedCompleted, id))
       and not self:Ignored(id, g.t) and self:LevelOK(g.l, nil, me) then
      -- It was offered to you, so trust that over the Classic rules; just keep
      -- other characters' race and class quests out.
      local cand = self:ByTitle()[lower(g.t)]
      local dbid = cand and cand[1]
      local info = dbid and self:Info(dbid)
      local fits = (not g.f or g.f == me.side)
        and not (info and info.races ~= 0 and band(info.races, me.race) == 0)
        and not (info and info.classes ~= 0 and band(info.classes, me.class) == 0)
      if fits then
        local by
        if info then _, by = self:PrereqOK(info, assume) end
        add({ id = id, title = g.t, level = g.l or (info and info.level), min = info and info.min, dbid = dbid,
              unlockedBy = by, source = "learned", giver = { name = g.name or "Quest giver", m = g.m, x = g.x, y = g.y } })
      end
    end
  end

  -- 3. Classic data
  if QP.db.classicOffers then
    for _, id in ipairs(self.byMap[mapID] or {}) do
      local info = self:Info(id)
      local why, by = self:Check(info, me, assume)
      if not why then
        local spot, npc = self:Spot(info.givers, mapID)
        if spot then
          add({ id = id, title = info.title, level = info.level, min = info.min, dbid = id, unlockedBy = by,
                elite = info.type == 1, source = "classic",
                giver = { name = NpcName(npc), npc = npc, m = mapID, x = spot.x, y = spot.y } })
        end
      end
    end
  end
  self.cache[key] = out
  return out
end

-- Offers on your map, nearest first, with distances.
function O:Nearby()
  local mapID, px, py = QP.Quests:PlayerPos()
  if not mapID then return {} end
  local list = {}
  for _, o in ipairs(self:ForMap(mapID)) do
    o.distance = self:Yards(mapID, o.giver.x, o.giver.y, px, py)
    list[#list + 1] = o
  end
  table.sort(list, function(a, b) return a.distance < b.distance end)
  return list, mapID
end

-- Where a log quest is handed in: learned spot first, then the Classic turn-in NPC.
function O:Ender(q, mapID)
  local l = QuestDirectDB.learned.e[q.id]
  if l and l.m then return { name = l.name or "Turn-in", m = l.m, x = l.x, y = l.y } end
  local info = q.dbid and self:Info(q.dbid)
  if not info then return nil end
  local spot, npc
  if mapID then spot, npc = self:Spot(info.enders, mapID) end
  if not spot then
    for _, e in ipairs(info.enders) do
      local s = self.npcPos[e] and self.npcPos[e][1]
      if s then spot, npc = s, e break end
    end
  end
  if spot then return { name = NpcName(npc), m = spot.m, x = spot.x, y = spot.y } end
end

------------------------------------------------------------------------
-- Where to go next: the best quest hub in another zone
------------------------------------------------------------------------

local function ZoneName(m)
  local info = m and C_Map.GetMapInfo(m)
  return info and info.name or "?"
end
O.ZoneName = ZoneName

function O:PlayerWorld()
  local mapID, px, py = QP.Quests:PlayerPos()
  if not mapID then return nil end
  local inst, v = Safe(C_Map.GetWorldPosFromMapPos, mapID, CreateVector2D(px, py))
  local wx, wy = XY(v)
  if not wx then return nil end
  return inst, wx, wy, mapID
end

-- { zone, m, x, y, npc, count, minL, maxL, distance } or nil
function O:NextHub(force)
  local now = GetTime and GetTime() or 0
  if not force and self.hubCache and now - self.hubCache.t < 30 then return self.hubCache.hub end
  local inst, wx, wy, here = self:PlayerWorld()
  if not inst or not self.ready then return nil end
  self:ReadLog()
  local me = self:Me()
  local buckets = {} -- npc id -> { spot, n, minL, maxL, quests }
  local function put(npc, spot, weight, level)
    local b = buckets[npc]
    if not b then
      b = { npc = npc, spot = spot, n = 0, quests = 0 }
      buckets[npc] = b
    end
    b.n = b.n + weight
    if level then
      b.quests = b.quests + 1
      b.minL = min(b.minL or level, level)
      b.maxL = max(b.maxL or level, level)
    end
  end
  for m, ids in pairs(self.byMap) do
    if m ~= here then
      for _, id in ipairs(ids) do
        local info = self:Info(id)
        if not self:Check(info, me) then
          for _, g in ipairs(info.givers) do
            local s = self.npcPos[g] and self.npcPos[g][1]
            if s and s.m == m and s.inst == inst then put(g, s, 1, info.level) break end
          end
        end
      end
    end
  end
  -- Finished quests handed in elsewhere pull you there too.
  for _, q in ipairs(QP.Quests.list) do
    if q.complete then
      local info = q.dbid and self:Info(q.dbid)
      for _, e in ipairs(info and info.enders or {}) do
        local s = self.npcPos[e] and self.npcPos[e][1]
        if s and s.m ~= here and s.inst == inst then put(e, s, 1.5) break end
      end
    end
  end
  -- Merge nearby givers into hubs.
  local list = {}
  for _, b in pairs(buckets) do list[#list + 1] = b end
  table.sort(list, function(a, b) return a.n > b.n end)
  local hubs = {}
  for _, b in ipairs(list) do
    local joined
    for _, h in ipairs(hubs) do
      local dx, dy = b.spot.wx - h.spot.wx, b.spot.wy - h.spot.wy
      if h.spot.m == b.spot.m and dx * dx + dy * dy < HUB_RADIUS * HUB_RADIUS then
        h.n, h.quests = h.n + b.n, h.quests + b.quests
        if b.minL then h.minL, h.maxL = min(h.minL or b.minL, b.minL), max(h.maxL or b.maxL, b.maxL) end
        joined = true
        break
      end
    end
    if not joined then
      hubs[#hubs + 1] = { npc = b.npc, spot = b.spot, n = b.n, quests = b.quests, minL = b.minL, maxL = b.maxL }
    end
  end
  local best, bestScore
  for _, h in ipairs(hubs) do
    local dx, dy = h.spot.wx - wx, h.spot.wy - wy
    h.distance = sqrt(dx * dx + dy * dy)
    local score = h.n / (1 + h.distance / 1500)
    if h.n >= 2 and (not bestScore or score > bestScore) then best, bestScore = h, score end
  end
  local hub
  if best then
    hub = { zone = ZoneName(best.spot.m), m = best.spot.m, x = best.spot.x, y = best.spot.y,
            npc = NpcName(best.npc), count = best.quests, minL = best.minL, maxL = best.maxL,
            distance = best.distance, turnins = floor(best.n - best.quests + 0.01) }
  end
  self.hubCache = { t = now, hub = hub }
  return hub
end

------------------------------------------------------------------------
-- Learning from what you see in game
------------------------------------------------------------------------

local function NpcFromGUID(guid)
  if not guid or QP.Secret(guid) then return nil end
  local kind, _, _, _, _, id = strsplit("-", guid)
  id = tonumber(id)
  if not id then return nil end
  if kind == "GameObject" then return -id end
  if kind == "Creature" then return id end
end

local function Here()
  local m, x, y = QP.Quests:PlayerPos()
  return m, x, y
end

local function Learn(kind, questID, title, level, unit)
  if not (QuestDirectDB and questID and questID > 0) then return end
  local m, x, y = Here()
  if not m then return end
  unit = unit or "npc"
  local name = UnitName(unit)
  if name and QP.Secret(name) then name = nil end
  local t = QuestDirectDB.learned[kind]
  local e = t[questID] or {}
  e.m, e.x, e.y = m, floor(x * 10000 + 0.5) / 10000, floor(y * 10000 + 0.5) / 10000
  e.name = name or e.name
  e.n = NpcFromGUID(UnitGUID(unit)) or e.n
  e.t = title or e.t
  e.l = level or e.l
  e.f = UnitFactionGroup and UnitFactionGroup("player") or e.f
  t[questID] = e
end
O.Learn = Learn

QP:On("QUEST_DETAIL", function()
  if not QP.db then return end
  local id = GetQuestID and GetQuestID()
  local unit = UnitExists and UnitExists("questnpc") and "questnpc" or "npc"
  Learn("g", id, GetTitleText and GetTitleText(), nil, unit)
  O:Invalidate()
end)

local function LearnEnder()
  if not QP.db then return end
  local id = GetQuestID and GetQuestID()
  local unit = UnitExists and UnitExists("questnpc") and "questnpc" or "npc"
  Learn("e", id, GetTitleText and GetTitleText(), nil, unit)
end
QP:On("QUEST_COMPLETE", LearnEnder)
QP:On("QUEST_PROGRESS", LearnEnder)

QP:On("GOSSIP_SHOW", function()
  if not (QP.db and C_GossipInfo) then return end
  for _, q in ipairs(Safe(C_GossipInfo.GetAvailableQuests) or {}) do
    if q.questID and not q.repeatable then Learn("g", q.questID, q.title, q.questLevel) end
  end
  for _, q in ipairs(Safe(C_GossipInfo.GetActiveQuests) or {}) do
    if q.questID and q.isComplete then Learn("e", q.questID, q.title, q.questLevel) end
  end
  O:Invalidate()
end)

QP:On("QUEST_GREETING", function()
  if not QP.db then return end
  for i = 1, (GetNumAvailableQuests and GetNumAvailableQuests() or 0) do
    local _, _, repeatable, _, id = Safe(GetAvailableQuestInfo, i)
    if id and not repeatable then Learn("g", id, GetAvailableTitle(i), GetAvailableLevel and GetAvailableLevel(i)) end
  end
  O:Invalidate()
end)

QP:On("QUEST_TURNED_IN", function(questID)
  if not QP.db then return end
  QP.char.done[questID] = true
  local title = QP.char.logTitles[questID]
  if title then QP.char.doneTitles[lower(title)] = true end
  O:Invalidate()
  O.hubCache = nil
end)

QP:Listen("QUESTS_CHANGED", function() O:Invalidate() end)
QP:On("PLAYER_LEVEL_UP", function() if QP.db then O:Invalidate(); O.hubCache = nil; QP:EmitSoon("QUESTS_CHANGED", 1) end end)
QP:On("QUESTLINE_UPDATE", function() if QP.db then O:Invalidate(); QP:EmitSoon("QUESTS_CHANGED", 0.5) end end)
QP:On("ZONE_CHANGED_NEW_AREA", function() if QP.db then O.hubCache = nil end end)

QP:Listen("LOGIN", function()
  C_Timer.After(3, function()
    O:Build(function() QP:Emit("QUESTS_CHANGED") end)
  end)
  C_Timer.After(4, function() O:ScanCompleted() end)
end)
