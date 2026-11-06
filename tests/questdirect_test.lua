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
  local file = line:match("^(.-%.lua)%s*$")
  if file then
    -- ForeverData.lua is made on the player's PC, so it's normal for it to be missing.
    local fn, err = loadfile(DIR .. "/" .. file)
    if fn then fn("QuestDirect", ns) elseif file ~= "ForeverData.lua" then error(err) end
  end
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
for i = 2, #list do
  local a, b = list[i - 1], list[i]
  if b.band < a.band or (b.band == a.band and b.distance < a.distance - 1) then sorted = false end
end
check(sorted, "best for your level first, then nearest")
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
  if i < j and a.kind == "npc" and b.kind == "npc" and a.later == b.later and O:Yards(1411, a.x, a.y, b.x, b.y) < 15 then merged = false end
end end
check(merged, "one stop per quest giver, and one more for hand-ins you haven't finished")
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
QP:Slash("plan radius 150")
check(QP.db.pickupRange == 150, "/qd plan radius sets the range")
QP:Slash("plan fresh")
local far = false
local pm, ppx, ppy = QP.Quests:PlayerPos()
for _, s in ipairs(P.stops) do for _, o in ipairs(s.pickups or {}) do if QP.Offers:Yards(1411, o.giver.x, o.giver.y, ppx, ppy) > 150 then far = true end end end
check(not far, "plans only pick up quests within range")
QP:Slash("plan radius zone")
check(QP.db.pickupRange == 0, "and 'zone' means all of it")
QP:Slash("plan radius 40")
check(QP.db.pickupRange == 100, "a range has a sensible minimum")
QP:Slash("plan radius 0")
check(QP.db.pickupRange == 0, "and 0 means all of it too")
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

