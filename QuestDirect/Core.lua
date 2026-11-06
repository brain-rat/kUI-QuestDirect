-- QuestDirect · Core
-- Saved settings, events, small helpers and slash commands.

local ADDON, ns = ...
local QP = {}
ns.QP = QP
_G.QuestDirect = QP

QP.defaults = {
  scale = 1.0,          -- tracker scale
  width = 300,          -- tracker size (unscaled)
  height = 380,
  left = nil, top = nil, -- saved position (nil = default spot)
  locked = false,       -- no dragging or resizing
  alpha = 0.75,         -- background opacity
  hideBlizzard = true,  -- hide Blizzard's objective tracker
  zoneOnly = false,     -- only quests in the zone you're in
  autoNext = true,      -- after finishing the focused quest, focus the next one
  arrival = 12,         -- yards: a route step or travel hop counts as reached
  nearby = true,        -- show quests to pick up nearby
  nearbyMax = 5,        -- how many of them
  pickups = true,       -- plans include quests to pick up
  classicOffers = true, -- use the Classic quest data (not just what the game, you and players in Forever have seen)
  showGrey = false,     -- suggest grey (too easy) quests too
  maxAbove = 3,         -- suggest quests up to this many levels above you
  pickupRange = 0,      -- yards: plans pick up quests within this distance of you (0: the whole zone)
  items = true,         -- quest item buttons
}

function QP:Print(msg, ...)
  if select("#", ...) > 0 then msg = msg:format(...) end
  DEFAULT_CHAT_FRAME:AddMessage("|cff7fc8ffQuestDirect|r " .. tostring(msg))
end

local function Secret(v) return issecretvalue ~= nil and issecretvalue(v) end
QP.Secret = Secret

------------------------------------------------------------------------
-- Events and internal messages
------------------------------------------------------------------------

local frame = CreateFrame("Frame")
local handlers, listeners = {}, {}

function QP:On(event, fn)
  if not handlers[event] then
    handlers[event] = {}
    pcall(frame.RegisterEvent, frame, event)
  end
  table.insert(handlers[event], fn)
end

frame:SetScript("OnEvent", function(_, event, ...)
  for _, fn in ipairs(handlers[event] or {}) do
    local ok, err = pcall(fn, ...)
    if not ok then geterrorhandler()(err) end
  end
end)

function QP:Listen(msg, fn)
  listeners[msg] = listeners[msg] or {}
  table.insert(listeners[msg], fn)
end

function QP:Emit(msg, ...)
  for _, fn in ipairs(listeners[msg] or {}) do
    local ok, err = pcall(fn, ...)
    if not ok then geterrorhandler()(err) end
  end
end

local pending = {}
function QP:EmitSoon(msg, delay)
  if pending[msg] then return end
  pending[msg] = true
  C_Timer.After(delay or 0.2, function()
    pending[msg] = nil
    QP:Emit(msg)
  end)
end

------------------------------------------------------------------------
-- Saved data
------------------------------------------------------------------------

QP:On("ADDON_LOADED", function(name)
  if name ~= ADDON then return end
  QuestDirectDB = type(QuestDirectDB) == "table" and QuestDirectDB or {}
  QuestDirectCharDB = type(QuestDirectCharDB) == "table" and QuestDirectCharDB or {}
  for k, v in pairs(QP.defaults) do
    if QuestDirectDB[k] == nil then QuestDirectDB[k] = v end
  end
  local d = QuestDirectDB
  d.planRadius = nil -- the old setting, 900 yards for everyone: plans now use the whole zone
  d.learned = type(d.learned) == "table" and d.learned or {}
  d.learned.g = d.learned.g or {} -- [questID] = where it was offered: m, x, y, name, n (npc), t, l, f
  d.learned.e = d.learned.e or {} -- [questID] = where it was handed in
  local c = QuestDirectCharDB
  c.hidden = c.hidden or {}     -- [questID] = true: left out of the tracker
  c.collapsed = c.collapsed or {} -- [zone header] = true
  c.ignored = c.ignored or {}   -- [quest title or id] = true: never suggest
  c.done = c.done or {}         -- [questID] = true: handed in (seen by QuestDirect)
  c.doneTitles = c.doneTitles or {}
  c.logTitles = c.logTitles or {} -- [questID] = title, so hand-ins can be matched by name
  if not c.planOn then c.route = nil end -- { questID, ... } plan order for the quest list
  QP.db, QP.char = QuestDirectDB, c
  QP:Emit("READY")
end)

QP:On("PLAYER_LOGIN", function() QP:Emit("LOGIN") end)

------------------------------------------------------------------------
-- Slash commands
------------------------------------------------------------------------

