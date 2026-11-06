-- kUI · Loot
-- Replaces the loot window with a flat one in QuestDirect's style: a row per
-- item with its icon, rarity outline and glow, and name in its rarity colour.
-- Click to loot, Shift-click to link, "All" takes everything, Esc closes.

local _, ns = ...
local FUI, S = ns.FUI, ns.Style

local L = { key = "loot", name = "Loot window", rows = {} }
ns.Loot = L

local ROW_H, ICON, WIDTH, PAD = 30, 26, 230, 4
local floor, max = math.floor, math.max

local function SlotIsMoney(slot)
  local t = GetLootSlotType and GetLootSlotType(slot)
  local money = (Enum and Enum.LootSlotType and Enum.LootSlotType.Money) or LOOT_SLOT_MONEY or 2
  return t == money
end

------------------------------------------------------------------------
-- Window
------------------------------------------------------------------------

function L:Build()
  if self.frame then return end
  local f = CreateFrame("Frame", "KUILoot", UIParent)
  f:SetFrameStrata("HIGH")
  f:SetToplevel(true)
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:SetWidth(WIDTH)
  f:Hide()
  S.Panel(f)
  S.Header(f)

  local header = CreateFrame("Frame", nil, f)
  header:SetPoint("TOPLEFT", 1, -1)
  header:SetPoint("TOPRIGHT", -1, -1)
  header:SetHeight(S.HEADER_H - 1)
  header:EnableMouse(true)
  header:RegisterForDrag("LeftButton")
  header:SetScript("OnDragStart", function() f:StartMoving() end)
  header:SetScript("OnDragStop", function()
    f:StopMovingOrSizing()
    ns.db.lootLeft, ns.db.lootTop = floor(f:GetLeft() + 0.5), floor(f:GetTop() + 0.5)
  end)
  f.title = S.Text(header, "GameFontNormal", nil, nil, 14)
  f.title:SetPoint("LEFT", 8, 0)
  f.title:SetTextColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3])

  f.close = S.Button(header, "x", 20, function() L:Close() end, nil)
  f.close:SetPoint("RIGHT", -2, 0)
  f.all = S.Button(header, "All", 32, function() L:LootAll() end, "Take everything")
  f.all:SetPoint("RIGHT", f.close, "LEFT", -2, 0)
  f.title:SetPoint("RIGHT", f.all, "LEFT", -4, 0)

  f:SetScript("OnHide", function()
    if L.open and not L.closing and not L.testing then CloseLoot() end
    L.testing = false
  end)
  table.insert(UISpecialFrames, "KUILoot") -- Esc closes it
  self.frame = f
end

local function RowEnter(r)
  if not r.slot then return end
  GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
  if L.testing then
    if r.itemID then GameTooltip:SetItemByID(r.itemID) else GameTooltip:SetText(r.name:GetText() or "") end
  elseif SlotIsMoney(r.slot) then
    GameTooltip:SetText(r.name:GetText() or "")
  elseif GetLootSlotType and Enum and Enum.LootSlotType and GetLootSlotType(r.slot) == Enum.LootSlotType.Currency and GameTooltip.SetLootCurrency then
    GameTooltip:SetLootCurrency(r.slot)
  else
    GameTooltip:SetLootItem(r.slot)
  end
  GameTooltip:Show()
  if CursorUpdate then CursorUpdate(r) end
end

local function RowClick(r)
  if not r.slot or L.testing then return end
  if IsModifiedClick() then
    local link = GetLootSlotLink(r.slot)
    if link and HandleModifiedItemClick(link) then return end
  end
  LootSlot(r.slot)
end

