-- kUI · Rares
-- A rare scanner in QuestDirect's style. Spots rare and rare-elite NPCs:
--   * map markers for rares (vignettes), when the game shows them
--   * nameplates as they come into view
--   * your target and whatever you mouse over
-- then shows an alert with the NPC's model, level and distance. The alert
-- also has buttons to target it, put a waypoint on it, or ignore it. Optionally
-- it plays a sound, flashes the game icon and marks the rare with a skull.
-- The world map shows where the Classic rares spawn, and /kui rares lists the
-- ones in your zone, with when you last saw and killed each one.

local _, ns = ...
local FUI, S = ns.FUI, ns.Style

local R = { key = "rares", name = "Rare scanner", spots = {}, recent = {} }
ns.Rares = R

local floor, max, min, sqrt, abs = math.floor, math.max, math.min, math.sqrt, math.abs
local CONTINENT = (Enum and Enum.UIMapType and Enum.UIMapType.Continent) or 2
local ZONE = (Enum and Enum.UIMapType and Enum.UIMapType.Zone) or 3
local W, H = 300, 96
local RARE_COLOR = { 0.85, 0.85, 1 }      -- silver-blue, like rare portraits
local ELITE_COLOR = { 1, 0.82, 0.3 }      -- gold for rare elites

local function Secret(v) return issecretvalue and issecretvalue(v) end
local function Safe(fn, ...)
  if not fn then return nil end
  local ok, a, b, c = pcall(fn, ...)
  if ok then return a, b, c end
end
local function XY(v)
  if not v then return nil end
  if v.GetXY then return v:GetXY() end
  return v.x, v.y
end

local function NpcID(guid)
  if not guid or Secret(guid) then return nil end
  local kind, _, _, _, _, id = strsplit("-", guid)
  if kind == "Creature" or kind == "Vehicle" then return tonumber(id) end
end

local function Data(id)
  local r = ns.RareData and ns.RareData[id]
  if r then return { name = r[1], min = r[2], max = r[3], elite = r[4], cont = r[5], pts = r[6] } end
end

------------------------------------------------------------------------
-- Where the Classic rares spawn, placed on zone maps by the game
------------------------------------------------------------------------

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

local function Continents()
  local found = {}
  local function try(uiMap)
    local info = uiMap and C_Map.GetMapInfo(uiMap)
    if not info or info.mapType ~= CONTINENT then return end
    local instance = Safe(C_Map.GetWorldPosFromMapPos, uiMap, CreateVector2D(0.5, 0.5))
    if instance and found[instance] == nil then found[instance] = uiMap end
  end
  local m = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
  for _ = 1, 6 do
    local info = m and not Secret(m) and C_Map.GetMapInfo(m)
    if not info then break end
    if info.mapType == CONTINENT then try(m) break end
    m = info.parentMapID
  end
  for _, id in ipairs({ 1415, 1414, 13, 12 }) do try(id) end
  return found
end