local HELP = {
  "/qd - show or hide the tracker",
  "/qd lock | unlock - stop or allow dragging and resizing",
  "/qd scale 1.2 - set the size (0.5 to 2); Ctrl + mouse wheel on the title bar also works",
  "/qd alpha 0.6 - background opacity (0 to 1)",
  "/qd plan - plan this zone: quest givers, hand-ins, pick-ups and objectives in order; again to stop",
  "/qd plan fresh - plan from scratch (ignore the previous order);  /qd plan radius 900 - pick-up range in yards (zone: all of it)",
  "/qd items - show or hide the quest item buttons;  /qd items reset - put them back next to the tracker",
  "/qd nearby - show or hide 'Pick up nearby';  /qd pickups - include pick-ups in plans (toggle)",
  "/qd grey - suggest grey quests too (toggle);  /qd above 3 - suggest up to this many levels above you",
  "/qd classic on | off - use the Classic quest data;  /qd unignore - suggest quests you dismissed again",
  "/qd data - what QuestDirect knows: quest data, NPCs placed, what it has learned",
  "/qd next - focus the best next quest for your level;  /qd clear - stop navigating",
  "/qd zone - show only this zone's quests (toggle)",
  "/qd blizzard on | off - show or hide Blizzard's quest tracker",
  "/qd unhide - show quests you hid;  /qd reset - put the tracker back in its default spot",
}