function L:Row(i)
  local r = self.rows[i]
  if r then return r end
  local f = self.frame
  r = CreateFrame("Button", nil, f)
  r:SetHeight(ROW_H)
  r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  r:SetScript("OnClick", RowClick)
  r:SetScript("OnEnter", RowEnter)
  r:SetScript("OnLeave", function() GameTooltip:Hide(); if ResetCursor then ResetCursor() end end)
  S.Highlight(r, 0.07)
  r.icon = r:CreateTexture(nil, "ARTWORK")
  r.icon:SetSize(ICON, ICON)
  r.icon:SetPoint("LEFT", 6, 0)
  r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  local slotBg = S.Tex(r, "BACKGROUND", -6)
  slotBg:SetAllPoints(r.icon)
  slotBg:SetColorTexture(1, 1, 1, 0.035)
  r.glow = S.Glow(r, r.icon, ICON)
  r.count = S.Text(r, "NumberFontNormal", "RIGHT", "OVERLAY", 12, "OUTLINE")
  r.count:SetDrawLayer("OVERLAY", 7)
  r.count:SetPoint("BOTTOMRIGHT", r.icon, "BOTTOMRIGHT", 1, 0)
  r.name = S.Text(r, "GameFontNormal", nil, nil, 13)
  r.name:SetPoint("LEFT", r.icon, "RIGHT", 8, 0)
  r.name:SetPoint("RIGHT", -PAD - 2, 0)
  r.tag = S.Text(r, "GameFontHighlightSmall", "RIGHT", nil, 11)
  r.tag:SetPoint("RIGHT", -PAD - 2, 0)
  self.rows[i] = r
  return r
end

-- items = { { slot, icon, name, count, quality, quest, starts, locked, itemID } }
function L:Show(items, title)
  self:Build()
  local f = self.frame
  f.title:SetText(title or "Loot")
  local y = S.HEADER_H + 2
  local shown = 0
  for i, it in ipairs(items) do
    local r = self:Row(i)
    r.slot, r.itemID, r.quality = it.slot, it.itemID, it.quality
    r.icon:SetTexture(it.icon)
    r.icon:SetDesaturated(it.locked and true or false)
    S.PaintGlow(r.glow, it.quality)
    r.count:SetText(it.count and it.count > 1 and it.count or "")
    r.name:SetText(it.name or "")
    local cr, cg, cb = 1, 1, 1
    local qr, qg, qb = S.QualityRGB(it.quality)
    if it.quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[it.quality] then
      local c = ITEM_QUALITY_COLORS[it.quality]
      cr, cg, cb = c.r, c.g, c.b
    elseif qr then
      cr, cg, cb = qr, qg, qb
    end
    if it.locked then cr, cg, cb = 0.6, 0.3, 0.3 end
    r.name:SetTextColor(cr, cg, cb)
    if it.starts then
      r.tag:SetText("|cffffd100Starts a quest|r")
    elseif it.quest then
      r.tag:SetText("|cffffd100Quest|r")
    else
      r.tag:SetText("")
    end
    r.name:SetPoint("RIGHT", r.tag:GetText() ~= "" and r.tag or r, r.tag:GetText() ~= "" and "LEFT" or "RIGHT", -PAD, 0)
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", 1, -y)
    r:SetPoint("TOPRIGHT", -1, -y)
    r:Show()
    y = y + ROW_H
    shown = i
  end
  for i = shown + 1, #self.rows do
    self.rows[i]:Hide()
    self.rows[i].slot = nil
  end
  f:SetHeight(y + PAD)
  self:Place()
  f:Show()
end

-- Under the mouse if the game's "loot under mouse" option is on, else where you left it.
function L:Place()
  local f = self.frame
  if f:IsShown() then return end
  f:ClearAllPoints()
  local underMouse = GetCVarBool and GetCVarBool("lootUnderMouse")
  if underMouse then
    local x, y = GetCursorPosition()
    local s = f:GetEffectiveScale()
    f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / s - 30, y / s + S.HEADER_H + ROW_H / 2)
  elseif ns.db.lootLeft then
    f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", ns.db.lootLeft, ns.db.lootTop)
  else
    f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 260, -220)
  end
end

------------------------------------------------------------------------
-- Real loot
------------------------------------------------------------------------

function L:Read()
  local items = {}
  for slot = 1, (GetNumLootItems() or 0) do
    if LootSlotHasItem == nil or LootSlotHasItem(slot) then
      local icon, name, count, _, quality, locked, isQuest, questID, isActive = GetLootSlotInfo(slot)
      if icon then
        if SlotIsMoney(slot) then
          name = (name or ""):gsub("\n", " ")
          quality = nil
        end
        items[#items + 1] = {
          slot = slot, icon = icon, name = name, count = count, quality = quality, locked = locked,
          quest = isQuest, starts = questID and questID > 0 and not isActive,
        }
      end
    end
  end
  return items