section("Level priority")
-- A function, not a block: this file is near Lua's limit of 200 locals in one function.
;(function()
  local Offers, Plan, D = QP.Offers, QP.Plan, ns.QuestData
  if Plan:Active() then Plan:Stop() end
  local savedQuests = {}
  for i, q in ipairs(QUESTS) do savedQuests[i] = q end
  local savedLearned, savedEnders = QuestDirectDB.learned.g, QuestDirectDB.learned.e
  local savedClassic, savedLevel, savedMax = QP.db.classicOffers, UnitLevel, C_QuestLog.GetMaxNumQuestsCanAccept
  QuestDirectDB.learned.g, QuestDirectDB.learned.e = {}, {}
  QP.db.classicOffers = false
  local level = 12
  UnitLevel = function() return level end
  local function setQuests(list)
    for i = #QUESTS, 1, -1 do table.remove(QUESTS, i) end
    table.insert(QUESTS, { header = "Durotar" })
    for _, q in ipairs(list) do table.insert(QUESTS, q) end
    for id in pairs(QP.char.hidden) do QP.char.hidden[id] = nil end
    QP.Quests:Refresh()
    Offers:Invalidate()
  end
  local function quest(id, lvl, x, y, extra)
    local q = { id = id, title = "Quest " .. id, level = lvl, pin = { 1411, x, y }, objectives = { { text = "x: 0/1" } } }
    for k, v in pairs(extra or {}) do q[k] = v end
    return q
  end
  local function offer(id, lvl, x, y, name)
    QuestDirectDB.learned.g[id] = { m = 1411, x = x, y = y, t = "Offer " .. id, l = lvl, name = name or ("Giver " .. id), f = "Horde" }
    Offers:Invalidate()
  end
  local function ender(id, x, y, name)
    QuestDirectDB.learned.e[id] = { m = 1411, x = x, y = y, name = name }
  end
  local function objOf(id)
    for i, s in ipairs(Plan.stops) do
      if s.kind == "obj" then for _, q in ipairs(s.quests) do if q == id then return s, i end end end
    end
  end
  local function bandsInOrder()
    local top = 0
    for _, s in ipairs(Plan.stops) do
      if (s.band or 1) < top then return false end
      top = s.band or 1
    end
    return true
  end

  -- Which band is which, at level 12
  local me12 = Offers:Me()
  check(me12.level == 12 and me12.green == 6, "level 12: grey is below 6")
  check(Offers:Band(12, me12) == 1 and Offers:Band(14, me12) == 1, "your level and two above are right for you")
  check(Offers:Band(15, me12) == 2 and Offers:Band(16, me12) == 2, "three and four above are harder")
  check(Offers:Band(17, me12) == 4, "five above is far too hard")
  check(Offers:Band(6, me12) == 1 and Offers:Band(5, me12) == 3, "grey is too easy, the level above it isn't")
  check(Offers:Band(nil, me12) == 1 and Offers:Band(0, me12) == 1, "no level known: no penalty")
  check(Offers:Band(12, me12, true) == 2 and Offers:Band(nil, me12, true) == 2, "a group quest counts as harder on your own")
  local realGroup = IsInGroup
  IsInGroup = function() return true end
  check(Offers:Band(12, me12, true) == 1, "but not in a group")
  IsInGroup = realGroup
  check(Offers:QuestBand({ level = 17, complete = true }, me12) == 1, "a finished quest is worth handing in now, whatever its level")
  D.q[89050] = { "Group Quest", 12, 10, 178, 0, "", 0, 0, 1, "", "" }
  Offers.info[89050] = nil
  check(Offers:QuestBand({ level = 12, dbid = 89050 }, me12) == 2, "a quest in your log the data says needs a group")

  -- The case reported: a level 15 right next to you, level 12s further off.
  setQuests({
    quest(301, 15, 0.52, 0.50),
    quest(302, 12, 0.20, 0.20),
    quest(303, 13, 0.80, 0.80),
    quest(304, 5, 0.51, 0.51),
    quest(305, 17, 0.53, 0.53),
    quest(306, 15, 0.51, 0.49, { complete = true, turnin = { 1411, 0.54, 0.50 } }),
  })
  ender(306, 0.54, 0.50, "Ready Hand-in")
  QP:Slash("plan fresh")
  local _, i301 = objOf(301)
  local _, i302 = objOf(302)
  local _, i303 = objOf(303)
  local _, i304 = objOf(304)
  local _, i305 = objOf(305)
  check(i302 < i301 and i303 < i301, "level 12 and 13 quests come before the level 15, however close it is")
  check(i301 < i304, "harder quests before ones too easy to matter")
  check(i304 < i305, "far too hard comes last")
  check(bandsInOrder(), "the whole plan keeps the bands in order")
  check(Plan.stops[1].kind == "npc" and Plan.stops[1].turnins[1] == 306, "a finished quest is handed in first, level 15 or not")
  check(QP.char.route and QP.char.route[1] == 306, "the quest list numbers follow")

  -- Objectives side by side but of different difficulty stay separate.
  setQuests({ quest(311, 12, 0.60, 0.60), quest(312, 15, 0.601, 0.601), quest(313, 13, 0.602, 0.602) })
  QP:Slash("plan fresh")
  local s311, n311 = objOf(311)
  local s312, n312 = objOf(312)
  local s313 = objOf(313)
  check(s311 == s313, "two right for you close together are still one stop")
  check(s311 ~= s312 and n311 < n312, "a harder one next to them is its own later stop")
  check(s312.band == 2 and s311.band == 1, "with its band")
  check(s312.weight == 0 and s311.weight > 0, "and only quests near your level get the small pull forward")
  setQuests({ quest(315, 10, 0.60, 0.60) })
  QP:Slash("plan fresh")
  check(objOf(315).weight > 0 and setQuests({ quest(316, 9, 0.60, 0.60) }) == nil, "two below your level gets it")
  QP:Slash("plan fresh")
  check(objOf(316).weight == 0, "three below doesn't")
  setQuests({ quest(317, 14, 0.60, 0.60) })
  QP:Slash("plan fresh")
  check(objOf(317).weight == 0, "nor two above")
  setQuests({ quest(318, 13, 0.60, 0.60) })
  QP:Slash("plan fresh")
  check(objOf(318).weight > 0, "one above does")

  -- A quest giver: pick up now, come back for the hand-in once it's done.
  setQuests({ quest(321, 12, 0.20, 0.20), quest(322, 15, 0.70, 0.70) })
  ender(321, 0.45, 0.45, "Hub")
  ender(322, 0.45, 0.45, "Hub")
  offer(90321, 12, 0.45, 0.45, "Hub")
  QP:Slash("plan fresh")
  local hubNow, hubLater, hubHard
  local where = {}
  for i, s in ipairs(Plan.stops) do
    where[s] = i
    if s.kind == "npc" and s.name == "Hub" then
      if not s.later then hubNow = s elseif s.later == 1 then hubLater = s else hubHard = s end
    end
  end
  local o321, o322 = objOf(321), objOf(322)
  check(hubNow and #hubNow.pickups == 1 and #hubNow.turnins == 0, "the pick-up is its own visit")
  check(hubLater and hubLater.turnins[1] == 321 and #hubLater.pickups == 0, "the hand-in is another")
  check(hubHard and hubHard.turnins[1] == 322 and hubHard.band == 2, "and a harder quest's hand-in waits with it")
  check(where[hubNow] < where[o321], "you pick up before going off to do the objective")
  check(where[o321] < where[hubLater], "and hand in after it")
  check(where[o322] < where[hubHard] and where[hubLater] < where[o322], "the harder quest and its hand-in come after")
  check(hubNow.key == "n:Hub" and hubLater.key == "n:Hub:later1" and hubHard.key == "n:Hub:later2", "each visit keeps its own place in the plan")
  check(bandsInOrder(), "nothing there tangles the bands")
  QuestDirectDB.learned.g, QuestDirectDB.learned.e = {}, {}

  -- Levelling up re-sorts the plan.
  setQuests({ quest(331, 15, 0.52, 0.50), quest(332, 12, 0.20, 0.20) })
  QP:Slash("plan fresh")
  local _, a331 = objOf(331)
  local _, a332 = objOf(332)
  check(a332 < a331, "level 15 waits at level 12")
  level = 13
  fire("PLAYER_LEVEL_UP")
  runTimers(2)
  check(objOf(331).band == 1, "level 13: it's right for you now")
  _, a331 = objOf(331)
  _, a332 = objOf(332)
  check(a331 < a332, "and the nearer one comes first")
  level = 12
  fire("PLAYER_LEVEL_UP")
  runTimers(2)
  _, a331 = objOf(331)
  _, a332 = objOf(332)
  check(a332 < a331 and bandsInOrder(), "an old order that breaks the bands is put right, not kept")
  -- Stays put otherwise
  local kept = table.concat(QP.char.planOrder, ">")
  QP:Slash("plan"); QP:Slash("plan")
  check(table.concat(QP.char.planOrder, ">") == kept, "turning Plan off and on keeps the order")
  Plan:Stop()

  -- Pick-ups: the whole zone, and the right level first
  setQuests({})
  offer(90401, 15, 0.51, 0.50)  -- right beside you, but harder
  offer(90402, 12, 0.05, 0.05)  -- the far corner of the zone
  offer(90403, 13, 0.95, 0.95)  -- the other far corner
  offer(90404, 12, 0.30, 0.30)
  local far = Offers:Yards(1411, 0.05, 0.05, 0.5, 0.5)
  check(far > 900, "the far giver is well over the old range: " .. math.floor(far))
  QP:Slash("plan fresh")
  local function taken()
    local t = {}
    for _, s in ipairs(Plan.stops) do for _, o in ipairs(s.pickups or {}) do t[o.id] = true end end
    return t
  end
  local got = taken()
  check(got[90402] and got[90403], "plans find quests anywhere in the zone")
  local hardStop, goodStop
  for i, s in ipairs(Plan.stops) do
    for _, o in ipairs(s.pickups or {}) do
      if o.id == 90401 then hardStop = i elseif not goodStop or i > goodStop then goodStop = i end
    end
  end
  check(hardStop and hardStop > goodStop, "the harder pick-up comes after the right ones, even right beside you")
  check(Plan.stops[hardStop].band == 2, "a stop with only harder pick-ups is itself later")
  -- Short of room: right level beats close.
  C_QuestLog.GetMaxNumQuestsCanAccept = function() return 3 end
  QP:Slash("plan fresh")
  got = taken()
  check(got[90404] and got[90402] and got[90403] and not got[90401], "with room for three, the harder one is what's left out")
  C_QuestLog.GetMaxNumQuestsCanAccept = function() return 1 end
  QP:Slash("plan fresh")
  got = taken()
  check(got[90404] and not got[90401] and not got[90402], "with room for one, the nearest quest right for you")
  C_QuestLog.GetMaxNumQuestsCanAccept = savedMax
  -- A hand-in is worth the trip even if all that's on offer there is harder.
  table.insert(QUESTS, quest(431, 15, 0.5, 0.5, { complete = true, turnin = { 1411, 0.51, 0.50 } }))
  ender(431, 0.51, 0.50, "Giver 90401")
  QP.Quests:Refresh()
  QP:Slash("plan fresh")
  for _, s in ipairs(Plan.stops) do
    if s.name == "Giver 90401" then check(s.band == 1 and #s.turnins == 1 and #s.pickups == 1 and s.pickups[1].band == 2, "a stop with a finished quest counts as right") end
  end
  table.remove(QUESTS)
  QuestDirectDB.learned.e[431] = nil
  QP.Quests:Refresh()
  Offers:Invalidate()
  -- A mixed giver is visited for the good quest.
  offer(90405, 12, 0.51, 0.50, "Giver 90401")
  QP:Slash("plan fresh")
  for _, s in ipairs(Plan.stops) do
    if s.name == "Giver 90401" then check(s.band == 1 and #s.pickups == 2, "a giver with one right quest counts as right") end
  end
  QuestDirectDB.learned.g[90405] = nil
  QP:Slash("plan radius 200")
  QP:Slash("plan fresh")
  got = taken()
  check(got[90401] and not got[90402], "a set range still limits it")
  QP:Slash("plan radius zone")
  Plan:Stop()

  -- Saying so
  local before = #chat
  QP:Slash("plan fresh")
  check(table.concat(chat, "\n", before + 1):find("1 that aren't right for your level come last", 1, true), "the plan says so")
  local hardRow
  QP.Tracker:Refresh()
  for i = 1, T.used do if T.rows[i].stop and T.rows[i].stop.band == 2 then hardRow = T.rows[i] end end
  wipe(GameTooltip.lines)
  hardRow.scripts.OnEnter(hardRow)
  check(table.concat(GameTooltip.lines, " "):find("Later: harder than your level", 1, true), "and the stop's tooltip says why")
  Plan:Stop()

  -- Pick up nearby, with no plan
  local near = Offers:Nearby()
  check(near[1].band == 1 and near[1].id == 90404, "Pick up nearby: nearest right for you first")
  check(near[#near].id == 90401, "and the harder one last, though it's right beside you")
  QP.db.nearbyMax = 3
  QP.Tracker:Refresh()
  local shown = {}
  for i = 1, T.used do if T.rows[i].offer then shown[T.rows[i].offer.id] = true end end
  check(shown[90402] and not shown[90401], "so a short list shows what's right for you")
  QP.db.nearbyMax = 5
  QuestDirectDB.learned.g = {}
  Offers:Invalidate()

  -- Next quest and the quest list, with no plan
  local function far2(q, d) q.fixed = d return q end
  local realDist = C_QuestLog.GetDistanceSqToQuest
  C_QuestLog.GetDistanceSqToQuest = function(id)
    local q = find(id)
    return q.fixed and q.fixed * q.fixed or 1e8, true
  end
  setQuests({ far2(quest(401, 15, 0.51, 0.5), 50), far2(quest(402, 12, 0.2, 0.2), 900), far2(quest(403, 12, 0.3, 0.3), 700), far2(quest(404, 5, 0.5, 0.51), 10) })
  check(QP.Nav:Nearest().id == 403, "next quest: the nearest right for you, not the nearest")
  check(QP.Nav:Nearest(403).id == 402, "and the one after")
  local order, groups = QP.Quests:Sorted()
  local ids = {}
  for _, q in ipairs(groups[order[1]]) do ids[#ids + 1] = q.id end
  check(table.concat(ids, ",") == "403,402,401,404", "the quest list goes the same way: " .. table.concat(ids, ","))
  setQuests({ far2(quest(411, 15, 0.51, 0.5), 50), far2(quest(412, 15, 0.51, 0.5, { complete = true }), 400) })
  check(QP.Nav:Nearest().id == 412, "a finished quest counts as right for you")
  -- Don't send you out of the zone for a better level.
  setQuests({ far2(quest(421, 15, 0.51, 0.5), 100) })
  table.insert(QUESTS, { header = "Orgrimmar" })
  table.insert(QUESTS, far2(quest(422, 12, 0.5, 0.5, { qmap = 1454 }), 50))
  QP.Quests:Refresh()
  check(QP.Nav:Nearest().id == 421, "one in this zone wins over a better one in another")
  QP.char.hidden[421] = true
  check(QP.Nav:Nearest().id == 422, "and if there's nothing here, the other zone")
  QP.char.hidden[421] = nil
  C_QuestLog.GetDistanceSqToQuest = realDist

  -- Next zone: quests right for you count for more
  local realByMap, realPos, realCache = Offers.byMap, Offers.npcPos, Offers.hubCache
  local function hubAt(id, x)
    D.q[id] = { "Hub " .. id, 12, 1, 178, 0, "", 0, 0, 0, tostring(id), "" }
    D.n[id] = { "Hub Giver " .. id, 1, "" }
    Offers.info[id] = nil
    return { m = 1454, x = x, y = 0.5, inst = 1, wx = 1500, wy = -4200 - x * 1000 }
  end
  setQuests({})
  -- The harder hub is the nearer of the two.
  local spotA, spotB = hubAt(89101, 0.9), hubAt(89103, 0.1)
  hubAt(89102, 0.9); hubAt(89104, 0.1)
  D.q[89101][2], D.q[89102][2] = 15, 15
  Offers.info[89101], Offers.info[89102] = nil, nil
  Offers.npcPos = { [89101] = { spotA }, [89102] = { spotA }, [89103] = { spotB }, [89104] = { spotB } }
  Offers.byMap = { [1454] = { 89101, 89102, 89103, 89104 } }
  Offers.ready = true
  local hub1 = Offers:NextHub(true)
  check(hub1 and hub1.count == 2 and hub1.minL == 12, "next zone: the hub right for your level, not the harder one")
  Offers.byMap = { [1454] = { 89101, 89102 } }
  Offers.npcPos = { [89101] = { spotA }, [89102] = { spotA } }
  local hub2 = Offers:NextHub(true)
  check(hub2 and hub2.count == 2 and hub2.minL == 15, "but two harder quests still beat nowhere to go")
  Offers.byMap, Offers.npcPos, Offers.hubCache = realByMap, realPos, realCache
  for _, id in ipairs({ 89050, 89101, 89102, 89103, 89104 }) do D.q[id], D.n[id], Offers.info[id] = nil, nil, nil end

  -- Back as it was
  UnitLevel = savedLevel
  QP.db.classicOffers = savedClassic
  QuestDirectDB.learned.g, QuestDirectDB.learned.e = savedLearned, savedEnders
  for i = #QUESTS, 1, -1 do table.remove(QUESTS, i) end
  for i, q in ipairs(savedQuests) do QUESTS[i] = q end
  QP.Quests:Refresh()
  Offers:Invalidate()
end)()

if ns.ForeverData then
  print("\n== Forever data: a real file is loaded, so the made-up one below is skipped")
else
  section("Forever data")
  local O = QP.Offers
  local function tipOf(row)
    wipe(GameTooltip.lines)
    row.scripts.OnEnter(row)
    return table.concat(GameTooltip.lines, " | ")
  end
  local CREDIT = "Data from ForeverDB.net (https://foreverdb.net)"
  local function creditRow()
    for i = 1, T.used do if T.rows[i].title.text == CREDIT then return T.rows[i] end end
  end
  local function offerOf(list, id) for _, o in ipairs(list) do if o.dbid == id then return o end end end

  -- Without the file nothing changes.
  check(O:Credit() == nil, "no file, no credit")
  T:Refresh()
  check(not creditRow(), "and no credit row")
  local before = #chat
  QP:Slash("data")
  check(table.concat(chat, "\n", before + 1):find("No Forever data file"), "/qd data says there's no file")

  -- Quests in the Classic data, as they'd be before the overlay.
  local D = ns.QuestData
  D.q[88001] = { "Old Title", 5, 3, 178, 1, "", 0, 0, 0, "3143", "3143" }
  D.q[88002] = { "Classic Only Label", 5, 3, 178, 0, "", 0, 0, 0, "3143", "3143" }
  D.q[88003] = { "Not In ForeverDB", 5, 3, 178, 0, "", 0, 0, 0, "3143", "3143" }
  D.n[700099] = { "Old Name", 1, "" }
  local gornek = O.npcPos[3143][1]
  local gx, gy = gornek.x, gornek.y
  ns.ForeverData = {
    build = "9.9", made = "2026-01-01", credit = CREDIT,
    q = {
      [88001] = { "New Title", 6, false, false, false, false, "700002", false, 1, 0 },
      [88002] = { false, false, false, false, false, false, false, false, 0, 0 },
      [88101] = { "Forever Quest", 6, 2, 178, 0, "", "700001", "700001", 1, 1 },
      [88102] = { "Alliance Quest", 6, 2, 77, 0, "", "700001", "700001", 1, 1 },
      [88103] = { "Paladin Quest", 6, 2, 0, 2, "", "700001", "700001", 1, 1 },
      [88104] = { "Warrior Quest", 6, 2, 0, 1, "", "700001", "700001", 1, 1 },
      [88105] = { "Second Part", 6, 2, 178, 0, "88101", "700001", "700001", 1, 1 },
      [88107] = { "Hand In Only", 6, 2, 178, 0, "", "", "700003", 0, 1 },
      [88108] = { "New Zone Quest", 6, 2, 178, 0, "", "700004", "700004", 1, 1 },
      [88109] = { "Marker Quest", 6, 2, 178, 0, "", "900088109", "", 2, 0 },
    },
    n = { [700001] = "Forever Giver", [700002] = "Seen Giver", [700003] = "Seen Hand-in", [700004] = "Far Giver", [700099] = "New Name", [900088109] = "Quest giver" },
    p = {
      [3143] = "1411,10.0,20.0",
      [700001] = "1411,30.0,40.0",
      [700002] = "1411,31.0,41.0",
      [700003] = "1454,50.0,50.0;1411,32.0,42.0",
      [700004] = "1460,50.0,50.0",
      [700098] = "1411,33.0,43.0",
      [900088109] = "1411,34.0,44.0",
    },
  }
  O:Info(88001) -- cached before the overlay
  O:ByTitle()
  O:Groups()
  O:UseForeverData()
  local f1 = ns.ForeverData.q[88001]
  check(D.q[88001][1] == "New Title" and D.q[88001][2] == 6, "known quest takes the new title and level")
  check(D.q[88001][3] == 3 and D.q[88001][5] == 1 and D.q[88001][10] == "700002" and D.q[88001][11] == "3143", "and keeps what the file leaves alone")
  check(O:Info(88001).title == "New Title", "what was read earlier isn't kept")
  check(O:ByTitle()["new title"] and not O:ByTitle()["old title"], "matching by title uses the new title")
  check(D.q[88101][1] == "Forever Quest" and D.q[88101][9] == 0 and D.q[88101][7] == 0, "a new quest gets a whole record")
  check(D.n[700001][1] == "Forever Giver" and D.n[700099][1] == "New Name", "new NPCs and new names")
  check(D.n[700098] and D.n[700098][3] == "", "an NPC with only a place still gets a record")
  D.q[88001][1] = "Changed Here"
  O:UseForeverData()
  check(D.q[88001][1] == "Changed Here", "laying it over twice does nothing")
  D.q[88001][1] = "New Title"
  O.info[88001] = nil

  local info = O:Info(88001)
  check(info.fdb and info.seenG == 1 and info.seenE == 0, "the quest keeps its labels")
  local plain = O:Info(88003)
  check(plain and not plain.fdb and plain.seenG == 0, "a quest ForeverDB doesn't list has none")
  check(D.q[88003][1] == "Not In ForeverDB", "and is still there")

  -- Placing
  O.ready = false
  local built
  O:Build(function() built = true end)
  runTimers(5)
  check(built and O.ready, "placed again with the new data")
  local s1 = O.npcPos[700001] and O.npcPos[700001][1]
  check(s1 and s1.m == 1411 and math.abs(s1.x - 0.30) < 1e-9 and math.abs(s1.y - 0.40) < 1e-9, "percent on the zone map becomes 0-1")
  local wx, wy = toWorld(1411, 0.30, 0.40)
  check(s1 and s1.inst == 1 and math.abs(s1.wx - wx) < 1e-6 and math.abs(s1.wy - wy) < 1e-6, "and it knows its world spot, for finding hubs")
  local g2 = O.npcPos[3143][1]
  check(g2 and math.abs(g2.x - 0.10) < 1e-9 and (g2.x ~= gx or g2.y ~= gy), "where players saw an NPC beats its Classic spawn")
  check(#O.npcPos[700003] == 2 and O.npcPos[700003][1].m == 1454, "an NPC can stand on more than one map")
  local far = O.npcPos[700004] and O.npcPos[700004][1]
  check(far and far.m == 1460 and far.inst == nil, "a map the game can't place in the world still counts")
  check(O.npcPos[700098], "an NPC with no Classic spot is placed")

  -- Offers
  O:Invalidate()
  local list = O:ForMap(1411)
  local fq = offerOf(list, 88101)
  check(fq and fq.source == "forever" and fq.label == 1 and fq.fdb, "a new quest is offered, labelled as seen in Forever")
  check(fq and fq.giver.name == "Forever Giver" and math.abs(fq.giver.x - 0.30) < 1e-9, "at the place players saw its giver")
  check(not offerOf(list, 88102), "the other side's quest isn't")
  check(not offerOf(list, 88103), "another class's quest isn't")
  check(offerOf(list, 88104), "your class's quest is")
  check(not offerOf(list, 88105), "a follow-up waits for its earlier quest")
  QP.char.done[88101] = true
  O:Invalidate()
  check(offerOf(O:ForMap(1411), 88105), "and comes after it")
  check(not offerOf(O:ForMap(1411), 88101), "what's done isn't offered")
  QP.char.done[88101] = nil
  O:Invalidate()
  list = O:ForMap(1411)
  check(not offerOf(list, 88107), "a hand-in-only quest is never offered")
  local mq = offerOf(list, 88109)
  check(mq and mq.giver.name == "Quest giver" and mq.label == 2, "a map marker works as a giver, with its own label")
  local classicQ = offerOf(list, 88002)
  check(classicQ and classicQ.source == "classic" and classicQ.fdb and classicQ.giver.name, "a Classic-labelled quest stays labelled Classic")
  local plainQ = offerOf(list, 88003)
  check(plainQ and plainQ.source == "classic" and not plainQ.fdb, "a quest outside ForeverDB is plain Classic")
  check(offerOf(O:ForMap(1460), 88108), "a zone only Forever has gets offers")
  -- Learned and game sources stay first, and take the credit when they use the data.
  local gameOffer = offerOf(list, 88001)
  check(gameOffer and gameOffer.title == "New Title" and gameOffer.giver.name == "Seen Giver", "a changed giver is used")

  -- /qd classic off keeps what was seen in Forever
  QP:Slash("classic off")
  list = O:ForMap(1411)
  check(offerOf(list, 88101) and not offerOf(list, 88002) and not offerOf(list, 88003), "/qd classic off leaves what players saw")
  QP:Slash("classic on")

  -- Hand-ins
  local e = O:Ender({ id = 88107, dbid = 88107 }, 1411)
  check(e and e.name == "Seen Hand-in" and e.m == 1411 and e.fdb and e.label == 1, "a hand-in-only quest knows its hand-in, on your map first")
  e = O:Ender({ id = 88107, dbid = 88107 })
  check(e and e.m == 1454, "and elsewhere")
  e = O:Ender({ id = 88001, dbid = 88001 }, 1411)
  check(e and e.name == "Gornek" and e.label == 0 and e.fdb, "Classic hand-in keeps its label")

  -- Credit and labels on screen
  check(O:Credit() == CREDIT, "credit available")
  QP.db.nearby = true
  QP.db.nearbyMax = 50
  if QP.Plan:Active() then QP.Plan:Stop(true) end
  T:Refresh()
  local cr = creditRow()
  check(cr and cr.shown, "the credit shows under the list")
  check(cr == T.rows[T.used], "at the very end")
  local offerRow
  for i = 1, T.used do if T.rows[i].offer and T.rows[i].offer.dbid == 88101 then offerRow = T.rows[i] end end
  check(offerRow, "the new quest is in Pick up nearby")
  if offerRow then
    local tip = tipOf(offerRow)
    check(tip:find("Seen in WoW Forever", 1, true), "tooltip label: " .. tip)
    check(tip:find(CREDIT, 1, true), "tooltip credit")
  end
  local r = T:Acquire()
  r.offer = classicQ
  local tip = tipOf(r)
  check(tip:find("Classic quest data", 1, true) and tip:find(CREDIT, 1, true), "Classic-labelled offer: label and credit: " .. tip)
  r.offer = plainQ
  tip = tipOf(r)
  check(tip:find("Classic quest data", 1, true) and not tip:find(CREDIT, 1, true), "plain Classic offer needs no credit")
  r.offer = mq
  check(tipOf(r):find("From the Forever client", 1, true), "the client's marker says so")
  r.offer = nil
  r.stop = { kind = "npc", name = "Someone", turnins = {}, pickups = { { title = "A", fdb = true, label = 1 } } }
  tip = tipOf(r)
  check(tip:find("Seen in WoW Forever", 1, true) and tip:find(CREDIT, 1, true), "plan stop: label and credit")
  r.stop.pickups[2] = { title = "B", fdb = true, label = 0 }
  check(tipOf(r):lower():find("part seen in wow forever, part classic data", 1, true), "a mixed stop says so")
  r.stop.pickups = { { title = "A" } }
  tip = tipOf(r)
  check(not tip:find(CREDIT, 1, true), "a stop not using the data has no credit")
  table.insert(QUESTS, { id = 88107, title = "Hand In Only", level = 6, pin = { 1411, 0.3, 0.3 }, objectives = {} })
  QP:Emit("QUESTS_CHANGED")
  O:ReadLog()
  r = T:Acquire() -- the list was redrawn
  r.stop = { kind = "npc", name = "Someone", turnins = { 88107 }, pickups = {} }
  tip = tipOf(r)
  check(QP.Quests:Get(88107).dbid == 88107 and tip:find(CREDIT, 1, true) and tip:find("Seen in WoW Forever", 1, true), "a stop handing in uses the hand-in's label")
  table.remove(QUESTS)
  QP:Emit("QUESTS_CHANGED")
  r = T:Acquire()
  r.hub = { zone = "Far", count = 2, npc = "Someone", turnins = 0 }
  check(tipOf(r):find(CREDIT, 1, true), "next-zone tooltip credit")
  r.hub = nil
  r.away = { title = "Far Quest", npc = "Someone", zone = "Far", m = 1454 }
  check(tipOf(r):find(CREDIT, 1, true), "hand-in elsewhere tooltip credit")
  r.away = nil

  before = #chat
  QP:Slash("data")
  local said = table.concat(chat, "\n", before + 1)
  check(said:find("Forever data: 10 quests, 9 seen in WoW Forever", 1, true), "/qd data counts it: " .. said)
  check(said:find("build 9.9, made 2026-01-01", 1, true), "and says how old it is")
  check(said:find(CREDIT, 1, true), "and credits it")

  -- Loading the add-on with the file there lays it over without being asked.
  ns.ForeverData = { build = "9.9", made = "2026-01-01", credit = CREDIT, n = {}, p = {},
    q = { [88201] = { "Loaded With The File", 6, 2, 178, 0, "", "700001", "700001", 1, 1 } } }
  assert(loadfile(DIR .. "/Offers.lua"))("QuestDirect", ns)
  check(D.q[88201] and D.q[88201][1] == "Loaded With The File", "the file applies itself at load")
end

print(string.format("\n%d passed, %d failed, %d errors", passed, failed, #errors))
for _, e in ipairs(errors) do print("ERROR: " .. e) end
os.exit((failed == 0 and #errors == 0) and 0 or 1)