function QP:Slash(msg)
  local cmd, rest = (msg or ""):lower():match("^%s*(%S*)%s*(.-)%s*$")
  local db, T, N = self.db, self.Tracker, self.Nav
  if cmd == "" or cmd == "show" or cmd == "toggle" then
    T:Toggle()
  elseif cmd == "lock" or cmd == "unlock" then
    db.locked = cmd == "lock"
    T:ApplyLock()
    self:Print("Tracker %s.", db.locked and "locked" or "unlocked: drag the title bar, resize from the corner")
  elseif cmd == "scale" then
    local n = tonumber(rest)
    if not n then self:Print("Scale is %.2f. Use /qd scale 0.5 to 2.", db.scale) return end
    T:SetScale(n)
  elseif cmd == "alpha" then
    local n = tonumber(rest)
    if not n then self:Print("Opacity is %.2f. Use /qd alpha 0 to 1.", db.alpha) return end
    db.alpha = math.max(0, math.min(1, n))
    T:ApplyLook()
  elseif (cmd == "route" or cmd == "plan") and rest == "fresh" then
    self.Plan:Build(true, true)
  elseif (cmd == "route" or cmd == "plan") and rest:match("^radius") then
    local n = tonumber(rest:match("%d+"))
    if rest:match("zone") or n == 0 then
      db.pickupRange = 0
    elseif n then
      db.pickupRange = math.max(100, math.min(5000, n))
    end
    if db.pickupRange > 0 then
      self:Print("Plans pick up quests within %d yards of you.", db.pickupRange)
    else
      self:Print("Plans pick up quests from the whole zone.")
    end
  elseif cmd == "route" or cmd == "plan" then
    N:ToggleRoute()
  elseif cmd == "items" then
    if rest == "reset" then
      db.itemLeft, db.itemTop = nil, nil
      if self.Items.bar and not InCombatLockdown() then self.Items:Place() end
      self:Print("Quest item bar back next to the tracker.")
    else
      db.items = not db.items
      self.Items:Update()
      self:Print("Quest item buttons %s.", db.items and "shown" or "hidden")
    end
  elseif cmd == "nearby" then
    db.nearby = not db.nearby
    self:Print("Pick up nearby: %s.", db.nearby and "shown" or "hidden")
    T:Refresh()
  elseif cmd == "pickups" then
    db.pickups = not db.pickups
    self:Print("Plans %s quests to pick up.", db.pickups and "include" or "leave out")
  elseif cmd == "grey" or cmd == "gray" then
    db.showGrey = not db.showGrey
    self.Offers:Invalidate()
    self:Print("Grey quests %s.", db.showGrey and "suggested" or "not suggested")
    self:Emit("QUESTS_CHANGED")
  elseif cmd == "above" then
    local n = tonumber(rest)
    if n then db.maxAbove = math.max(0, math.min(10, math.floor(n))) end
    self.Offers:Invalidate()
    self:Print("Suggesting quests up to %d levels above you.", db.maxAbove)
    self:Emit("QUESTS_CHANGED")
  elseif cmd == "classic" then
    db.classicOffers = rest ~= "off"
    self.Offers:Invalidate()
    self:Print("Classic quest data %s.", db.classicOffers and "on" or "off: only what the game, you and players in Forever have seen")
    self:Emit("QUESTS_CHANGED")
  elseif cmd == "unignore" then
    wipe(self.char.ignored)
    self.Offers:Invalidate()
    self:Print("Dismissed quests will be suggested again.")
    self:Emit("QUESTS_CHANGED")
  elseif cmd == "data" then
    local O = self.Offers
    local nq, nn, placed, lg, le = 0, 0, 0, 0, 0
    for _ in pairs(ns.QuestData and ns.QuestData.q or {}) do nq = nq + 1 end
    for _ in pairs(ns.QuestData and ns.QuestData.n or {}) do nn = nn + 1 end
    for _ in pairs(O.npcPos) do placed = placed + 1 end
    for _ in pairs(db.learned.g) do lg = lg + 1 end
    for _ in pairs(db.learned.e) do le = le + 1 end
    self:Print("Quest data: %d quests, %d NPCs (%d placed on maps%s).", nq, nn, placed, O.ready and "" or ", still placing")
    if ns.ForeverData then
      local fq, seen = 0, 0
      for _, f in pairs(ns.ForeverData.q) do
        fq = fq + 1
        if (f[9] or 0) > 0 or (f[10] or 0) > 0 then seen = seen + 1 end
      end
      self:Print("Forever data: %d quests, %d seen in WoW Forever, the rest Classic data (build %s, made %s).", fq, seen, ns.ForeverData.build, ns.ForeverData.made)
      self:Print(ns.ForeverData.credit)
    else
      self:Print("No Forever data file. The add-on's read-me says how to make one.")
    end
    self:Print("Learned in game: %d quest givers, %d hand-ins.", lg, le)
    O:ReadLog()
    local ids
    if O.idsMatch == nil then
      ids = "not checked yet (needs a Classic quest in your log)"
    elseif O.idsMatch then
      ids = "match the Classic data (quests new in Forever have their own)"
    elseif O.idOffset then
      ids = ("are Classic's %+d, so they're translated"):format(O.idOffset)
    else
      ids = "differ from the Classic data, so quests are matched by name"
    end
    self:Print("Quest ids %s.", ids)
    local named = 0
    for _ in pairs(O.completedTitles) do named = named + 1 end
    self:Print("Finished quests read from the game: %d%s.", named,
      O.scanning and " (still reading)" or (O.completedCount and (" of " .. O.completedCount) or " (not available)"))
    -- A few log quests, so a mismatch can be checked.
    local shown = 0
    for _, q in ipairs(self.Quests.list) do
      if shown < 6 then
        shown = shown + 1
        local info = q.dbid and O:Info(q.dbid)
        self:Print("  %d %s -> %s", q.id, q.title, info and (info.id .. " " .. info.title) or "not in Classic data")
      end
    end
  elseif cmd == "next" then
    N:FocusNearest()
  elseif cmd == "clear" then
    N:Clear(true)
  elseif cmd == "zone" then
    db.zoneOnly = not db.zoneOnly
    self:Print(db.zoneOnly and "Showing this zone's quests only." or "Showing all quests.")
    self:Emit("QUESTS_CHANGED")
  elseif cmd == "blizzard" then
    db.hideBlizzard = rest == "off"
    T:ApplyBlizzard()
    self:Print("Blizzard's quest tracker %s.", db.hideBlizzard and "hidden" or "shown")
  elseif cmd == "unhide" then
    wipe(self.char.hidden)
    self:Emit("QUESTS_CHANGED")
    self:Print("All quests are shown again.")
  elseif cmd == "reset" then
    db.left, db.top, db.scale, db.width, db.height = nil, nil, 1, QP.defaults.width, QP.defaults.height
    T:ApplyLayout()
  else
    self:Print("Commands:\n" .. table.concat(HELP, "\n"))
  end
end

SLASH_QUESTDIRECT1 = "/qd"
SLASH_QUESTDIRECT2 = "/questdirect"
SLASH_QUESTDIRECT3 = "/qp" -- the old name still works
SlashCmdList.QUESTDIRECT = function(msg) QP:Slash(msg) end

-- Key Bindings menu (Bindings.xml)
BINDING_HEADER_QUESTDIRECT = "QuestDirect"
BINDING_NAME_QUESTDIRECT_TOGGLE = "Show or hide the tracker"
BINDING_NAME_QUESTDIRECT_NEXT = "Focus the best next quest"
BINDING_NAME_QUESTDIRECT_CLEAR = "Stop navigating"
BINDING_NAME_QUESTDIRECT_ROUTE = "Plan this zone, or stop the plan"
_G["BINDING_NAME_CLICK QuestDirectItem1:LeftButton"] = "Use the first quest item (nearest quest)"
