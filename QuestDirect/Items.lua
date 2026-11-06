-- QuestDirect · Quest items
-- A small bar of buttons for quests with a usable item (the ones Blizzard's own
-- tracker showed), nearest quest first, with a keybind for the first button.
--
-- The buttons are secure (the game only lets add-ons use items that way), so the
-- bar can only be rearranged out of combat: changes during combat wait until it
-- ends. It's its own frame, not attached to the tracker, so moving or scaling the
-- tracker in combat still works.

local _, ns = ...
local QP = ns.QP

local I = { buttons = {}, shown = {} }
QP.Items = I

local MAX, SIZE, GAP = 8, 32, 4
local WHITE = "Interface\\Buttons\\WHITE8X8"
local EDGE = { 0.35, 0.4, 0.5 }
local ACCENT = { 0.5, 0.78, 1 }

local function Tex(parent, layer, sub)
  local t = parent:CreateTexture(nil, layer, nil, sub)
  if t.SetSnapToPixelGrid then t:SetSnapToPixelGrid(false) end
  if t.SetTexelSnappingBias then t:SetTexelSnappingBias(0) end
  return t
end

local function Edges(parent, r, g, b, a)
  local e = {}
  for i = 1, 4 do
    e[i] = Tex(parent, "OVERLAY", 6)
    e[i]:SetColorTexture(r, g, b, a)
  end
  e[1]:SetPoint("TOPLEFT"); e[1]:SetPoint("TOPRIGHT"); e[1]:SetHeight(1)
  e[2]:SetPoint("BOTTOMLEFT"); e[2]:SetPoint("BOTTOMRIGHT"); e[2]:SetHeight(1)
  e[3]:SetPoint("TOPLEFT"); e[3]:SetPoint("BOTTOMLEFT"); e[3]:SetWidth(1)
  e[4]:SetPoint("TOPRIGHT"); e[4]:SetPoint("BOTTOMRIGHT"); e[4]:SetWidth(1)
  return e
end

local function ItemCooldown(id)
  if C_Container and C_Container.GetItemCooldown then return C_Container.GetItemCooldown(id) end
  if GetItemCooldown then return GetItemCooldown(id) end
end

local function Font(fs, size)
  local FUI = (_G.KUI or _G.ForeverUI)
  if FUI and FUI.Style and FUI.Style.SetFont then FUI.Style.SetFont(fs, size, "OUTLINE") end
end

