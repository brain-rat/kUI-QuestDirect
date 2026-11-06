-- kUI · Tooltips
-- Every tooltip in the flat dark style, with a border in the item's rarity
-- colour, a thin health bar, the kUI font, and a few extra lines on items:
--   * item level on gear (when the game doesn't show it)
--   * vendor price (when the game doesn't show it)
--   * which mobs and nodes it drops from, from GoldForever's record of your play

local _, ns = ...
local FUI, S = ns.FUI, ns.Style

local T = { key = "tooltips", name = "Tooltips", styled = {} }
ns.Tooltips = T

local floor, max = math.floor, math.max

local NAMES = {
  "GameTooltip", "ItemRefTooltip", "ShoppingTooltip1", "ShoppingTooltip2",
  "ItemRefShoppingTooltip1", "ItemRefShoppingTooltip2", "EmbeddedItemTooltip",
  "WorldMapTooltip", "WorldMapCompareTooltip1", "WorldMapCompareTooltip2",
  "FriendsTooltip", "SmallTextTooltip", "NamePlateTooltip", "QuestScrollTooltip",
}

local function Secret(v) return issecretvalue and issecretvalue(v) end

-- Keep something faded even if the game sets its alpha again.
local function KeepFaded(obj)
  if type(obj) ~= "table" or not obj.SetAlpha then return end
  obj:SetAlpha(0)
  if obj.fuiFaded then return end
  obj.fuiFaded = true
  hooksecurefunc(obj, "SetAlpha", function(self, a) if a ~= 0 then self:SetAlpha(0) end end)
end

local function Border(tip, r, g, b, a)
  local p = tip.fuiPanel
  if p then S.ColorEdges(p.edges, r, g, b, a) end
end

local function ResetBorder(tip)
  Border(tip, S.EDGE[1], S.EDGE[2], S.EDGE[3], 0.9)
end

function T:Style(tip)
  if type(tip) ~= "table" or tip.fuiStyled then return end
  tip.fuiStyled = true
  KeepFaded(tip.NineSlice)
  if tip.SetBackdropColor then
    pcall(tip.SetBackdropColor, tip, 0, 0, 0, 0)
    pcall(tip.SetBackdropBorderColor, tip, 0, 0, 0, 0)
    if tip.SetBackdrop and not tip.NineSlice then
      hooksecurefunc(tip, "SetBackdropColor", function(self, _, _, _, a)
        if a and a > 0 then self:SetBackdropColor(0, 0, 0, 0) end
      end)
    end
  end
  S.Panel(tip, max(ns.db.alpha, 0.9))
  ResetBorder(tip)
  tip:HookScript("OnShow", function(self)
    if self.SetBackdropColor and not self.NineSlice then
      pcall(self.SetBackdropColor, self, 0, 0, 0, 0)
      pcall(self.SetBackdropBorderColor, self, 0, 0, 0, 0)
    end
    if not self.fuiRarity then ResetBorder(self) end
  end)
  tip:HookScript("OnHide", function(self) self.fuiRarity = nil end)
  if tip.HasScript and tip:HasScript("OnTooltipCleared") then
    tip:HookScript("OnTooltipCleared", function(self)
      self.fuiRarity = nil
      ResetBorder(self)
    end)
  end
  table.insert(self.styled, tip)
end

function T:StyleBar()
  local bar = _G.GameTooltipStatusBar
  if not bar or bar.fuiStyled then return end
  bar.fuiStyled = true
  bar:SetStatusBarTexture(S.WHITE)
  bar:SetHeight(4)
  bar:ClearAllPoints()
  bar:SetPoint("TOPLEFT", GameTooltip, "BOTTOMLEFT", 1, -2)
  bar:SetPoint("TOPRIGHT", GameTooltip, "BOTTOMRIGHT", -1, -2)
  local bg = S.Tex(bar, "BACKGROUND", -8)
  bg:SetPoint("TOPLEFT", -1, 1)
  bg:SetPoint("BOTTOMRIGHT", 1, -1)
  bg:SetColorTexture(S.BG[1], S.BG[2], S.BG[3], 0.9)
  for _, r in ipairs({ bar:GetRegions() }) do
    if r ~= bg and r.IsObjectType and r:IsObjectType("Texture") and r ~= bar:GetStatusBarTexture() then r:SetAlpha(0) end
  end
  if bar.BorderLeft then KeepFaded(bar.BorderLeft) end
end

function T:Fonts()
  -- the font objects every tooltip uses
  if _G.GameTooltipHeaderText then S.SetFont(_G.GameTooltipHeaderText, 15) end
  if _G.GameTooltipText then S.SetFont(_G.GameTooltipText, 13) end
  if _G.GameTooltipTextSmall then S.SetFont(_G.GameTooltipTextSmall, 12) end
end

------------------------------------------------------------------------
-- Extra item lines
------------------------------------------------------------------------

local function HasLine(tip, pattern)
  local name = tip.GetName and tip:GetName()
  if not name then return false end
  for i = 1, (tip.NumLines and tip:NumLines() or 0) do
    local fs = _G[name .. "TextLeft" .. i]
    local t = fs and fs:GetText()
    if t and not Secret(t) and t:find(pattern) then return true end
  end
  return false
end

local function Money(c)
  c = floor((c or 0) + 0.5)
  if GetCoinTextureString then return GetCoinTextureString(c) end
  return ("%dg %ds %dc"):format(floor(c / 10000), floor(c / 100) % 100, c % 100)
end

-- itemID -> { {name, chance, loots}, ... } from GoldForever's drop record, rebuilt now and then.
local dropIndex, dropBuilt, dropLoots = nil, 0, -1
function T:DropsFor(itemID)
  local GF = _G.GoldForever
  local drops = GF and GF.db and GF.db.drops
  if not drops then return nil end
  local now = GetTime()
  if not dropIndex or now - dropBuilt > 30 then
    local total = 0
    for _, d in pairs(drops) do total = total + (d.loots or 0) end
    if total ~= dropLoots or not dropIndex then
      dropIndex = {}
      for key, d in pairs(drops) do
        local loots = d.loots or 0
        if loots > 0 then
          for ikey, it in pairs(d.it or {}) do
            local id = tonumber(tostring(ikey):match("^(%d+)"))
            if id then
              dropIndex[id] = dropIndex[id] or {}
              local name = (d.name or "?"):gsub("^Node: ", "")
              -- chests and other objects by their own name, not their first item
              local oid = key:sub(1, 1) == "o" and tonumber(key:sub(2))
              if oid and ns.TreasureData and ns.TreasureData[oid] then name = ns.TreasureData[oid][1] end
              table.insert(dropIndex[id], { name = name, chance = (it.seen or 0) / loots, loots = loots, node = key:sub(1, 1) == "o" })
            end
          end
        end
      end
      for _, list in pairs(dropIndex) do
        table.sort(list, function(a, b)
          if a.chance ~= b.chance then return a.chance > b.chance end
          return a.loots > b.loots
        end)
      end
      dropLoots = total
    end
    dropBuilt = now
  end
  return dropIndex[itemID]
end

local function Instant(link)
  local fn = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
  if fn then return fn(link) end
end

function T:OnItem(tip, link)
  if not tip or not tip.fuiStyled or not link or Secret(link) then return end
  local info = C_Item and C_Item.GetItemInfo or GetItemInfo
  local name, _, quality, ilvl, _, _, _, _, _, _, sell = info(link)
  local id, _, _, _, _, classID = Instant(link)
  if quality then
    local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
    if c and quality ~= 1 then
      tip.fuiRarity = quality
      Border(tip, c.r, c.g, c.b, 1)
    end
  end
  local db = ns.db
  local added = false
  if db.tipIlvl and ilvl and ilvl > 1 and (classID == 2 or classID == 4) and not HasLine(tip, "Item Level") then
    tip:AddLine("Item level " .. ilvl, 0.85, 0.85, 0.85)
    added = true
  end
  if db.tipVendor and sell and sell > 0 and not (tip.shownMoneyFrames and tip.shownMoneyFrames > 0) then
    tip:AddDoubleLine("Vendor", Money(sell), 0.75, 0.75, 0.75, 1, 1, 1)
    added = true
  end
  if db.tipDrops and id then
    local list = self:DropsFor(id)
    if list and #list > 0 then
      tip:AddLine("Drops from (your loot record)", S.ACCENT[1], S.ACCENT[2], S.ACCENT[3])
      for i = 1, math.min(3, #list) do
        local d = list[i]
        local pct = d.chance >= 0.995 and "100%" or (d.chance >= 0.1 and ("%d%%"):format(floor(d.chance * 100 + 0.5)) or ("%.1f%%"):format(d.chance * 100))
        tip:AddDoubleLine("  " .. d.name, ("%s  |cff808080of %d|r"):format(pct, d.loots), 0.9, 0.9, 0.9, 1, 1, 1)
      end
      if #list > 3 then tip:AddLine(("  and %d more"):format(#list - 3), 0.6, 0.6, 0.6) end
      added = true
    end
  end
  if added and tip.Show then tip:Show() end
end

------------------------------------------------------------------------
-- Start-up
------------------------------------------------------------------------

function T:Refresh()
  for _, tip in ipairs(self.styled) do
    S.Panel(tip, max(ns.db.alpha, 0.9))
    if not tip.fuiRarity then ResetBorder(tip) end
  end
end

function T:Enable()
  self.enabled = true
  for _, n in ipairs(NAMES) do self:Style(_G[n]) end
  self:StyleBar()
  self:Fonts()
  -- Tooltips made later (some windows load on demand)
  local ev = CreateFrame("Frame")
  ev:RegisterEvent("ADDON_LOADED")
  ev:SetScript("OnEvent", function()
    for _, n in ipairs(NAMES) do if _G[n] and not _G[n].fuiStyled then T:Style(_G[n]) end end
  end)
  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tip)
      if not (tip and tip.GetItem) then return end
      local _, link = tip:GetItem()
      local ok, err = pcall(T.OnItem, T, tip, link)
      if not ok and T.debug then FUI:Print("tooltip: %s", tostring(err)) end
    end)
  else
    for _, tip in ipairs(self.styled) do
      if tip.HasScript and tip:HasScript("OnTooltipSetItem") then
        tip:HookScript("OnTooltipSetItem", function(self)
          local _, link = self:GetItem()
          pcall(T.OnItem, T, self, link)
        end)
      end
    end
  end
end

FUI:Register(T)