local function Points(s)
  local t = {}
  for x, y in (s or ""):gmatch("(%-?[%d%.]+),(%-?[%d%.]+)") do t[#t + 1] = { tonumber(x), tonumber(y) } end
  return t
end

function R:PlaceAll()
  if not (ns.RareData and C_Map and C_Map.GetMapPosFromWorldPos and CreateVector2D) then return end
  local cont = Continents()
  -- axis order: whichever places more sample points
  local hits = { [false] = 0, [true] = 0 }
  local n = 0
  for _, r in pairs(ns.RareData) do
    local c, p = cont[r[5]], Points(r[6])[1]
    if c and p then
      for _, swap in ipairs({ false, true }) do if Place(r[5], c, p[1], p[2], swap) then hits[swap] = hits[swap] + 1 end end
      n = n + 1
      if n >= 60 then break end
    end
  end
  local swap = hits[true] > hits[false]
  local spots, byMap = {}, {}
  for id, r in pairs(ns.RareData) do
    local c = cont[r[5]]
    if c then
      for _, p in ipairs(Points(r[6])) do
        local m, x, y = Place(r[5], c, p[1], p[2], swap)
        if m then
          spots[id] = spots[id] or {}
          table.insert(spots[id], { m = m, x = x, y = y })
          byMap[m] = byMap[m] or {}
          byMap[m][id] = true
        end
      end
    end
  end
  self.spots, self.byMap = spots, byMap
  self.cont, self.swap = cont, swap
  if ns.Treasures then ns.Treasures:PlaceAll(cont, swap) end
  self:DrawPins()
end

------------------------------------------------------------------------
-- Positions and distances
------------------------------------------------------------------------

local function PlayerPos()
  local m = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
  if not m or Secret(m) then return nil end
  local pos = Safe(C_Map.GetPlayerMapPosition, m, "player")
  if not pos or Secret(pos) then return nil end
  local x, y = XY(pos)
  if not x or Secret(x) or (x == 0 and y == 0) then return nil end
  return m, x, y
end

local sizes = {}
local function Yards(m, x1, y1, x2, y2)
  local s = sizes[m]
  if not s then
    local _, a = Safe(C_Map.GetWorldPosFromMapPos, m, CreateVector2D(0, 0))
    local _, b = Safe(C_Map.GetWorldPosFromMapPos, m, CreateVector2D(1, 1))
    local ax, ay = XY(a)
    local bx, by = XY(b)
    s = (ax and bx) and { abs(by - ay), abs(bx - ax) } or { 1000, 667 }
    if s[1] < 1 or s[2] < 1 then s = { 1000, 667 } end
    sizes[m] = s
  end
  local dx, dy = (x1 - x2) * s[1], (y1 - y2) * s[2]
  return sqrt(dx * dx + dy * dy)
end

local function ZoneName(m)
  local info = m and C_Map.GetMapInfo(m)
  return info and info.name or ""
end

local function Ago(t)
  if not t then return "never" end
  local d = time() - t
  if d < 60 then return "just now" end
  if d < 3600 then return floor(d / 60) .. " min ago" end
  if d < 86400 then return floor(d / 3600) .. " h ago" end
  return floor(d / 86400) .. " days ago"
end
R.Ago = Ago
R.Place, R.Points, R.PlayerPos, R.Yards, R.ZoneName = Place, Points, PlayerPos, Yards, ZoneName
R.NpcID = NpcID

------------------------------------------------------------------------
-- The alert
------------------------------------------------------------------------

function R:BuildToast()
  if self.toast then return end
  local db = ns.db
  local f = CreateFrame("Frame", "KUIRareAlert", UIParent)
  f:SetSize(W, H)
  f:SetFrameStrata("HIGH")
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function() f:StartMoving() end)
  f:SetScript("OnDragStop", function()
    f:StopMovingOrSizing()
    db.rareLeft, db.rareTop = floor(f:GetLeft() + 0.5), floor(f:GetTop() + 0.5)
  end)
  f:Hide()
  S.Panel(f)
  S.Header(f, 22)
  f.accent = S.Tex(f, "ARTWORK", 1)
  f.accent:SetPoint("TOPLEFT", 1, -1)
  f.accent:SetPoint("BOTTOMLEFT", 1, 1)
  f.accent:SetWidth(3)

  f.kind = S.Text(f, nil, "LEFT", nil, 12)
  f.kind:SetPoint("TOPLEFT", 10, -5)
  f.kind:SetTextColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3])
  f.ago = S.Text(f, nil, "RIGHT", nil, 11)
  f.ago:SetPoint("TOPRIGHT", -26, -6)
  f.ago:SetTextColor(0.6, 0.6, 0.6)
  f.close = S.Button(f, "x", 20, function() R:Dismiss() end)
  f.close:SetPoint("TOPRIGHT", -2, -2)

  local model = CreateFrame("PlayerModel", nil, f)
  model:SetSize(62, 62)
  model:SetPoint("BOTTOMLEFT", 8, 8)
  local mbg = S.Tex(f, "BACKGROUND", -6)
  mbg:SetAllPoints(model)
  mbg:SetColorTexture(1, 1, 1, 0.04)
  f.modelEdges = S.Edges(f, "ARTWORK", 2, model)
  f.model = model

  f.name = S.Text(f, nil, "LEFT", nil, 16)
  f.name:SetPoint("TOPLEFT", model, "TOPRIGHT", 10, 0)
  f.name:SetPoint("RIGHT", -8, 0)
  f.info = S.Text(f, nil, "LEFT", nil, 12)
  f.info:SetPoint("TOPLEFT", f.name, "BOTTOMLEFT", 0, -3)
  f.info:SetPoint("RIGHT", -8, 0)
  f.info:SetTextColor(0.8, 0.8, 0.8)

  f.way = S.Button(f, "Waypoint", 70, function() R:Waypoint(R.current) end, "Put a waypoint on it")
  f.ignore = S.Button(f, "Ignore", 56, function() R:Ignore(R.current) end, "Don't alert for this rare again (/kui rares to undo)")
  f.ignore:SetPoint("BOTTOMRIGHT", -8, 8)
  f.way:SetPoint("RIGHT", f.ignore, "LEFT", -4, 0)
  -- Spot for the target button (a separate secure button sits on top of it).
  f.targetSpot = S.Button(f, "Target", 60, nil, nil)
  f.targetSpot:SetPoint("RIGHT", f.way, "LEFT", -4, 0)
  f.targetSpot:EnableMouse(false)
  S.Panel(f.targetSpot, 0.6)

  local elapsed = 0
  f:SetScript("OnUpdate", function(_, dt)
    elapsed = elapsed + dt
    if elapsed < 0.5 then return end
    elapsed = 0
    R:UpdateInfo()
    if R.current and R.current.until_ and GetTime() > R.current.until_ then R:Dismiss() end
  end)
  f:SetScript("OnHide", function() R:SyncTarget() end)
  f:SetScript("OnShow", function() R:SyncTarget() end)
  self.toast = f

  -- Targeting needs a secure button; it can only be set up out of combat.
  local t = CreateFrame("Button", "KUIRareTarget", UIParent, "SecureActionButtonTemplate")
  t:SetFrameStrata("DIALOG")
  t:RegisterForClicks("AnyUp", "AnyDown")
  t:SetAttribute("type", "macro")
  t:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Target it", 1, 1, 1)
    GameTooltip:AddLine("Works once it's in range", 0.7, 0.7, 0.7)
    GameTooltip:Show()
  end)
  t:SetScript("OnLeave", function() GameTooltip:Hide() end)
  S.Highlight(t, 0.15)
  t:Hide()
  self.targetBtn = t
  self:PlaceToast()