end

local function Title()
  if UnitExists("target") and UnitIsDead and UnitIsDead("target") then
    local n = UnitName("target")
    if n and not (issecretvalue and issecretvalue(n)) then return n end
  end
  return "Loot"
end

function L:Update()
  if not self.open then return end
  local items = self:Read()
  if #items == 0 then
    self.frame:Hide()
    return
  end
  self:Show(items, self.title)
end

function L:LootAll()
  if self.testing then return self.frame:Hide() end
  for slot = GetNumLootItems(), 1, -1 do
    if LootSlotHasItem == nil or LootSlotHasItem(slot) then
      local icon, _, _, _, _, locked = GetLootSlotInfo(slot)
      if icon and not locked then LootSlot(slot) end
    end
  end
end

function L:Close()
  if self.testing then
    self.frame:Hide()
  else
    CloseLoot()
  end
end

-- A sample window so you can see the look without looting anything.
function L:Test()
  local sample = {
    { 2589, 4 }, -- Linen Cloth (common)
    { 774, 1 },  -- Malachite (uncommon)
    { 818, 1 },  -- Tigerseye (uncommon)
    { 2770, 3 }, -- Copper Ore
    { 4306, 2 }, -- Silk Cloth
    { 6948, 1 }, -- Hearthstone
  }
  local items = {}
  for i, s in ipairs(sample) do
    local name, _, quality, _, _, _, _, _, _, icon = GetItemInfo(s[1])
    icon = icon or (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(s[1])) or "Interface\\Icons\\INV_Misc_QuestionMark"
    items[#items + 1] = { slot = i, itemID = s[1], icon = icon, name = name or ("Item " .. s[1]), count = s[2], quality = quality or 1 }
  end
  local icon = items[1].icon
  items[#items + 1] = { slot = #items + 1, icon = "Interface\\Icons\\INV_Misc_Coin_01", name = "3 Silver 12 Copper" }
  items[#items + 1] = { slot = #items + 1, icon = icon, name = "Rare sample (quest item)", count = 1, quality = 3, quest = true }
  items[#items + 1] = { slot = #items + 1, icon = icon, name = "Epic sample", count = 1, quality = 4 }
  items[#items + 1] = { slot = #items + 1, icon = icon, name = "Poor sample", count = 1, quality = 0 }
  self.testing = true
  self:Build()
  self.frame:Hide()
  self.testing = true
  self:Show(items, "Sample loot")
end

function L:Refresh()
  if not self.frame then return end
  S.Panel(self.frame)
  for _, r in ipairs(self.rows) do
    if r:IsShown() then S.PaintGlow(r.glow, r.quality) end
  end
  if self.open then self:Update() end
end

------------------------------------------------------------------------
-- Events
------------------------------------------------------------------------

function L:Enable()
  self.enabled = true
  self:Build()
  -- Blizzard's loot window stops listening; everything else about looting is unchanged.
  if LootFrame then
    for _, e in ipairs({ "LOOT_OPENED", "LOOT_SLOT_CLEARED", "LOOT_SLOT_CHANGED", "LOOT_CLOSED" }) do
      pcall(LootFrame.UnregisterEvent, LootFrame, e)
    end
  end
  local ev = CreateFrame("Frame")
  for _, e in ipairs({ "LOOT_OPENED", "LOOT_SLOT_CLEARED", "LOOT_SLOT_CHANGED", "LOOT_CLOSED" }) do ev:RegisterEvent(e) end
  ev:SetScript("OnEvent", function(_, event, autoLoot)
    if event == "LOOT_OPENED" then
      L.testing = false
      if L.frame:IsShown() then L.frame:Hide() end
      L.open, L.title = true, Title()
      if autoLoot then
        -- Auto loot: only show what's left once it's had a moment (no flash).
        C_Timer.After(0.3, function() if L.open then L:Update() end end)
      else
        L:Update()
      end
    elseif event == "LOOT_CLOSED" then
      L.open = false
      L.closing = true
      L.frame:Hide()
      L.closing = false
    elseif L.open and (L.frame:IsShown() or event == "LOOT_SLOT_CHANGED") then
      L:Update()
    end
  end)
end

FUI:Register(L)
