-- kUI · Treasures
-- Chests and other things lying around to loot, for the rare scanner:
--   * Classic chest spawns (Battered, Solid, Footlockers, Strongboxes...) and a
--     few classic finds (Giant Clams, Power Crystals, Un'Goro Dirt Piles) on the map
--   * anything you loot from the world (not herbs, ore, fishing or skinning) is
--     remembered with where it was: Forever's own new lootables, such as dinosaur
--     hatchlings, show up the first time you loot one
--   * the game's own treasure map markers, when it shows them
-- Walk near a spot where you've looted something before and you get an alert.

local _, ns = ...
local FUI, S = ns.FUI, ns.Style
local R = ns.Rares

local T = { spots = {}, byMap = {}, alerted = {} }
ns.Treasures = T

local floor, min, max = math.floor, math.min, math.max
local lower = string.lower
local SPOT_MERGE = 12   -- yards: the same object looted this close counts as one spot
local COLORS = {
  chest = { 0.95, 0.68, 0.3 },  -- warm gold-brown
  find = { 0.45, 0.95, 0.6 },   -- green
}
local ICONS = {
  chest = "Interface\\Icons\\INV_Box_01",
  find = "Interface\\Icons\\INV_Misc_Bag_10",
}
local GATHER = { "herb", "mining", "mine", "fishing", "skinning", "disenchant", "prospect", "salvag" }

local function Secret(v) return issecretvalue and issecretvalue(v) end

------------------------------------------------------------------------
-- Classic spawn points
------------------------------------------------------------------------

function T:PlaceAll(cont, swap)
  local spots, byMap = {}, {}
  for id, r in pairs(ns.TreasureData or {}) do
    for inst, pts in pairs(r[3]) do
      local c = cont[inst]
      if c then
        for _, p in ipairs(R.Points(pts)) do
          local m, x, y = R.Place(inst, c, p[1], p[2], swap)
          if m then
            spots[id] = spots[id] or {}
            table.insert(spots[id], { m = m, x = x, y = y })
            byMap[m] = byMap[m] or {}
            byMap[m][id] = true
          end
        end
      end
    end
  end
  self.spots, self.byMap = spots, byMap
end

------------------------------------------------------------------------
-- Learning what you loot
------------------------------------------------------------------------

-- db.finds[key] = { name, kind, n, spots = { { m, x, y, t } } }; key = object id or "v:name"
function T:Record(key, name, kind, m, x, y, looted)
  local db = ns.db
  local e = db.finds[key]
  if not e then
    e = { name = name, kind = kind, n = 0, spots = {} }
    db.finds[key] = e
  end
  if name and (not e.name or e.name:find("^Object ")) then e.name = name end
  e.kind = e.kind or kind
  local spot
  for _, s in ipairs(e.spots) do
    if s.m == m and R.Yards(m, s.x, s.y, x, y) <= SPOT_MERGE then spot = s break end
  end
  if not spot then
    spot = { m = m, x = floor(x * 10000 + 0.5) / 10000, y = floor(y * 10000 + 0.5) / 10000 }
    table.insert(e.spots, spot)
  end
  if looted then
    spot.t = time()
    e.n = (e.n or 0) + 1
    e.last = spot.t
  end
  R:DrawPins()
  return e, spot
end

-- Remember the name of the world object under the mouse (its tooltip has no unit).
function T:WatchTooltip()
  if not GameTooltip or self.tipHooked then return end
  self.tipHooked = true
  GameTooltip:HookScript("OnShow", function(tip)
    if tip.GetUnit and tip:GetUnit() then return end
    local owner = tip.GetOwner and tip:GetOwner()
    if owner and owner ~= UIParent and owner ~= WorldFrame then return end
    local line = _G.GameTooltipTextLeft1
    local text = line and line:GetText()
    if text and not Secret(text) and text ~= "" then T.lastName, T.lastNameAt = text, GetTime() end
  end)
end

function T:OnLoot()
  if not GetLootSourceInfo then return end
  local guid = GetLootSourceInfo(1)
  if not guid or Secret(guid) then return end
  local kind, _, _, _, _, id = strsplit("-", guid)
  if kind ~= "GameObject" then return end
  id = tonumber(id)
  if not id then return end
  -- gathering is GoldForever's business, not treasure
  local cast = self.lastCast
  if cast and GetTime() - cast.t < 3 then
    for _, w in ipairs(GATHER) do
      if cast.name:find(w, 1, true) then return end
    end
  end
  -- Quest objects (everything in them is for a quest) aren't treasure.
  local n, quest, firstItem = GetNumLootItems and GetNumLootItems() or 0, 0, nil
  for slot = 1, n do
    local _, itemName, _, _, _, _, isQuest = GetLootSlotInfo(slot)
    -- the loot window's quest flag, or the item filed as a quest item (class 12)
    if not isQuest and GetLootSlotLink then
      local link = GetLootSlotLink(slot)
      local instant = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
      local classID = link and instant and select(6, instant(link))
      isQuest = classID == 12
    end
    if isQuest then quest = quest + 1 end
    if not firstItem and itemName and not Secret(itemName) then firstItem = itemName end
  end
  if n > 0 and quest == n then return end
  local m, x, y = R.PlayerPos()
  if not m then return end
  local classic = ns.TreasureData and ns.TreasureData[id]
  local name = (self.lastName and GetTime() - (self.lastNameAt or 0) < 8 and self.lastName)
    or (classic and classic[1]) or (firstItem and ("Object with " .. firstItem)) or ("Object " .. id)
  local kind2 = classic and classic[2] or (lower(name):find("chest") or lower(name):find("footlocker")
    or lower(name):find("strongbox") or lower(name):find("coffer")) and "chest" or "find"
  self:Record(id, name, kind2, m, x, y, true)
  self.alerted[id] = GetTime()
end

-- The game's treasure markers: remember the spot and alert.
function T:FromVignette(info, guid, m, x, y)
  local kind, _, _, _, _, oid = strsplit("-", info.objectGUID or "")
  oid = kind == "GameObject" and tonumber(oid) or nil
  local key = oid or ("v:" .. (info.name or "?"))
  local name = info.name or "Treasure"
  local k = (lower(name):find("chest") or lower(name):find("strongbox")) and "chest" or "find"
  local e = self:Record(key, name, k, m, x, y, false)
  if ns.db.rareTreasures then self:Alert(key, e, { m = m, x = x, y = y }, "on your map") end
end

------------------------------------------------------------------------
-- Alerts near spots you've looted before
------------------------------------------------------------------------

function T:Alert(key, e, spot, how)
  local db = ns.db
  if db.rareIgnored["o" .. tostring(key)] then return end
  local last = self.alerted[key]
  if last and GetTime() - last < 600 then return end
  self.alerted[key] = GetTime()
  local kind = e.kind or "find"
  -- never cover up a rare
  if R.current and not R.current.treasure and R.toast and R.toast:IsShown() then
    FUI:Print("|cff73f299%s|r: %s", kind == "chest" and "Chest" or "Find", e.name or "?")
    return
  end
  R:Show({
    treasure = true, key = "o" .. tostring(key), id = "o" .. tostring(key), name = e.name or "Treasure",
    m = spot.m, x = spot.x, y = spot.y, color = COLORS[kind], icon = ICONS[kind],
    kindText = (kind == "chest" and "CHEST" or "FIND") .. "  ·  " .. (how or "nearby"),
    kindName = kind == "chest" and "Chest" or "Something to loot", looted = e.n, lastLooted = e.last,
  })
  if db.rareSound and PlaySound and SOUNDKIT then
    PlaySound(SOUNDKIT.UI_EPICLOOT_TOAST or SOUNDKIT.RAID_WARNING, "Master")
  end
  FUI:Print("|cff73f299%s|r nearby: %s", kind == "chest" and "Chest" or "Find", e.name or "?")
end

function T:CheckNearby()
  local db = ns.db
  if not db.findNearby then return end
  local m, px, py = R.PlayerPos()
  if not m then return end
  local range = db.findRange or 40
  for key, e in pairs(db.finds) do
    if (e.kind ~= "chest" or db.chestNearby) and not db.rareIgnored["o" .. tostring(key)] then
      for _, s in ipairs(e.spots) do
        if s.m == m then
          local d = R.Yards(m, s.x, s.y, px, py)
          local fresh = s.t and time() - s.t < (db.findRespawn or 900)
          if d <= range and d > 4 and not fresh then
            self:Alert(key, e, s, ("%d yd away"):format(floor(d + 0.5)))
            return
          end
        end
      end
    end
  end
end

------------------------------------------------------------------------
-- Map pins
------------------------------------------------------------------------

function T:Pins(rares, used, mapID, f, Wd, Ht, scale)
  local db = ns.db
  local function pin(kind, key, name, s, faded, learned)
    used = used + 1
    local p = rares:Pin(used)
    p.kind, p.tkey, p.name, p.m, p.x, p.y, p.learned = kind, key, name, s.m, s.x, s.y, learned
    local size = (learned and 11 or 9) * scale
    p:SetSize(size, size)
    p:ClearAllPoints()
    p:SetPoint("CENTER", f, "TOPLEFT", s.x * Wd, -s.y * Ht)
    local c = COLORS[kind] or COLORS.find
    p.dot:SetColorTexture(c[1], c[2], c[3], faded and 0.3 or 1)
    S.ColorEdges(p.edges, c[1], c[2], c[3], learned and 1 or 0.6)
    p:Show()
  end
  -- learned first (drawn under nothing, they're what you've actually found)
  local learnedAt = {}
  if db.findPins then
    for key, e in pairs(db.finds) do
      if not db.rareIgnored["o" .. tostring(key)] then
        for _, s in ipairs(e.spots) do
          if s.m == mapID then
            local faded = s.t and time() - s.t < (db.findRespawn or 900)
            pin(e.kind or "find", key, e.name, s, faded, true)
            learnedAt[key] = true
          end
        end
      end
    end
  end
  if db.chestPins then
    for id in pairs(self.byMap[mapID] or {}) do
      local r = ns.TreasureData[id]
      if r and not db.rareIgnored["o" .. id] and (r[2] == "chest" or db.findPins) then
        for _, s in ipairs(self.spots[id] or {}) do
          if s.m == mapID then pin(r[2], id, r[1], s, false, false) end
        end
      end
    end
  end
  return used
end

function T:PinTooltip(p)
  local db = ns.db
  GameTooltip:SetOwner(p, "ANCHOR_RIGHT")
  local c = COLORS[p.kind] or COLORS.find
  GameTooltip:SetText(p.name or "Treasure", c[1], c[2], c[3])
  local e = db.finds[p.tkey]
  if p.learned and e then
    GameTooltip:AddLine(("You've looted this %d time%s"):format(e.n or 0, e.n == 1 and "" or "s"), 1, 1, 1)
    GameTooltip:AddLine("Last looted " .. R.Ago(e.last), 0.8, 0.8, 0.8)
  else
    GameTooltip:AddLine((p.kind == "chest" and "A chest can spawn here" or "Can be found here") .. " (Classic data)", 0.8, 0.8, 0.8)
    if e then GameTooltip:AddLine("You've looted one " .. (e.n or 0) .. " times", 1, 1, 1) end
  end
  GameTooltip:AddLine("Click: waypoint", 0.6, 0.75, 1)
  GameTooltip:Show()
end

------------------------------------------------------------------------
-- The Treasures list
------------------------------------------------------------------------

function T:FillList(f, m, px, py)
  local db = ns.db
  local items = {}
  local function nearest(spots)
    local best, bs
    for _, s in ipairs(spots) do
      if s.m == m then
        local d = R.Yards(m, s.x, s.y, px, py)
        if not best or d < best then best, bs = d, s end
      end
    end
    return best, bs
  end
  local learnedNames = {}
  for key, e in pairs(db.finds) do
    local d, s = nearest(e.spots)
    if d then
      learnedNames[e.name or ""] = true
      local fresh = s.t and time() - s.t < (db.findRespawn or 900)
      local ignored = db.rareIgnored["o" .. tostring(key)]
      items[#items + 1] = {
        treasure = true, key = key, spot = s, dist = d, name = e.name,
        label = (e.name or "?") .. (ignored and "  |cff808080(ignored)|r" or ""),
        color = COLORS[e.kind] or COLORS.find,
        sub = ("%s · looted %d · last %s%s · %d spot%s"):format(e.kind == "chest" and "Chest" or "Find", e.n or 0,
          R.Ago(e.last), fresh and " (may still be empty)" or "", #e.spots, #e.spots == 1 and "" or "s"),
      }
    end
  end
  -- Classic chests here, one row per kind of chest
  local byName = {}
  for id in pairs(self.byMap[m] or {}) do
    local r = ns.TreasureData[id]
    if r and not learnedNames[r[1]] then
      local g = byName[r[1]]
      if not g then
        g = { treasure = true, classic = true, name = r[1], kind = r[2], spots = {}, ids = {} }
        byName[r[1]] = g
      end
      g.ids[#g.ids + 1] = id
      for _, s in ipairs(self.spots[id] or {}) do if s.m == m then g.spots[#g.spots + 1] = s end end
    end
  end
  for _, g in pairs(byName) do
    local d, s = nearest(g.spots)
    g.dist, g.spot = d, s
    g.label = g.name
    g.color = COLORS[g.kind] or COLORS.find
    g.sub = ("%s · %d possible spot%s (Classic data)"):format(g.kind == "chest" and "Chest" or "Find", #g.spots, #g.spots == 1 and "" or "s")
    items[#items + 1] = g
  end
  table.sort(items, function(a, b)
    if (a.classic or false) ~= (b.classic or false) then return not a.classic end
    return (a.dist or 1e9) < (b.dist or 1e9)
  end)
  R:RenderList(f, ("Treasures in %s  |cff808080%d|r"):format(R.ZoneName(m), #items), items,
    "Nothing known here yet. Loot something and it's remembered.")
end

function T:ListClick(e, button)
  if button == "RightButton" then
    if e.classic then
      for _, id in ipairs(e.ids) do
        local k = "o" .. id
        if ns.db.rareIgnored[k] then ns.db.rareIgnored[k] = nil else ns.db.rareIgnored[k] = e.name end
      end
    else
      local k = "o" .. tostring(e.key)
      if ns.db.rareIgnored[k] then ns.db.rareIgnored[k] = nil else ns.db.rareIgnored[k] = e.name end
    end
    R:FillList()
    R:DrawPins()
  elseif e.spot then
    R:Waypoint({ name = e.name, m = e.spot.m, x = e.spot.x, y = e.spot.y })
  end
end

------------------------------------------------------------------------
-- Start-up
------------------------------------------------------------------------

function T:Enable()
  local db = ns.db
  db.finds = db.finds or {}
  self:WatchTooltip()
  local ev = CreateFrame("Frame")
  for _, e in ipairs({ "LOOT_OPENED", "UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_START" }) do pcall(ev.RegisterEvent, ev, e) end
  ev:SetScript("OnEvent", function(_, event, a1, a2, a3)
    if event == "LOOT_OPENED" then
      T:OnLoot()
    elseif a1 == "player" then
      local spellID = event == "UNIT_SPELLCAST_SUCCEEDED" and a3 or a3
      local name = spellID and ((C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID))
        or (GetSpellInfo and GetSpellInfo(spellID)))
      if name and not Secret(name) then T.lastCast = { name = lower(name), t = GetTime() } end
    end
  end)
  local tick = CreateFrame("Frame")
  local elapsed = 0
  tick:SetScript("OnUpdate", function(_, dt)
    elapsed = elapsed + dt
    if elapsed < 2 then return end
    elapsed = 0
    T:CheckNearby()
  end)
end
