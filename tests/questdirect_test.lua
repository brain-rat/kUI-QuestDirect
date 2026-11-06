-- Stubbed WoW environment for QuestDirect. Run: texlua tests/questdirect_test.lua QuestDirect
local DIR = arg[1]
local unpack = table.unpack or unpack
local CLOCK, timers, chat, errors = 100, {}, {}, {}
function GetTime() return CLOCK end
C_Timer = { After = function(d, fn) timers[#timers + 1] = { due = CLOCK + d, fn = fn } end }
local function runTimers(window)
  local limit = CLOCK + (window or 0)
  for _ = 1, 100 do
    table.sort(timers, function(a, b) return a.due < b.due end)
    local t = timers[1]
    if not t or t.due > limit then break end
    table.remove(timers, 1)
    if t.due > CLOCK then CLOCK = t.due end
    local ok, e = pcall(t.fn); if not ok then errors[#errors + 1] = e end
  end
end
function geterrorhandler() return function(e) errors[#errors + 1] = tostring(e); print("  !! " .. tostring(e)) end end
function wipe(t) for k in pairs(t) do t[k] = nil end return t end

-- Frames
local eventFrames = {}
local Mock = {}
local Meta = { __index = function(t, k)
  if Mock[k] ~= nil then return Mock[k] end
  if type(k) == "string" and k:match("^%u") then return function() end end
end }
local function newMock(kind, name)
  local m = setmetatable({ kind = kind, scripts = {}, shown = true, text = "", scale = 1, w = 0, h = 0 }, Meta)
  if name then _G[name] = m end
  return m
end
function Mock:SetScript(k, fn) self.scripts[k] = fn end
function Mock:Show() self.shown = true end
function Mock:Hide() self.shown = false end
function Mock:IsShown() return self.shown end
function Mock:SetShown(v) self.shown = v and true or false end
function Mock:SetText(t) self.text = t end
function Mock:GetText() return self.text end
function Mock:SetTextColor(r, g, b) self.color = { r, g, b } end
function Mock:CreateFontString() return newMock("FontString") end
function Mock:CreateTexture() return newMock("Texture") end
function Mock:RegisterEvent(e) eventFrames[e] = eventFrames[e] or {}; table.insert(eventFrames[e], self) end
function Mock:SetScale(s) self.scale = s end
function Mock:GetScale() return self.scale end
function Mock:SetWidth(w) self.w = w end
function Mock:SetHeight(h) self.h = h end
function Mock:SetSize(w, h) self.w, self.h = w, h end
function Mock:GetWidth() return self.w end
function Mock:GetHeight() return self.h end
function Mock:SetPoint(...) self.point = { ... } end
function Mock:ClearAllPoints() self.point = nil end
function Mock:GetLeft() return self.point and self.point[4] or 1000 end
function Mock:GetTop() return self.point and self.point[5] or 700 end
function Mock:SetVerticalScroll(v) self.vscroll = v end
function Mock:GetVerticalScroll() return self.vscroll or 0 end
function Mock:StartMoving() self.moving = true end
function Mock:StartSizing() self.sizing = true end
function Mock:StopMovingOrSizing() self.moving, self.sizing = false, false end
function Mock:SetAttribute(k, v) self.attrs = self.attrs or {}; self.attrs[k] = v end
function Mock:SetTexture(t) self.tex = t end
local createdInCombat = 0
function CreateFrame(kind, name, parent, template)
  if template == "SecureActionButtonTemplate" and combat then createdInCombat = createdInCombat + 1 end
  return newMock(kind, name)
end
local SPECIAL = {}
function GetQuestLogSpecialItemInfo(i)
  local q = QUESTS[i]
  local s = q and SPECIAL[q.id]
  if not s then return nil end
  return "|cffffffff|Hitem:" .. s.id .. "::::|h[" .. s.name .. "]|h|r", "icon" .. s.id, s.charges or 0, s.showComplete
end
function GetBindingKey(cmd) if cmd == "CLICK QuestDirectItem1:LeftButton" then return "SHIFT-E" end end
function GetBindingText(k) return (k:gsub("SHIFT%-", "s")) end
local cooldowns = {}
C_Container = { GetItemCooldown = function(id) return cooldowns[id] or 0, 0, 1 end }
function CooldownFrame_Set(cd, s, d, e) cd.cdset = { s, d, e } end
local function fire(event, ...)
  for _, f in ipairs(eventFrames[event] or {}) do f.scripts.OnEvent(f, event, ...) end
end
function hooksecurefunc(t, name, fn)
  local orig = t[name]
  t[name] = function(...) local r = { orig(...) }; fn(...); return unpack(r) end
end
UIParent = newMock("Frame")
GameTooltip = newMock("GameTooltip")
GameTooltip.lines = {}
function GameTooltip:AddLine(t) table.insert(self.lines, t) end
DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) chat[#chat + 1] = m; print("  chat: " .. m:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end }
SlashCmdList = {}
ObjectiveTrackerFrame = newMock("Frame")
local combat = false
function InCombatLockdown() return combat end
local ctrl, shift = false, false
function IsControlKeyDown() return ctrl end
function IsShiftKeyDown() return shift end
function IsInGroup() return false end
function UnitLevel() return 6 end
local linked
function GetQuestLink(id) return "|Hquest:" .. id .. "|h[Quest]|h" end
function ChatEdit_InsertLink(l) linked = l end
local openedDetails
function QuestMapFrame_OpenToQuestDetails(id) openedDetails = id end
local menu
MenuUtil = { CreateContextMenu = function(owner, gen)
  menu = { items = {} }
  local root = { CreateTitle = function(_, t) menu.title = t end,
    CreateButton = function(_, label, fn) table.insert(menu.items, { label = label, fn = fn }) end }
  gen(owner, root)
end }

-- World: player on Durotar (1411); quests with pins
local player = { map = 1411, x = 0.5, y = 0.5 }
local QUESTS = {
  { header = "Durotar" },
  { id = 101, title = "Cutting Teeth", level = 3, pin = { 1411, 0.52, 0.48 }, objectives = { { text = "Mottled Boar slain: 4/10", finished = false } } },
  { id = 102, title = "Sting of the Scorpid", level = 4, pin = { 1411, 0.60, 0.70 }, objectives = { { text = "Scorpid Worker Tail: 2/10", finished = false } } },
  { id = 103, title = "Vile Familiars", level = 4, pin = { 1411, 0.40, 0.40 }, objectives = { { text = "Vile Familiar slain: 12/12", finished = true } }, complete = true, turnin = { 1411, 0.44, 0.67 } },
  { header = "Orgrimmar" },
  { id = 201, title = "Report to Orgrimmar", level = 5, waypoint = { 1411, 0.58, 0.32, "Take the road north to Orgrimmar" }, qmap = 1454, pin = { 1454, 0.5, 0.5 }, objectives = {} },
}
local function dist(q)
  local p = (q.complete and q.turnin) or q.pin
  if not p or p[1] ~= player.map then return 1e8 end
  local dx, dy = (p[2] - player.x) * 5000, (p[3] - player.y) * 3333
  return dx * dx + dy * dy
end
local function find(id) for _, q in ipairs(QUESTS) do if q.id == id then return q end end end
local supertracked = 0
C_QuestLog = {
  GetNumQuestLogEntries = function() return #QUESTS end,
  GetInfo = function(i)
    local q = QUESTS[i]; if not q then return nil end
    if q.header then return { title = q.header, isHeader = true } end
    return { title = q.title, questID = q.id, level = q.level, isHeader = false }
  end,
  GetQuestObjectives = function(id) return find(id).objectives end,
  ReadyForTurnIn = function(id) return find(id).complete end,
  IsComplete = function(id) return find(id).complete end,
  IsFailed = function() return false end,
  GetDistanceSqToQuest = function(id) return dist(find(id)), true end,
  GetQuestsOnMap = function(m)
    local out = {}
    for _, q in ipairs(QUESTS) do
      local p = q.id and ((q.complete and q.turnin) or q.pin)
      if p and p[1] == m then out[#out + 1] = { questID = q.id, x = p[2], y = p[3] } end
    end
    return out
  end,
  GetNextWaypoint = function(id) local w = find(id).waypoint; if w then return w[1], w[2], w[3] end end,
  GetNextWaypointText = function(id) local w = find(id).waypoint; return w and w[4] end,
  GetMaxNumQuestsCanAccept = function() return 35 end,
  IsPushableQuest = function() return true end,
  IsQuestFlaggedCompleted = function(id) return completedFlags[id] or false end,
  GetAllCompletedQuestIDs = function() return { 50001, 50002 } end,
  GetTitleForQuestID = function(id) if id == 50001 then return "Lazy Peons" end; if id == 50002 and loadedLate then return "Sarkoth" end end,
  RequestLoadQuestByID = function(id) requestedLoad = id end,
}
function GetQuestUiMapID(id) return find(id).qmap or 1411 end
C_SuperTrack = {
  SetSuperTrackedQuestID = function(id) supertracked = id; fire("SUPER_TRACKING_CHANGED") end,
  GetSuperTrackedQuestID = function() return supertracked end,
}
C_Map = {
  GetBestMapForUnit = function() return player.map end,
  GetPlayerMapPosition = function(m) return { x = player.x, y = player.y, GetXY = function(p) return p.x, p.y end } end,
  GetMapInfo = function(m) return ({ [1411] = { name = "Durotar", mapType = 3, parentMapID = 1414 }, [1414] = { name = "Kalimdor", mapType = 2 }, [1454] = { name = "Orgrimmar", mapType = 3 } })[m] end,
  GetMapWorldSize = function() return 5000, 3333 end,
}

-- A small fake world: Kalimdor (instance 1) with Durotar and Orgrimmar as world rectangles.
-- World X runs north, world Y runs west, like the game.
local ZONES = {
  [1411] = { xs = -1500, xn = 1300, yw = -3600, ye = -6000, name = "Durotar" },
  [1454] = { xs = 1300, xn = 2100, yw = -3900, ye = -4900, name = "Orgrimmar" },
  [1414] = { xs = -12000, xn = 12000, yw = 12000, ye = -12000, name = "Kalimdor" },
}
function CreateVector2D(x, y) return { x = x, y = y, GetXY = function(v) return v.x, v.y end } end
local function toWorld(m, x, y)
  local z = ZONES[m]; if not z then return nil end
  return z.xn - y * (z.xn - z.xs), z.yw - x * (z.yw - z.ye)
end
local function toMap(m, wx, wy)
  local z = ZONES[m]; if not z then return nil end
  return (z.yw - wy) / (z.yw - z.ye), (z.xn - wx) / (z.xn - z.xs)
end
C_Map.GetWorldPosFromMapPos = function(m, v)
  local wx, wy = toWorld(m, v.x, v.y); if not wx then return nil end
  return 1, CreateVector2D(wx, wy)
end
C_Map.GetMapPosFromWorldPos = function(inst, v, m)
  if inst ~= 1 then return nil end
  local x, y = toMap(m, v.x, v.y); if not x then return nil end
  return m, CreateVector2D(x, y)
end
C_Map.GetMapInfoAtPosition = function(m, cx, cy)
  if m ~= 1414 then return nil end
  local wx, wy = toWorld(1414, cx, cy)
  for id, z in pairs(ZONES) do
    if id ~= 1414 and wx >= z.xs and wx <= z.xn and wy <= z.yw and wy >= z.ye then return { mapID = id, mapType = 3, name = z.name } end
  end
end
function UnitRace() return "Orc", "Orc", 2 end
function UnitClass() return "Warrior", "WARRIOR", 1 end
function UnitFactionGroup() return "Horde" end
function UnitName() return "Gornek" end
function UnitGUID() return "Creature-0-1-1-1-3143-0000" end
function UnitExists() return true end
function strsplit(sep, s) local t = {}; for p in (s .. sep):gmatch("(.-)%" .. sep) do t[#t + 1] = p end; return table.unpack(t) end
local completedFlags = {}
loadedLate, requestedLoad = false, nil


-- TomTom mock
local tt = { added = {}, removed = 0, suppressed = {} }
TomTom = {
  AddWaypoint = function(self, m, x, y, opts) local uid = { m, x, y, title = opts.title, opts = opts }; table.insert(tt.added, uid); tt.last = uid; return uid end,
  RemoveWaypoint = function(self, uid) tt.removed = tt.removed + 1; if tt.last == uid then tt.last = nil end end,
  DefaultCallbacks = function(self, opts) return { minimap = {}, world = {}, distance = {} } end,
  SuppressFeature = function(self, owner, feature) tt.suppressed[feature] = owner end,
}

local passed, failed = 0, 0
local function check(c, label) if c then passed = passed + 1 else failed = failed + 1; print("  FAIL: " .. label) end end
local function section(s) print("\n== " .. s) end

local ns = {}
for line in io.lines(DIR .. "/QuestDirect.toc") do
  if line:match("%.lua$") then assert(loadfile(DIR .. "/" .. line))("QuestDirect", ns) end
end
local QP = ns.QP

section("Load")
fire("ADDON_LOADED", "QuestDirect")
fire("PLAYER_LOGIN")
runTimers(3)
local f = QuestDirectFrame
check(f and f.shown, "tracker built and shown")
check(ObjectiveTrackerFrame.shown == false, "Blizzard tracker hidden")
check(tt.suppressed.poi == "QuestDirect", "TomTom's own quest waypoints handed over")
ObjectiveTrackerFrame:Show()
check(ObjectiveTrackerFrame.shown == false, "Blizzard tracker stays hidden when the game re-shows it")

section("List and order")
local T = QP.Tracker
local rows = {}
for i = 1, T.used do local r = T.rows[i]; if r.zone or r.quest then rows[#rows + 1] = r.zone and ("#" .. r.zone) or r.quest.id end end
print("  rows: " .. table.concat(rows, ", "))
check(rows[1] == "#Durotar" and rows[2] == 101, "your zone first, nearest quest first")
check(rows[#rows - 1] == "#Orgrimmar", "other zones after")
check(f.title.text:find("4/35"), "count in the title: " .. f.title.text)
local function questRow(id) for i = 1, T.used do if T.rows[i].quest and T.rows[i].quest.id == id then return T.rows[i] end end end
local row101 = questRow(101)
check(row101.title.text == "[3] Cutting Teeth" and row101.dist.text:match("yd$"), "title with level and distance: " .. row101.title.text .. " / " .. row101.dist.text)
local done
for i = 1, T.used do if T.rows[i].quest and T.rows[i].quest.id == 103 then done = T.rows[i] end end
check(done and done.lines[1].text == "Ready to turn in", "complete quest says ready to turn in")

section("Focus and TomTom")
row101.scripts.OnClick(row101, "LeftButton")
check(supertracked == 101 and QP.char.focus == 101, "click focuses and super-tracks the quest")
check(tt.last and tt.last[1] == 1411 and math.abs(tt.last[2] - 0.52) < 1e-9 and tt.last.opts.crazy == true, "TomTom waypoint at the quest's objective, with the arrow")
check(tt.last.opts.from == "QuestDirect" and tt.last.opts.persistent == false and tt.last.opts.silent, "waypoint options")
local before = #tt.added
QP:Emit("QUESTS_CHANGED")
check(#tt.added == before, "same target isn't re-added on every update")
check(questRow(101).bar.shown, "focused row highlighted")
row101.scripts.OnClick(row101, "LeftButton")
check(QP.char.focus == nil and tt.last == nil and supertracked == 0, "click again stops navigating")

section("Travel hops")
local r201
for i = 1, T.used do if T.rows[i].quest and T.rows[i].quest.id == 201 then r201 = T.rows[i] end end
r201.scripts.OnClick(r201, "LeftButton")
check(tt.last and tt.last.title:find("Take the road north") and math.abs(tt.last[2] - 0.58) < 1e-9, "other-zone quest uses the game's next travel step: " .. tostring(tt.last and tt.last.title))
QP.Tracker:Refresh()
local hopLine
for i = 1, T.used do if T.rows[i].quest and T.rows[i].quest.id == 201 then hopLine = T.rows[i].lines[1] end end
check(hopLine and hopLine.text:find("Take the road north"), "tracker shows the travel step")
-- arrive at the hop: player now in Orgrimmar, the pin is there
find(201).waypoint = nil
player.map, player.x, player.y = 1454, 0.4, 0.4
tt.last.opts.callbacks.distance[QP.db.arrival]()
runTimers(2)
check(tt.last and tt.last[1] == 1454 and math.abs(tt.last[2] - 0.5) < 1e-9, "after the hop, arrow moves to the quest itself")
player.map, player.x, player.y = 1411, 0.5, 0.5

section("Completion and auto-next")
QP.Nav:Focus(102, true)
check(tt.last and math.abs(tt.last[3] - 0.70) < 1e-9, "focus objective")
find(102).complete, find(102).turnin = true, { 1411, 0.45, 0.68 }
QP:Emit("QUESTS_CHANGED")
check(tt.last and math.abs(tt.last[3] - 0.68) < 1e-9 and tt.last.title:find("turn in"), "objective done: arrow moves to the turn-in")
-- turn it in
for i, q in ipairs(QUESTS) do if q.id == 102 then table.remove(QUESTS, i) break end end
fire("QUEST_TURNED_IN", 102)
runTimers(1)
check(QP.char.focus == 101, "after turn-in, the nearest quest is focused: " .. tostring(QP.char.focus))

section("Pick up nearby")
QP.Nav:Clear()
table.insert(QUESTS, 4, { id = 104, title = "Far Away", level = 5, pin = { 1411, 0.90, 0.10 }, objectives = { { text = "Thing: 0/1" } } })
QP:Emit("QUESTS_CHANGED")
local O = QP.Offers
check(O.ready, "quest givers placed on the map")
local g = O.npcPos[3143]
check(g and g[1].m == 1411 and math.abs(g[1].x - 0.244) < 0.01 and math.abs(g[1].y - 0.679) < 0.01, "Gornek placed in Durotar at the right spot")
local zoneCount = 0
for _ in pairs(O.byMap[1411] or {}) do zoneCount = zoneCount + 1 end
print("  Classic quests with a giver in Durotar: " .. zoneCount)
QP.Tracker:Refresh()
local offerRows = {}
for i = 1, T.used do if T.rows[i].offer then offerRows[#offerRows + 1] = T.rows[i] end end
local offers = O:ForMap(1411)
local names = {}
for _, o in ipairs(offers) do names[#names + 1] = ("[%s] %s"):format(o.level or "?", o.title) end
print("  offers: " .. table.concat(names, "; "))
check(#offerRows > 0 and #offerRows <= QP.db.nearbyMax, "'Pick up nearby' lists quests (" .. #offerRows .. " rows)")
local list = O:Nearby()
local sorted = true
for i = 2, #list do if list[i].distance < list[i - 1].distance then sorted = false end end
check(sorted, "nearest first")
local byTitle = {}
for _, o in ipairs(offers) do byTitle[o.title] = o end
check(not byTitle["Cutting Teeth"], "quests in your log aren't suggested")
check(not byTitle["Sting of the Scorpid"], "quests you've handed in aren't suggested")
local raceOK, levelOK, chainOK = true, true, true
for _, o in ipairs(offers) do
  local info = o.dbid and O:Info(o.dbid)
  if info and info.races ~= 0 and O.band(info.races, 2) == 0 then raceOK = false end
  if o.level and (o.level > 6 + QP.db.maxAbove) then levelOK = false end
  if info and #info.pre > 0 and not O:PrereqOK(info) then chainOK = false end
end
check(raceOK, "only quests an orc can take")
check(levelOK, "nothing far above your level")
check(chainOK, "follow-ups wait for their earlier quest")
check(offerRows[1].title.text:find(list[1].title, 1, true), "row shows the nearest quest: " .. offerRows[1].title.text)
offerRows[1].scripts.OnEnter(offerRows[1])
check(#GameTooltip.lines >= 2, "offer tooltip")
offerRows[1].scripts.OnClick(offerRows[1], "LeftButton")
check(tt.last and math.abs(tt.last[2] - list[1].giver.x) < 1e-9 and QP.char.focus == nil, "click sends the arrow to the quest giver")
offerRows[1].scripts.OnClick(offerRows[1], "LeftButton")
check(tt.last == nil, "click again stops")
offerRows[1].scripts.OnClick(offerRows[1], "RightButton")
local dismissed = list[1].title
for _, it in ipairs(menu.items) do if it.label == "Don't suggest this quest" then it.fn() end end
local still = false
for _, o in ipairs(O:ForMap(1411)) do if o.title == dismissed then still = true end end
check(not still, "dismissed quests aren't suggested")
QP:Slash("unignore")

-- learning from the game
GetQuestID = function() return 90001 end
GetTitleText = function() return "A Quest Forever Added" end
player.x, player.y = 0.30, 0.60
fire("QUEST_DETAIL")
player.x, player.y = 0.5, 0.5
local l = QuestDirectDB.learned.g[90001]
check(l and l.m == 1411 and l.x == 0.3 and l.name == "Gornek" and l.n == 3143 and l.f == "Horde", "quest givers you meet are learned")
local learnedOffer
for _, o in ipairs(O:ForMap(1411)) do if o.id == 90001 then learnedOffer = o end end
check(learnedOffer and learnedOffer.source == "learned", "learned quests are suggested")
QuestDirectDB.learned.g[90002] = { m = 1411, x = 0.5, y = 0.5, t = "Alliance Thing", f = "Alliance" }
O:Invalidate()
local otherSide = false
for _, o in ipairs(O:ForMap(1411)) do if o.id == 90002 then otherSide = true end end
check(not otherSide, "other faction's learned quests are left out")

-- finished quests from before, read by name
check(O.completedTitles["lazy peons"], "finished quests read from the game by name")
check(requestedLoad == 50002, "titles not loaded yet are requested")
loadedLate = true
fire("QUEST_DATA_LOAD_RESULT", 50002, true)
check(O.completedTitles["sarkoth"], "and picked up when they arrive")
local stillOffered = false
for _, o in ipairs(O:ForMap(1411)) do if o.title == "Lazy Peons" or o.title == "Sarkoth" then stillOffered = true end end
check(not stillOffered, "quests you finished before aren't suggested")

section("Plan")
QP:Slash("plan")
local P = QP.Plan
check(P:Active() and #P.stops > 0, "plan built: " .. #P.stops .. " stops")
for i, s in ipairs(P.stops) do
  if s.kind == "obj" then
    print(("  %d. do %s"):format(i, QP.Quests:Get(s.quest).title))
  else
    local bits = {}
    for _, id in ipairs(s.turnins) do bits[#bits + 1] = "hand in " .. QP.Quests:Get(id).title end
    for _, o in ipairs(s.pickups) do bits[#bits + 1] = "pick up " .. o.title end
    print(("  %d. %s: %s"):format(i, s.name, table.concat(bits, ", ")))
  end
end
local pos, objStop, turnStop = {}, {}, {}
for i, s in ipairs(P.stops) do
  pos[s] = i
  if s.kind == "obj" then for _, q in ipairs(s.quests) do objStop[q] = s end else for _, id in ipairs(s.turnins) do turnStop[id] = s end end
end
check(objStop[101] and objStop[104], "objectives in this zone are stops")
check(not objStop[201] and not turnStop[201], "other zones' quests aren't")
check(turnStop[103], "the finished quest's hand-in is a stop")
check(turnStop[101] and turnStop[101].name == "Gornek", "Cutting Teeth hands in at Gornek")
check(pos[objStop[101]] < pos[turnStop[101]], "do it before handing it in")
local rulesOK, unlocks = true, 0
for _, s in ipairs(P.stops) do
  for _, o in ipairs(s.pickups or {}) do
    if o.unlockQuest then
      unlocks = unlocks + 1
      local t = turnStop[o.unlockQuest]
      if t and pos[t] > pos[s] then rulesOK = false end
    end
  end
end
check(rulesOK, "follow-ups come after the hand-in that unlocks them (" .. unlocks .. " of them)")
local pickups = 0
for _, s in ipairs(P.stops) do pickups = pickups + #(s.pickups or {}) end
check(pickups > 0 and pickups <= 35 - #QP.Quests.list + 1, "pick-ups fit in your log: " .. pickups)
local merged = true
for i, a in ipairs(P.stops) do for j, b in ipairs(P.stops) do
  if i < j and a.kind == "npc" and b.kind == "npc" and O:Yards(1411, a.x, a.y, b.x, b.y) < 15 then merged = false end
end end
check(merged, "one stop per quest giver")
local first = P.stops[1]
check(P.current == 1, "first stop is current")
if first.kind == "npc" then
  check(tt.last and math.abs(tt.last[2] - first.x) < 1e-9 and tt.last.title:find(first.name, 1, true), "arrow points at the first stop: " .. tostring(tt.last and tt.last.title))
else
  check(QP.char.focus == first.quest, "arrow points at the first objective")
end
check(QP.char.route and #QP.char.route >= 3, "quest list numbers follow the plan")
QP.Tracker:Refresh()
local planRows, nearbyShown = 0, false
for i = 1, T.used do
  if T.rows[i].stop then planRows = planRows + 1 end
  if T.rows[i].offer then nearbyShown = true end
end
check(planRows == #P.stops, "tracker lists every stop")
check(not nearbyShown, "'Pick up nearby' folds into the plan")
check(f.routeBtn.text.text == "Plan", "header button says Plan")


-- the same situation gives the same plan; moving a little doesn't reshuffle it
local function keys() local t = {}; for _, s in ipairs(P.stops) do t[#t + 1] = s.key end; return table.concat(t, ">") end
QP:Slash("plan fresh")
local k1 = keys()
QP:Slash("plan fresh")
check(keys() == k1, "fresh plans from the same spot are identical")
QP:Slash("plan"); QP:Slash("plan") -- off and on again
check(keys() == k1, "turning Plan off and on keeps the order")
player.x, player.y = 0.53, 0.47
QP:Slash("plan"); QP:Slash("plan")
check(keys() == k1, "moving a little and pressing Plan keeps the order")
player.x, player.y = 0.5, 0.5
-- pick-ups and hand-ins lean early
local A = { x = 0.4, y = 0.5, weight = 0, key = "a" }   -- objective 100 yd left
local B = { x = 0.62, y = 0.5, weight = 0.35, key = "b" } -- quest giver 120 yd right
local ordW = P.Order({ x = 0.5, y = 0.5 }, { A, B }, 1000, 1000)
check(ordW[1] == B, "a nearby quest giver comes before an objective that's slightly closer")
local C = { x = 0.45, y = 0.5, weight = 0, key = "c" }  -- objective 50 yd left
local D = { x = 0.95, y = 0.5, weight = 0.35, key = "d" } -- giver 450 yd right
local ordF = P.Order({ x = 0.5, y = 0.5 }, { C, D }, 1000, 1000)
check(ordF[1] == C, "but not when it means a long detour")
-- sticky: an old order that's only a little worse is kept
local E = { x = 0.3, y = 0.5, key = "e", rank = 2 }
local F = { x = 0.32, y = 0.5, key = "f", rank = 1 }
local ordS = P.Order({ x = 0.5, y = 0.5 }, { E, F }, 1000, 1000, true)
check(ordS[1] == F, "re-plans keep the old order unless the change saves real walking")
local G = { x = 0.9, y = 0.5, key = "g", rank = 1 }
local Hh = { x = 0.45, y = 0.5, key = "h", rank = 2 }
local ordG = P.Order({ x = 0.5, y = 0.5 }, { G, Hh }, 1000, 1000, true)
check(ordG[1] == Hh, "...and do change when it does")
-- objectives close together are one stop
local nearby = 0
for _, s in ipairs(P.stops) do if s.kind == "obj" and #s.quests > 1 then nearby = nearby + 1 end end
print("  merged Do stops: " .. nearby)
-- pick-up radius
QP.db.planRadius = 150
QP:Slash("plan fresh")
local far = false
local pm, ppx, ppy = QP.Quests:PlayerPos()
for _, s in ipairs(P.stops) do for _, o in ipairs(s.pickups or {}) do if QP.Offers:Yards(1411, o.giver.x, o.giver.y, ppx, ppy) > 150 then far = true end end end
check(not far, "plans only pick up quests within range")
QP.db.planRadius = 900
QP:Slash("plan fresh")

-- take everything at the first quest-giver stop
local npcIndex
for i, s in ipairs(P.stops) do if s.kind == "npc" and #s.pickups > 0 then npcIndex = i break end end
local s1 = P.stops[npcIndex]
local before = #P.stops
P:FocusStop(npcIndex)
check(P.current == npcIndex and tt.last and math.abs(tt.last[2] - s1.x) < 1e-9, "click a stop to go there now")
local nid = 500
for _, o in ipairs(s1.pickups) do
  nid = nid + 1
  table.insert(QUESTS, 2, { id = nid, title = o.title, level = o.level or 3, pin = { 1411, 0.3, 0.3 }, objectives = { { text = "x: 0/1" } } })
end
for _, id in ipairs(s1.turnins) do
  if find(id).complete then for i, q in ipairs(QUESTS) do if q.id == id then table.remove(QUESTS, i) break end end end
end
QP:Emit("QUESTS_CHANGED")
local newObj = false
for _, s in ipairs(P.stops) do if s.kind == "obj" and s.quest > 500 then newObj = true end end
check(newObj, "quests you just took are planned in (" .. before .. " -> " .. #P.stops .. " stops)")
local takenStill = false
for _, s in ipairs(P.stops) do for _, o in ipairs(s.pickups or {}) do for _, o2 in ipairs(s1.pickups) do if o.title == o2.title then takenStill = true end end end end
check(not takenStill, "taken quests drop out of the pick-ups")

-- skip
local skipRow
for i = 1, T.used do if T.rows[i].stop then skipRow = T.rows[i] break end end
skipRow.scripts.OnEnter(skipRow)
check(#GameTooltip.lines >= 2, "stop tooltip")
local skipped = skipRow.stop
skipRow.scripts.OnClick(skipRow, "RightButton")
for _, it in ipairs(menu.items) do if it.label == "Skip this stop" then it.fn() end end
local again = false
for _, s in ipairs(P.stops) do
  if s.kind == skipped.kind and ((s.kind == "obj" and s.quest == skipped.quest) or (s.kind == "npc" and s.name == skipped.name and #s.pickups == #skipped.pickups and #s.turnins == #skipped.turnins)) then again = true end
end
check(not again, "skipped stop leaves the plan")

-- the order obeys its rules
local stops = { { x = 0.1, y = 0, after = { [3] = true } }, { x = 0.2, y = 0 }, { x = 0.3, y = 0 } }
local ord = P.Order({ x = 0, y = 0 }, stops, 100, 100)
local p1, p3
for i, s in ipairs(ord) do if s == stops[1] then p1 = i end; if s == stops[3] then p3 = i end end
check(p3 < p1, "ordering keeps 'this before that'")
local ord2 = P.Order({ x = 0, y = 0 }, { { x = 0.3, y = 0 }, { x = 0.1, y = 0 }, { x = 0.2, y = 0 } }, 100, 100)
check(ord2[1].x == 0.1 and ord2[2].x == 0.2 and ord2[3].x == 0.3, "and is shortest otherwise")

local hub = P.hub
print("  next hub: " .. (hub and (hub.zone .. " near " .. hub.npc .. ", " .. hub.count .. " quests") or "none"))
check(hub == nil or (hub.m and hub.zone ~= "Durotar"), "next area is another zone")

QP:Slash("data")
local idsLine = false
for i = math.max(1, #chat - 12), #chat do if chat[i]:find("Quest ids") then idsLine = true end end
check(idsLine, "/qp data")
QP:Slash("plan")
check(not P:Active() and QP.char.route == nil, "Plan again stops it")
QP:Slash("nearby")
QP.Tracker:Refresh()
local anyOffer = false
for i = 1, T.used do if T.rows[i].offer then anyOffer = true end end
check(not anyOffer, "/qp nearby hides the section")
QP:Slash("nearby")
section("Quest ids offset")
local saved = {}
for i, q in ipairs(QUESTS) do saved[i] = q end
for i = #QUESTS, 1, -1 do table.remove(QUESTS, i) end
table.insert(QUESTS, { header = "Durotar" })
table.insert(QUESTS, { id = 788 + 700000, title = "Cutting Teeth", level = 2, pin = { 1411, 0.5, 0.5 }, objectives = {} })
table.insert(QUESTS, { id = 4641 + 700000, title = "Your Place In The World", level = 1, pin = { 1411, 0.5, 0.5 }, objectives = {} })
QP.Quests:Refresh()
O:ReadLog()
check(O.idsMatch == false and O.idOffset == 700000, "a fixed id offset is detected: " .. tostring(O.idOffset))
completedFlags[789 + 700000] = true
check(O:IsDone(789), "finished quests found through the offset")
QP:Slash("data")
local listed = false
for _, m in ipairs(chat) do if m:find("788 Cutting Teeth", 1, true) then listed = true end end
check(listed, "/qp data lists log quests against the Classic data")
for i = #QUESTS, 1, -1 do table.remove(QUESTS, i) end
for i, q in ipairs(saved) do QUESTS[i] = q end

section("Forever-only quests")
local saved2 = {}
for i, q in ipairs(QUESTS) do saved2[i] = q end
for i = #QUESTS, 1, -1 do table.remove(QUESTS, i) end
table.insert(QUESTS, { header = "Durotar" })
table.insert(QUESTS, { id = 788, title = "Cutting Teeth", level = 2, pin = { 1411, 0.5, 0.5 }, objectives = {} })
table.insert(QUESTS, { id = 99048, title = "A Missing Hand", level = 7, pin = { 1411, 0.5, 0.5 }, objectives = {} })
table.insert(QUESTS, { id = 99049, title = "Threat from Below", level = 8, pin = { 1411, 0.5, 0.5 }, objectives = {} })
QP.Quests:Refresh()
O:ReadLog()
check(O.idsMatch == true, "new Forever quests don't make ids look different")
completedFlags[789] = true
check(O:IsDone(789), "so finished Classic quests are read straight from the game")
completedFlags[789] = nil
for i = #QUESTS, 1, -1 do table.remove(QUESTS, i) end
for i, q in ipairs(saved2) do QUESTS[i] = q end
QP.Quests:Refresh()

section("Quest items")
function GetQuestLogSpecialItemInfo(i)
  local q = QUESTS[i]
  local sp = q and SPECIAL[q.id]
  if not sp then return nil end
  return "|cffffffff|Hitem:" .. sp.id .. "::::|h[" .. sp.name .. "]|h|r", "icon" .. sp.id, sp.charges or 0, sp.showComplete
end
local Items = QP.Items
for i = #QUESTS, 1, -1 do if QUESTS[i].id and QUESTS[i].id > 500 then table.remove(QUESTS, i) end end
if QP.Plan:Active() then QP:Slash("plan") end
do local ids = {}; for _, q in ipairs(QUESTS) do ids[#ids + 1] = tostring(q.id or q.header) end; print("  log: " .. table.concat(ids, ",")) end
SPECIAL[101] = { id = 4986, name = "Flawed Power Stone", charges = 3 }
SPECIAL[104] = { id = 5165, name = "Sunscale Feather" }
QP:Emit("QUESTS_CHANGED")
local bar = QuestDirectItemBar
check(bar and bar.shown, "quest item bar shows")
local b1, b2, b3 = QuestDirectItem1, QuestDirectItem2, QuestDirectItem3
check(b1.shown and b2.shown and not b3.shown, "a button per quest with an item")
check(b1.attrs.type == "item" and b1.attrs.item and b1.attrs.item:find("item:"), "secure item buttons")
local first = b1.questTitle
local d101, d104 = find(101), find(104)
print("  first button: " .. tostring(first))
check(b1.attrs.item == "item:4986" or b1.attrs.item == "item:5165", "items from the quest log")
check(b1.key.text == "sE", "keybind shown on the first button")
local withCharges = b1.attrs.item == "item:4986" and b1 or b2
check(withCharges.count.text == 3, "charges shown")
check(bar.w == 2 * 32 + 4, "bar sized to its buttons")
-- focused quest goes first
QP.Nav:Focus(104, true)
QP:Emit("QUESTS_CHANGED")
check(QuestDirectItem1.attrs.item == "item:5165", "the focused quest's item comes first")
-- combat: changes wait
combat = true
SPECIAL[103] = { id = 6000, name = "Thing" }
find(103).complete = false
QP:Emit("QUESTS_CHANGED")
check(not QuestDirectItem3.shown and Items.pending, "no rearranging in combat")
check(createdInCombat == 0, "no secure buttons made in combat")
combat = false
fire("PLAYER_REGEN_ENABLED")
check(QuestDirectItem3.shown and not Items.pending, "rearranged after combat")
SPECIAL[103] = nil
find(103).complete = true
-- tooltip
QuestDirectItem1.scripts.OnEnter(QuestDirectItem1)
check(GameTooltip.lines[#GameTooltip.lines]:find("For:"), "tooltip says which quest")
-- cooldown
cooldowns[5165] = 100
fire("BAG_UPDATE_COOLDOWN")
check(QuestDirectItem1.cd.cdset and QuestDirectItem1.cd.cdset[1] == 100, "cooldowns shown")
-- complete quests drop their item unless the game says to keep it
find(104).complete = true
QP:Emit("QUESTS_CHANGED")
local still = false
for i = 1, 8 do local b = _G["QuestDirectItem" .. i]; if b.shown and b.attrs.item == "item:5165" then still = true end end
check(not still, "finished quests' items go away")
find(104).complete = false
QP:Slash("items")
check(not bar.shown, "/qp items hides the bar")
QP:Slash("items")
check(bar.shown, "and shows it again")
SPECIAL[101], SPECIAL[104] = nil, nil
QP:Emit("QUESTS_CHANGED")
check(not bar.shown, "no items, no bar")

section("Window")
T:SetScale(1.5)
check(f.scale == 1.5 and QP.db.scale == 1.5, "scale")
local l1, t1 = QP.db.left, QP.db.top
check(l1 and t1, "scaling keeps the top-left corner: " .. tostring(l1) .. "," .. tostring(t1))
T:SetScale(9)
check(QP.db.scale == 2, "scale capped at 2")
ctrl = true
local hdr -- header frame is the first child with OnMouseWheel; reach through the title's parent
T:SetScale(1)
ctrl = false
QP:Slash("lock")
check(QP.db.locked and f.grip.shown == false, "lock hides the resize corner")
QP:Slash("unlock")
check(not QP.db.locked and f.grip.shown, "unlock")
f.grip.scripts.OnMouseDown(f.grip)
check(f.sizing, "corner starts resizing")
f.w, f.h = 340, 420
f.grip.scripts.OnMouseUp(f.grip)
check(QP.db.width == 340 and QP.db.height == 420, "new size saved")
QP:Slash("")
check(not f.shown and QP.db.hidden, "/qp hides")
QP:Slash("")
check(f.shown, "/qp shows")

section("Row actions")
QP.Tracker:Refresh()
local anyRow
for i = 1, T.used do if T.rows[i].quest then anyRow = T.rows[i] break end end
shift = true
anyRow.scripts.OnClick(anyRow, "LeftButton")
shift = false
check(linked and linked:find("quest:"), "shift-click links the quest")
anyRow.scripts.OnClick(anyRow, "RightButton")
check(menu and menu.title == anyRow.quest.title and #menu.items >= 3, "right-click menu")
for _, it in ipairs(menu.items) do if it.label == "Open in quest log" then it.fn() end end
check(openedDetails == anyRow.quest.id, "open in quest log")
local hideID = anyRow.quest.id
for _, it in ipairs(menu.items) do if it.label == "Hide from tracker" then it.fn() end end
local stillThere = false
for i = 1, T.used do if T.rows[i].quest and T.rows[i].quest.id == hideID then stillThere = true end end
check(not stillThere and QP.char.hidden[hideID], "hide from tracker")
QP:Slash("unhide")
anyRow.scripts.OnEnter(anyRow)
check(#GameTooltip.lines > 2, "row tooltip")
QP:Slash("zone")
check(QP.db.zoneOnly, "zone filter on")
local otherZone = false
for i = 1, T.used do if T.rows[i].zone == "Orgrimmar" then otherZone = true end end
check(not otherZone, "zone filter hides other zones")
QP:Slash("zone")
-- collapse a zone
local zr
for i = 1, T.used do if T.rows[i].zone then zr = T.rows[i] break end end
zr.scripts.OnClick(zr, "LeftButton")
check(QP.char.collapsed[zr.zone], "zone header collapses")
zr.scripts.OnClick(zr, "LeftButton")

section("Blizzard map focus follows")
C_SuperTrack.SetSuperTrackedQuestID(104)
check(QP.char.focus == 104 and tt.last and math.abs(tt.last[2] - 0.90) < 1e-9, "focusing on Blizzard's map moves QuestDirect too")

section("Without TomTom")
local realTomTom = TomTom
TomTom = nil
local pinned
UiMapPoint = { CreateFromCoordinates = function(m, x, y) return { m, x, y } end }
C_Map.SetUserWaypoint = function(p) pinned = p end
C_Map.ClearUserWaypoint = function() pinned = nil end
QP.Nav:Clear()
QP.Nav:Focus(104, true)
check(pinned and pinned[1] == 1411, "falls back to Blizzard's map pin")
QP.Nav:Clear()
check(pinned == nil, "and clears it")
TomTom = realTomTom

section("Combat")
combat = true
QP.db.hideBlizzard = false
T:ApplyBlizzard()
check(ObjectiveTrackerFrame.shown == false, "no frame changes in combat")
combat = false
fire("PLAYER_REGEN_ENABLED")
check(ObjectiveTrackerFrame.shown == true, "applied after combat")
QP:Slash("help")

print(string.format("\n%d passed, %d failed, %d errors", passed, failed, #errors))
for _, e in ipairs(errors) do print("ERROR: " .. e) end
os.exit((failed == 0 and #errors == 0) and 0 or 1)
