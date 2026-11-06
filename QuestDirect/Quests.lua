-- QuestDirect · Quests
-- Reads the quest log: titles, levels, zones, objectives, distance, and
-- where each quest's next stop is (objective area, turn-in, or travel hop).

local _, ns = ...
local QP = ns.QP

local Q = { list = {}, byID = {} }
QP.Quests = Q

local sqrt = math.sqrt
local CQ = C_QuestLog

local function Safe(fn, ...)
  if not fn then return nil end
  local ok, a, b, c, d = pcall(fn, ...)
  if not ok then return nil end
  return a, b, c, d
end

function Q:PlayerMap()
  local m = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
  if m == nil or QP.Secret(m) then return nil end
  return m
end

function Q:PlayerPos(mapID)
  mapID = mapID or self:PlayerMap()
  if not mapID then return nil end
  local pos = Safe(C_Map.GetPlayerMapPosition, mapID, "player")
  if not pos or QP.Secret(pos) then return nil end
  local x, y = pos.x, pos.y
  if pos.GetXY then x, y = pos:GetXY() end
  if not x or QP.Secret(x) or (x == 0 and y == 0) then return nil end
  return mapID, x, y
end

function Q:ZoneName(mapID)
  local info = mapID and C_Map.GetMapInfo(mapID)
  return info and info.name
end

-- Quest log -> list of quests with everything the tracker shows.
function Q:Refresh()
  local list, byID = {}, {}
  local header
  local n = Safe(CQ.GetNumQuestLogEntries) or 0
  for i = 1, n do
    local info = Safe(CQ.GetInfo, i)
    if info then
      if info.isHeader then
        header = info.title
      elseif info.questID and info.questID > 0 and not info.isHidden then
        local id = info.questID
        local q = {
          id = id, title = info.title or ("Quest " .. id), level = info.level or 0,
          zone = header or "Other", index = i, frequency = info.frequency, isTask = info.isTask,
          objectives = Safe(CQ.GetQuestObjectives, id) or {},
          complete = (Safe(CQ.ReadyForTurnIn, id) or Safe(CQ.IsComplete, id)) and true or false,
          failed = Safe(CQ.IsFailed, id) and true or false,
        }
        local d2, onContinent = Safe(CQ.GetDistanceSqToQuest, id)
        if d2 and not QP.Secret(d2) and d2 > 0 then q.distance, q.onContinent = sqrt(d2), onContinent end
        list[#list + 1] = q
        byID[id] = q
      end
    end
  end
  self.list, self.byID = list, byID
  return list
end

function Q:Get(id) return self.byID[id] end

-- Map position of a quest's pin (objective area, or turn-in when complete) on one map.
local function OnMap(questID, mapID)
  for _, p in ipairs(Safe(CQ.GetQuestsOnMap, mapID) or {}) do
    if p.questID == questID and p.x and p.y then return p.x, p.y end
  end
end

-- Where to go next for a quest: map, x, y (0-1), a label, and whether it's a travel hop.
-- 1. its pin on the map you're on (or that map's parents)
-- 2. Blizzard's next waypoint (flight master, zone exit, boat) when it's elsewhere
-- 3. its pin on the quest's own zone map
function Q:Target(questID)
  local here = self:PlayerMap()
  local m, tries = here, 0
  while m and tries < 3 do
    local x, y = OnMap(questID, m)
    if x then return m, x, y, nil, false end
    local info = C_Map.GetMapInfo(m)
    m = info and info.parentMapID
    tries = tries + 1
    if info and info.mapType and info.mapType <= 2 then break end -- stop at continent
  end
  local wm, wx, wy = Safe(CQ.GetNextWaypoint, questID)
  if wm and wx and wy then
    return wm, wx, wy, Safe(CQ.GetNextWaypointText, questID), true
  end
  local qm = Safe(GetQuestUiMapID, questID)
  if qm and qm > 0 then
    local x, y = OnMap(questID, qm)
    if x then return qm, x, y, nil, false end
  end
  return nil
end

-- Tracker order: your zone first, then the rest; inside a zone, by distance.
function Q:Sorted()
  local zoneName = self:ZoneName(self:PlayerMap())
  local groups, order = {}, {}
  for _, q in ipairs(self.list) do
    if not QP.char.hidden[q.id] and (not QP.db.zoneOnly or q.zone == zoneName) then
      if not groups[q.zone] then
        groups[q.zone] = {}
        order[#order + 1] = q.zone
      end
      table.insert(groups[q.zone], q)
    end
  end
  table.sort(order, function(a, b)
    if a == zoneName then return b ~= zoneName end
    if b == zoneName then return false end
    return a < b
  end)
  local routeRank = {}
  for i, id in ipairs(QP.char.route or {}) do routeRank[id] = i end
  for _, z in ipairs(order) do
    table.sort(groups[z], function(a, b)
      local ra, rb = routeRank[a.id], routeRank[b.id]
      if ra or rb then
        if ra and rb then return ra < rb end
        return ra ~= nil
      end
      local da, db = a.distance or math.huge, b.distance or math.huge
      if da ~= db then return da < db end
      return a.title < b.title
    end)
  end
  return order, groups, zoneName
end

-- Difficulty color like the quest log: grey, green, yellow, orange, red.
function Q:Color(level)
  if GetQuestDifficultyColor then
    local c = GetQuestDifficultyColor(level)
    if c then return c.r, c.g, c.b end
  end
  local diff = (level or 0) - (UnitLevel("player") or 0)
  if diff >= 5 then return 1, 0.1, 0.1 end
  if diff >= 3 then return 1, 0.5, 0.25 end
  if diff >= -2 then return 1, 0.82, 0 end
  if diff >= -7 then return 0.25, 0.75, 0.25 end
  return 0.5, 0.5, 0.5
end

QP:On("QUEST_LOG_UPDATE", function() if QP.db then QP:EmitSoon("QUESTS_CHANGED", 0.25) end end)
QP:On("QUEST_WATCH_LIST_CHANGED", function() if QP.db then QP:EmitSoon("QUESTS_CHANGED", 0.25) end end)
QP:On("QUEST_POI_UPDATE", function() if QP.db then QP:EmitSoon("QUESTS_CHANGED", 0.25) end end)
QP:On("ZONE_CHANGED_NEW_AREA", function() if QP.db then QP:EmitSoon("QUESTS_CHANGED", 0.5) end end)
QP:On("QUEST_REMOVED", function(questID) if QP.db then QP:Emit("QUEST_GONE", questID) end end)
QP:On("QUEST_TURNED_IN", function(questID) if QP.db then QP:Emit("QUEST_GONE", questID) end end)
QP:Listen("QUESTS_CHANGED", function() Q:Refresh() end)
QP:Listen("LOGIN", function() Q:Refresh() end)