function I:Build()
  if self.bar then return end
  local db = QP.db
  local bar = CreateFrame("Frame", "QuestDirectItemBar", UIParent)
  bar:SetSize(SIZE, SIZE)
  bar:SetFrameStrata("MEDIUM")
  bar:SetClampedToScreen(true)
  bar:SetMovable(true)
  bar:Hide()
  -- drag handle on the left (unlocked tracker, out of combat)
  local grip = CreateFrame("Frame", nil, bar)
  grip:SetPoint("TOPRIGHT", bar, "TOPLEFT", -2, 0)
  grip:SetPoint("BOTTOMRIGHT", bar, "BOTTOMLEFT", -2, 0)
  grip:SetWidth(6)
  local gt = Tex(grip, "ARTWORK")
  gt:SetAllPoints()
  gt:SetColorTexture(EDGE[1], EDGE[2], EDGE[3], 0.5)
  grip:EnableMouse(true)
  grip:RegisterForDrag("LeftButton")
  grip:SetScript("OnDragStart", function()
    if not db.locked and not InCombatLockdown() then bar:StartMoving() end
  end)
  grip:SetScript("OnDragStop", function()
    bar:StopMovingOrSizing()
    db.itemLeft, db.itemTop = math.floor(bar:GetLeft() + 0.5), math.floor(bar:GetTop() + 0.5)
  end)
  grip:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Quest items", 1, 1, 1)
    GameTooltip:AddLine(db.locked and "Unlock the tracker to move this bar" or "Drag to move", 0.7, 0.7, 0.7)
    GameTooltip:Show()
  end)
  grip:SetScript("OnLeave", function() GameTooltip:Hide() end)
  bar.grip = grip
  self.bar = bar

  for i = 1, MAX do
    local b = CreateFrame("Button", "QuestDirectItem" .. i, bar, "SecureActionButtonTemplate")
    b:SetSize(SIZE, SIZE)
    b:RegisterForClicks("AnyUp", "AnyDown")
    b:SetAttribute("type", "item")
    local bg = Tex(b, "BACKGROUND", -8)
    bg:SetAllPoints()
    bg:SetColorTexture(0.04, 0.05, 0.07, 0.85)
    b.icon = Tex(b, "ARTWORK")
    b.icon:SetPoint("TOPLEFT", 1, -1)
    b.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    b.edges = Edges(b, EDGE[1], EDGE[2], EDGE[3], 0.9)
    local hl = Tex(b, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.15)
    b.cd = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
    b.cd:SetAllPoints(b.icon)
    b.count = b:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    b.count:SetPoint("BOTTOMRIGHT", -2, 2)
    Font(b.count, 12)
    b.key = b:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmallGray")
    b.key:SetPoint("TOPRIGHT", -2, -2)
    Font(b.key, 10)
    b:SetScript("OnEnter", function(self)
      if not self.link then return end
      GameTooltip:SetOwner(self, "ANCHOR_LEFT")
      GameTooltip:SetHyperlink(self.link)
      if self.questTitle then GameTooltip:AddLine("For: " .. self.questTitle, ACCENT[1], ACCENT[2], ACCENT[3]) end
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:Hide()
    self.buttons[i] = b
  end
  self:Place()
end

function I:Place()
  local bar, db = self.bar, QP.db
  bar:ClearAllPoints()
  if db.itemLeft then
    bar:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", db.itemLeft, db.itemTop)
  else
    local t = QP.Tracker and QP.Tracker.frame
    if t and t:GetLeft() then
      bar:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", t:GetLeft() - 10, t:GetTop())
    else
      bar:SetPoint("RIGHT", UIParent, "RIGHT", -320, 120)
    end
  end
end

-- Quests in your log that have an item to use, nearest first (focused quest first).
function I:Collect()
  local list = {}
  if not GetQuestLogSpecialItemInfo then return list end
  for _, q in ipairs(QP.Quests.list) do
    if not QP.char.hidden[q.id] and q.index then
      local ok, link, tex, charges, showComplete = pcall(GetQuestLogSpecialItemInfo, q.index)
      if ok and link and (not q.complete or showComplete) then
        local id = tonumber(link:match("item:(%d+)"))
        list[#list + 1] = { quest = q, link = link, icon = tex, charges = charges, id = id }
      end
    end
  end
  local focus = QP.char.focus
  table.sort(list, function(a, b)
    if (a.quest.id == focus) ~= (b.quest.id == focus) then return a.quest.id == focus end
    local da, db = a.quest.distance or math.huge, b.quest.distance or math.huge
    if da ~= db then return da < db end
    return a.quest.title < b.quest.title
  end)
  return list
end

function I:Update()
  if not QP.db then return end
  self:Build()
  if InCombatLockdown() then
    self.pending = true
    self:Cooldowns()
    return
  end
  self.pending = false
  local list = QP.db.items and self:Collect() or {}
  local n = math.min(#list, MAX)
  for i = 1, MAX do
    local b, it = self.buttons[i], list[i]
    if it then
      b:SetAttribute("item", it.id and ("item:" .. it.id) or it.link)
      b.link, b.itemID, b.questTitle = it.link, it.id, it.quest.title
      b.icon:SetTexture(it.icon)
      b.count:SetText(it.charges and it.charges > 1 and it.charges or "")
      b:ClearAllPoints()
      b:SetPoint("TOPLEFT", self.bar, "TOPLEFT", (i - 1) * (SIZE + GAP), 0)
      b:Show()
    else
      b.link, b.itemID, b.questTitle = nil, nil, nil
      b:Hide()
    end
  end
  self.bar:SetWidth(math.max(SIZE, n * (SIZE + GAP) - GAP))
  self.bar:SetShown(n > 0)
  self:Keys()
  self:Cooldowns()
end

function I:Cooldowns()
  for _, b in ipairs(self.buttons) do
    if b.itemID and b:IsShown() then
      local start, duration, enable = ItemCooldown(b.itemID)
      if CooldownFrame_Set and start then CooldownFrame_Set(b.cd, start, duration, enable)
      elseif start and duration and duration > 0 then b.cd:SetCooldown(start, duration) end
    end
  end
end

function I:Keys()
  local b = self.buttons[1]
  if not b then return end
  local key = GetBindingKey and GetBindingKey("CLICK QuestDirectItem1:LeftButton")
  if key and GetBindingText then key = GetBindingText(key, true) end
  b.key:SetText(key or "")
end

QP:Listen("QUESTS_CHANGED", function() I:Update() end)
QP:Listen("NAV_CHANGED", function() if not InCombatLockdown() then I:Update() end end)
QP:Listen("LOGIN", function() C_Timer.After(2.5, function() I:Update() end) end)
QP:On("PLAYER_REGEN_ENABLED", function() if I.pending then I:Update() end end)
QP:On("BAG_UPDATE_COOLDOWN", function() if I.bar then I:Cooldowns() end end)
QP:On("UPDATE_BINDINGS", function() if I.bar then I:Keys() end end)