end

function R:PlaceToast()
  local f, db = self.toast, ns.db
  f:ClearAllPoints()
  if db.rareLeft then f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", db.rareLeft, db.rareTop)
  else f:SetPoint("TOP", UIParent, "TOP", 0, -140) end
end

-- Keep the secure target button over its spot; only possible out of combat.
function R:SyncTarget()
  local t, f = self.targetBtn, self.toast
  if not t then return end
  local want = f:IsShown() and self.current and not self.current.treasure and self.current.name
  if InCombatLockdown() then
    self.syncPending = true
    t:SetAlpha(want and 1 or 0)
    f.targetSpot.text:SetText(want and (t.forName == self.current.name and "Target" or "After combat") or "Target")
    return
  end
  self.syncPending = false
  if want then
    t:SetAttribute("macrotext", "/cleartarget\n/target " .. self.current.name)
    t.forName = self.current.name
    t:ClearAllPoints()
    t:SetAllPoints(f.targetSpot)
    t:SetAlpha(1)
    t:Show()
    f.targetSpot.text:SetText("Target")
  else
    t:Hide()
  end
end

function R:UpdateInfo()
  local c, f = self.current, self.toast
  if not c or not f then return end
  local bits = {}
  if c.treasure then
    bits[#bits + 1] = c.kindName or "Treasure"
    if c.looted and c.looted > 0 then bits[#bits + 1] = "looted " .. c.looted .. (c.looted == 1 and " time" or " times") end
  else
    local lvl = c.level or (c.min and (c.min == c.max and c.min or (c.min .. "-" .. c.max)))
    if lvl then bits[#bits + 1] = "Level " .. lvl end
    bits[#bits + 1] = c.elite and "Rare Elite" or "Rare"
  end
  local where
  local pm, px, py = PlayerPos()
  if c.m and c.x then
    where = ("%s %.1f, %.1f"):format(ZoneName(c.m), c.x * 100, c.y * 100)
    if pm == c.m then where = where .. ("  ·  %d yd"):format(floor(Yards(pm, c.x, c.y, px, py) + 0.5)) end
  end
  f.info:SetText(table.concat(bits, " · ") .. (where and ("\n" .. where) or ""))
  f.info:SetWordWrap(true)
  local killed = not c.treasure and ns.db.rareKilled[c.id]
  f.ago:SetText(killed and ("killed " .. Ago(killed)) or (c.lastLooted and ("looted " .. Ago(c.lastLooted)) or ""))
  if c.dead then f.kind:SetText("RARE  ·  dead") end
end

function R:Show(c)
  self:BuildToast()
  local f = self.toast
  self.current = c
  local col = c.color or (c.elite and ELITE_COLOR or RARE_COLOR)
  f.name:SetText(c.name)
  f.name:SetTextColor(col[1], col[2], col[3])
  f.accent:SetColorTexture(col[1], col[2], col[3], 1)
  S.ColorEdges(f.modelEdges, col[1], col[2], col[3], 0.8)
  f.kind:SetText(c.kindText or (c.source == "vignette" and "RARE  ·  on your map" or "RARE  ·  nearby"))
  local model = f.model
  pcall(model.ClearModel, model)
  local ok = false
  f.targetSpot:SetShown(not c.treasure)
  f.icon = f.icon or S.Tex(f, "ARTWORK", 3)
  f.icon:SetAllPoints(model)
  f.icon:SetShown(c.treasure and c.icon and true or false)
  if c.treasure and c.icon then f.icon:SetTexture(c.icon) end
  if c.treasure then c.unit = nil end
  if c.unit and model.SetUnit then ok = pcall(model.SetUnit, model, c.unit) end
  if not ok and not c.treasure and c.id and model.SetCreature then ok = pcall(model.SetCreature, model, c.id) end
  if model.SetPortraitZoom then pcall(model.SetPortraitZoom, model, 0.6) end
  model:SetShown(ok)
  c.until_ = GetTime() + (ns.db.rareToastTime or 120)
  self:UpdateInfo()
  f:Show()
  self:SyncTarget()
end

function R:Dismiss()
  if self.toast then self.toast:Hide() end
  self.current = nil
  self:SyncTarget()
end

function R:Waypoint(c)
  if not (c and c.m and c.x) then
    -- no live position: the nearest known spawn
    local pm, px, py = PlayerPos()
    local best, bd
    for _, s in ipairs(c and self.spots[c.id] or {}) do
      local d = (pm == s.m) and Yards(pm, s.x, s.y, px, py) or 1e9
      if not bd or d < bd then best, bd = s, d end
    end
    if not best then FUI:Print("No position known for %s.", c and c.name or "it") return end
    c = { name = c.name, m = best.m, x = best.x, y = best.y }
  end
  if TomTom and TomTom.AddWaypoint then
    if self.uid and TomTom.RemoveWaypoint then pcall(TomTom.RemoveWaypoint, TomTom, self.uid) end
    local ok, uid = pcall(TomTom.AddWaypoint, TomTom, c.m, c.x, c.y, { title = c.name, from = "kUI", persistent = false, crazy = true })
    if ok then self.uid = uid end
  elseif C_Map.SetUserWaypoint and UiMapPoint then
    pcall(C_Map.SetUserWaypoint, UiMapPoint.CreateFromCoordinates(c.m, c.x, c.y))
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true) end
  end
  FUI:Print("Waypoint: %s, %s %.1f, %.1f", c.name, ZoneName(c.m), c.x * 100, c.y * 100)
end

function R:Ignore(c)
  if not c then return end
  ns.db.rareIgnored[c.key or c.id or c.name] = c.name
  FUI:Print("Won't alert for %s again. /kui rares to undo.", c.name)
  self:Dismiss()
  self:DrawPins()
end

------------------------------------------------------------------------
-- Spotting
------------------------------------------------------------------------

local RARE_CLASS = { rare = true, rareelite = true }

-- c = { id, name, level, elite, m, x, y, unit, source, dead }
function R:Spotted(c)
  local db = ns.db
  if not c.name or Secret(c.name) then return end
  local key = c.id or c.name
  if db.rareIgnored[key] then return end
  local d = c.id and Data(c.id)
  if d then
    c.min, c.max = d.min, d.max
    if c.elite == nil then c.elite = d.elite end
  end
  if not c.m then
    local m, x, y = PlayerPos()
    if c.unit and m then c.m, c.x, c.y, c.near = m, x, y, true end -- it's within sight of you
  end
  if c.m then
    db.rareSeen[key] = { t = time(), m = c.m, x = floor((c.x or 0) * 10000) / 10000, y = floor((c.y or 0) * 10000) / 10000, name = c.name }
  end
  if c.dead then
    if self.current and (self.current.id or self.current.name) == key then
      self.current.dead = true
      self:UpdateInfo()
    end
    return
  end
  local now = GetTime()
  local last = self.recent[key]
  if last and now - last < (db.rareCooldown or 300) then
    if self.current and (self.current.id or self.current.name) == key and c.unit and not self.current.unit then
      self.current.unit = c.unit
    end
    return
  end
  self.recent[key] = now
  self:Show(c)
  if db.rareSound then
    if PlaySound and SOUNDKIT and SOUNDKIT.RAID_WARNING then PlaySound(SOUNDKIT.RAID_WARNING, "Master") end
  end
  if db.rareFlash and FlashClientIcon then FlashClientIcon() end
  local where = c.m and (" at %s %.1f, %.1f"):format(ZoneName(c.m), (c.x or 0) * 100, (c.y or 0) * 100) or ""
  FUI:Print("|cffd9d9ffRare|r: %s%s%s", c.name, c.elite and " (elite)" or "", where)
end

function R:CheckUnit(unit, source)
  if not UnitExists(unit) or UnitIsPlayer(unit) then return end
  local class = UnitClassification(unit)
  if Secret(class) then return end
  local id = NpcID(UnitGUID(unit))
  local known = id and ns.RareData and ns.RareData[id]
  if not (RARE_CLASS[class] or known) then return end
  local dead = UnitIsDead(unit)
  local key = id or UnitName(unit)
  if dead and key then
    local db = ns.db
    if not db.rareKilled[key] or time() - db.rareKilled[key] > 60 then db.rareKilled[key] = time() end
  end
  local level = UnitLevel(unit)
  if Secret(level) or (level and level < 0) then level = nil end
  self:Spotted({ id = id, name = UnitName(unit), level = level, elite = class == "rareelite" or nil,
                 unit = unit, source = source, dead = dead })
  -- Skull it once you target it.
  if unit == "target" and ns.db.rareMark and not dead and GetRaidTargetIndex and not GetRaidTargetIndex("target")
     and (not IsInGroup() or UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
    pcall(SetRaidTarget, "target", 8)
  end
end

-- Map markers: the game's rare markers carry the NPC and its position.
function R:CheckVignettes()
  local V = C_VignetteInfo
  if not (V and V.GetVignettes) then return end
  local m = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
  if not m or Secret(m) then return end
  for _, guid in ipairs(Safe(V.GetVignettes) or {}) do
    local info = Safe(V.GetVignetteInfo, guid)
    if info and not info.isDead then
      local atlas = info.atlasName or ""
      local id = NpcID(info.objectGUID)
      local isRare = atlas:find("VignetteKill") or (id and ns.RareData and ns.RareData[id])
      local isTreasure = atlas:find("VignetteLoot")
      if isRare then
        local pos = Safe(V.GetVignettePosition, guid, m)
        local x, y = XY(pos)
        self:Spotted({ id = id, name = info.name, elite = atlas:find("Elite") and true or nil,
                       m = x and m or nil, x = x, y = y, source = "vignette" })
      elseif isTreasure and ns.Treasures then
        local pos = Safe(V.GetVignettePosition, guid, m)
        local x, y = XY(pos)
        if x then ns.Treasures:FromVignette(info, guid, m, x, y) end
      end
    end
  end
end

------------------------------------------------------------------------
-- World map pins: where the Classic rares spawn
------------------------------------------------------------------------

function R:SetupMap()
  if self.wm or not (WorldMapFrame and WorldMapFrame.GetCanvas) then return end
  local canvas = WorldMapFrame:GetCanvas()
  local f = CreateFrame("Frame", nil, canvas)
  f:SetAllPoints(canvas)
  f:SetFrameLevel(canvas:GetFrameLevel() + 60)
  self.wm = { frame = f, pins = {}, used = 0 }
  local function redraw() R:DrawPins() end
  hooksecurefunc(WorldMapFrame, "OnMapChanged", redraw)
  WorldMapFrame:HookScript("OnShow", redraw)
  canvas:HookScript("OnSizeChanged", redraw)
  if WorldMapFrame.ScrollContainer then
    WorldMapFrame.ScrollContainer:HookScript("OnMouseWheel", function() C_Timer.After(0.25, redraw) end)
  end
end

local function PinEnter(pin)
  if pin.kind ~= "rare" and ns.Treasures then return ns.Treasures:PinTooltip(pin) end
  local id = pin.id
  local d = Data(id)
  if not d then return end
  GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
  local col = d.elite and ELITE_COLOR or RARE_COLOR
  GameTooltip:SetText(d.name, col[1], col[2], col[3])
  GameTooltip:AddLine(("Level %s · %s"):format(d.min == d.max and d.min or (d.min .. "-" .. d.max), d.elite and "Rare Elite" or "Rare"), 0.8, 0.8, 0.8)
  local seen, killed = ns.db.rareSeen[id], ns.db.rareKilled[id]
  GameTooltip:AddLine("Last seen: " .. Ago(seen and seen.t), 1, 1, 1)
  if killed then GameTooltip:AddLine("Killed: " .. Ago(killed), 1, 1, 1) end
  GameTooltip:AddLine("One of its spawn points (Classic data)", 0.5, 0.5, 0.5)
  GameTooltip:AddLine("Click: waypoint here", 0.6, 0.75, 1)
  GameTooltip:Show()
end

function R:Pin(i)
  local wm = self.wm
  local p = wm.pins[i]
  if p then return p end
  p = CreateFrame("Button", nil, wm.frame)
  p.ring = S.Tex(p, "ARTWORK", 1)
  p.ring:SetAllPoints()
  p.ring:SetColorTexture(0.04, 0.05, 0.07, 0.9)
  p.dot = S.Tex(p, "ARTWORK", 2)
  p.dot:SetPoint("TOPLEFT", 2, -2)
  p.dot:SetPoint("BOTTOMRIGHT", -2, 2)
  p.edges = S.Edges(p, "OVERLAY", 1)
  p:SetScript("OnEnter", PinEnter)
  p:SetScript("OnLeave", function() GameTooltip:Hide() end)
  p:SetScript("OnClick", function(self)
    if self.kind ~= "rare" then
      return R:Waypoint({ name = self.name or "Treasure", m = self.m, x = self.x, y = self.y })
    end
    local d = Data(self.id)
    R:Waypoint({ id = self.id, name = d and d.name or "Rare", m = self.m, x = self.x, y = self.y })
  end)
  wm.pins[i] = p
  return p
end

function R:DrawPins()
  local wm = self.wm
  if not wm then return end
  local used = 0
  if ns.db.rarePins and WorldMapFrame:IsShown() and self.byMap then
    local mapID = WorldMapFrame:GetMapID()
    local f = wm.frame
    local Wd, Ht = f:GetWidth(), f:GetHeight()
    local scale = 1 / max(f:GetEffectiveScale() / UIParent:GetEffectiveScale(), 0.05)
    for id in pairs(self.byMap[mapID] or {}) do
      if not ns.db.rareIgnored[id] then
        local d = Data(id)
        local col = d and d.elite and ELITE_COLOR or RARE_COLOR
        local killed = ns.db.rareKilled[id] and time() - ns.db.rareKilled[id] < 3600
        for _, s in ipairs(self.spots[id] or {}) do
          if s.m == mapID then
            used = used + 1
            local p = self:Pin(used)
            p.kind, p.id, p.m, p.x, p.y = "rare", id, s.m, s.x, s.y
            local size = 12 * scale
            p:SetSize(size, size)
            p:ClearAllPoints()
            p:SetPoint("CENTER", f, "TOPLEFT", s.x * Wd, -s.y * Ht)
            p.dot:SetColorTexture(col[1], col[2], col[3], killed and 0.35 or 1)
            S.ColorEdges(p.edges, col[1], col[2], col[3], 0.9)
            p:Show()
          end
        end
      end
    end
  end
  if ns.Treasures and WorldMapFrame:IsShown() then
    local f = wm.frame
    local scale = 1 / max(f:GetEffectiveScale() / UIParent:GetEffectiveScale(), 0.05)
    used = ns.Treasures:Pins(self, used, WorldMapFrame:GetMapID(), f, f:GetWidth(), f:GetHeight(), scale)
  end
  for i = used + 1, #wm.pins do wm.pins[i]:Hide() end
  wm.used = used
end

------------------------------------------------------------------------
-- The list: rares in your zone
------------------------------------------------------------------------

function R:BuildList()
  if self.list then return end
  local f = CreateFrame("Frame", "KUIRareList", UIParent)
  f:SetSize(320, 100)
  f:SetFrameStrata("HIGH")
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function() f:StartMoving() end)
  f:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)
  f:SetPoint("CENTER", 0, 80)
  f:Hide()
  S.Panel(f)
  S.Header(f, S.HEADER_H)
  f.title = S.Text(f, nil, "LEFT", nil, 14)
  f.title:SetPoint("TOPLEFT", 8, -6)
  f.title:SetTextColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3])
  local x = S.Button(f, "x", 20, function() f:Hide() end)
  x:SetPoint("TOPRIGHT", -2, -3)
  f.tTab = S.Button(f, "Treasures", 64, function() R.listMode = "treasures"; R:FillList() end)
  f.tTab:SetPoint("RIGHT", x, "LEFT", -4, 0)
  f.rTab = S.Button(f, "Rares", 44, function() R.listMode = "rares"; R:FillList() end)
  f.rTab:SetPoint("RIGHT", f.tTab, "LEFT", -2, 0)
  f.rows = {}
  table.insert(UISpecialFrames, "KUIRareList")
  self.list = f
end

function R:FillList()
  local f = self.list
  local m, px, py = PlayerPos()
  local db = ns.db
  local treasures = self.listMode == "treasures"
  f.rTab.text:SetTextColor(treasures and 1 or S.ACCENT[1], treasures and 1 or S.ACCENT[2], 1)
  f.tTab.text:SetTextColor(treasures and S.ACCENT[1] or 1, treasures and S.ACCENT[2] or 1, 1)
  if treasures and ns.Treasures then return ns.Treasures:FillList(f, m, px, py) end
  local items = {}
  for id in pairs(m and self.byMap and self.byMap[m] or {}) do
    local d = Data(id)
    local best
    for _, s in ipairs(self.spots[id] or {}) do
      if s.m == m then
        local dist = Yards(m, s.x, s.y, px, py)
        if not best or dist < best then best = dist end
      end
    end
    items[#items + 1] = { id = id, name = d.name, d = d, dist = best }
  end
  for key, s in pairs(db.rareSeen) do
    if s.m == m and not (type(key) == "number" and self.byMap and self.byMap[m] and self.byMap[m][key]) then
      items[#items + 1] = { id = key, name = s.name, seenOnly = true, dist = Yards(m, s.x, s.y, px, py) }
    end
  end
  table.sort(items, function(a, b) return (a.dist or 1e9) < (b.dist or 1e9) end)
  for _, it in ipairs(items) do
    it.color = it.d and it.d.elite and ELITE_COLOR or RARE_COLOR
    it.label = it.name .. (db.rareIgnored[it.id] and "  |cff808080(ignored)|r" or "")
    local seen, killed = db.rareSeen[it.id], db.rareKilled[it.id]
    local lvl = it.d and (it.d.min == it.d.max and it.d.min or (it.d.min .. "-" .. it.d.max)) or "?"
    it.sub = ("Level %s%s · seen %s%s"):format(lvl, it.d and it.d.elite and " elite" or "", Ago(seen and seen.t),
      killed and (" · killed " .. Ago(killed)) or "")
  end
  self:RenderList(f, ("Rares in %s  |cff808080%d|r"):format(ZoneName(m), #items), items, "No rares known here yet.")
end

-- items: { label, color, sub, dist, ... } (the whole item is passed back on click)
function R:RenderList(f, title, items, emptyText)
  f.title:SetText(title)
  local y = S.HEADER_H + 4
  for i, it in ipairs(items) do
    local r = f.rows[i]
    if not r then
      r = CreateFrame("Button", nil, f)
      r:SetHeight(34)
      S.Highlight(r, 0.07)
      r.name = S.Text(r, nil, "LEFT", nil, 13)
      r.name:SetPoint("TOPLEFT", 10, -3)
      r.dist = S.Text(r, nil, "RIGHT", nil, 12)
      r.dist:SetPoint("TOPRIGHT", -8, -4)
      r.sub = S.Text(r, nil, "LEFT", nil, 11)
      r.sub:SetPoint("TOPLEFT", 10, -18)
      r.sub:SetPoint("RIGHT", -8, 0)
      r.sub:SetTextColor(0.65, 0.65, 0.65)
      r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
      r:SetScript("OnClick", function(self, button)
        local e = self.entry
        if e.treasure then return ns.Treasures:ListClick(e, button) end
        if button == "RightButton" then
          if ns.db.rareIgnored[e.id] then ns.db.rareIgnored[e.id] = nil else ns.db.rareIgnored[e.id] = e.name end
          R:FillList()
          R:DrawPins()
        else
          local s = ns.db.rareSeen[e.id]
          if e.seenOnly and s then R:Waypoint({ name = e.name, m = s.m, x = s.x, y = s.y })
          else R:Waypoint({ id = e.id, name = e.name }) end
        end
      end)
      f.rows[i] = r
    end
    r.entry = it
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", 1, -y)
    r:SetPoint("TOPRIGHT", -1, -y)
    r.name:SetText(it.label)
    r.name:SetTextColor(it.color[1], it.color[2], it.color[3])
    r.dist:SetText(it.dist and (it.dist < 1000 and (floor(it.dist) .. " yd") or ("%.1fk yd"):format(it.dist / 1000)) or "")
    r.sub:SetText(it.sub or "")
    r:Show()
    y = y + 34
  end
  for i = #items + 1, #f.rows do f.rows[i]:Hide() end
  if #items == 0 then
    f.rows.empty = f.rows.empty or S.Text(f, nil, "LEFT", nil, 12)
    f.rows.empty:SetPoint("TOPLEFT", 10, -(S.HEADER_H + 8))
    f.rows.empty:SetText(emptyText)
    f.rows.empty:Show()
    y = y + 24
  elseif f.rows.empty then
    f.rows.empty:Hide()
  end
  f.hint = f.hint or S.Text(f, nil, "LEFT", nil, 11)
  f.hint:SetPoint("BOTTOMLEFT", 10, 7)
  f.hint:SetText("Click: waypoint · Right-click: ignore / unignore")
  f.hint:SetTextColor(0.5, 0.6, 0.75)
  f:SetHeight(y + 26)
end

function R:ToggleList()
  self:BuildList()
  if self.list:IsShown() then self.list:Hide() else self:FillList(); self.list:Show() end
end

------------------------------------------------------------------------
-- Start-up and events
------------------------------------------------------------------------

function R:Refresh()
  if self.toast then S.Panel(self.toast) end
  if self.list then S.Panel(self.list) if self.list:IsShown() then self:FillList() end end
  self:DrawPins()
end

function R:Test()
  local id, d = 5808, Data(5808)
  local m, x, y = PlayerPos()
  self.recent[id] = nil
  self:Show({ id = id, name = d and d.name or "Warlord Kolkanis", min = d and d.min, max = d and d.max, elite = true,
              m = m, x = x and min(1, x + 0.02), y = y, source = "vignette" })
end

function R:Enable()
  self.enabled = true
  local db = ns.db
  db.rareSeen = db.rareSeen or {}
  db.rareKilled = db.rareKilled or {}
  db.rareIgnored = db.rareIgnored or {}
  self:BuildToast()
  self:SetupMap()
  if ns.Treasures then ns.Treasures:Enable() end
  C_Timer.After(2, function() R:PlaceAll() end)

  local ev = CreateFrame("Frame")
  for _, e in ipairs({ "NAME_PLATE_UNIT_ADDED", "PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT",
                       "VIGNETTE_MINIMAP_UPDATED", "VIGNETTES_UPDATED", "PLAYER_REGEN_ENABLED",
                       "ZONE_CHANGED_NEW_AREA", "UNIT_HEALTH" }) do
    pcall(ev.RegisterEvent, ev, e)
  end
  ev:SetScript("OnEvent", function(_, event, unit)
    if event == "NAME_PLATE_UNIT_ADDED" then
      R:CheckUnit(unit, "nameplate")
    elseif event == "PLAYER_TARGET_CHANGED" then
      R:CheckUnit("target", "target")
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
      R:CheckUnit("mouseover", "mouseover")
    elseif event == "UNIT_HEALTH" then
      if unit == "target" and R.current and UnitIsDead("target") then R:CheckUnit("target", "target") end
    elseif event == "VIGNETTE_MINIMAP_UPDATED" or event == "VIGNETTES_UPDATED" then
      R:CheckVignettes()
    elseif event == "PLAYER_REGEN_ENABLED" then
      if R.syncPending then R:SyncTarget() end
    elseif event == "ZONE_CHANGED_NEW_AREA" then
      if R.list and R.list:IsShown() then R:FillList() end
    end
  end)
end

FUI:Register(R)

function R:Slash(arg)
  local db = ns.db
  if arg == "" then return self:ToggleList() end
  if arg == "test" then return self:Test() end
  local toggles = { sound = "rareSound", flash = "rareFlash", mark = "rareMark", pins = "rarePins", treasures = "rareTreasures",
                    chests = "chestPins", finds = "findPins", nearby = "findNearby", chestnearby = "chestNearby" }
  if toggles[arg] then
    db[toggles[arg]] = not db[toggles[arg]]
    FUI:Print("rares %s: %s", arg, db[toggles[arg]] and "on" or "off")
    self:DrawPins()
  elseif arg:match("^range %d+") then
    db.findRange = tonumber(arg:match("%d+"))
    FUI:Print("treasure alerts within %d yards.", db.findRange)
  elseif arg == "list treasures" or arg == "treasure" then
    self.listMode = "treasures"
    self:BuildList()
    self:FillList()
    self.list:Show()
  elseif arg == "unignore" then
    wipe(db.rareIgnored)
    FUI:Print("rares: alerting for every rare again.")
    self:DrawPins()
  else
    FUI:Print("/kui rares (list) · test · sound · flash · mark · pins · chests · finds · nearby · chestnearby · treasures · range 40 · unignore")
  end
end
