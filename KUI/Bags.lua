-- kUI · Bags
-- One bag window (and one bank window) in QuestDirect's style:
--   * items sorted into categories that sit side by side when they fit
--   * every empty slot shown at the bottom
--   * rarity outline and inner glow on every item
--   * adjustable columns, slot size, horizontal and vertical gaps, fonts
--   * search, sort, money, item level, quest and new-item markers
--
-- Item slots are the game's own container item buttons, so clicking, dragging,
-- using, splitting, tooltips and selling all behave exactly like the default bags.

local _, ns = ...
local FUI, S = ns.FUI, ns.Style

local B = { key = "bags", name = "Bags", windows = {} }
ns.Bags = B

local floor, max, min, lower = math.floor, math.max, math.min, string.lower
local CC = C_Container
local PAD, HEADER_H, FOOTER_H = 8, 26, 24

------------------------------------------------------------------------
-- Container API (modern C_Container, or the old globals)
------------------------------------------------------------------------

local function NumSlots(bag)
  local fn = CC and CC.GetContainerNumSlots or GetContainerNumSlots
  return fn and fn(bag) or 0
end

local function ItemInfo(bag, slot)
  if CC and CC.GetContainerItemInfo then return CC.GetContainerItemInfo(bag, slot) end
  local tex, count, locked, quality, _, _, link, _, noValue, itemID = GetContainerItemInfo(bag, slot)
  if not tex then return nil end
  return { iconFileID = tex, stackCount = count, isLocked = locked, quality = quality, hyperlink = link,
           hasNoValue = noValue, itemID = itemID }
end

local function QuestInfo(bag, slot)
  if CC and CC.GetContainerItemQuestInfo then
    local q = CC.GetContainerItemQuestInfo(bag, slot)
    if q then return q.isQuestItem, q.questID, q.isActive end
  elseif GetContainerItemQuestInfo then
    return GetContainerItemQuestInfo(bag, slot)
  end
end

local function Cooldown(bag, slot)
  local fn = CC and CC.GetContainerItemCooldown or GetContainerItemCooldown
  if fn then return fn(bag, slot) end
end

local function Instant(id)
  local fn = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
  if fn then return fn(id) end
end

local function ItemName(id)
  local fn = C_Item and C_Item.GetItemInfo or GetItemInfo
  local name = fn and fn(id)
  return name
end

local function ItemLevel(link)
  local fn = C_Item and C_Item.GetDetailedItemLevelInfo or GetDetailedItemLevelInfo
  return fn and link and fn(link)
end

local function IsNew(bag, slot)
  return C_NewItems and C_NewItems.IsNewItem and C_NewItems.IsNewItem(bag, slot) or false
end

local EQUIPPED = NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4

local function BagIDs()
  local t = {}
  for bag = 0, EQUIPPED do t[#t + 1] = bag end
  return t
end

local function BankIDs()
  local t = { BANK_CONTAINER or -1 }
  for i = 1, (NUM_BANKBAGSLOTS or 6) do t[#t + 1] = EQUIPPED + i end
  local E = Enum and Enum.BagIndex
  if E and E.CharacterBankTab_1 then
    for i = 1, 6 do
      local id = E["CharacterBankTab_" .. i]
      if id then t[#t + 1] = id end
    end
  end
  if REAGENTBANK_CONTAINER and IsReagentBankUnlocked and IsReagentBankUnlocked() then
    t[#t + 1] = REAGENTBANK_CONTAINER
  end
  return t
end

------------------------------------------------------------------------
-- Categories
------------------------------------------------------------------------

local CATS = {
  { key = "new", label = "New" },
  { key = "quest", label = "Quest" },
  { key = "equipment", label = "Equipment", classes = { 2, 4 } },
  { key = "consumable", label = "Consumables", classes = { 0 } },
  { key = "trade", label = "Trade Goods", classes = { 7 } },
  { key = "reagent", label = "Reagents", classes = { 5 } },
  { key = "recipe", label = "Recipes", classes = { 9 } },
  { key = "container", label = "Bags", classes = { 1 } },
  { key = "ammo", label = "Ammo", classes = { 6, 11 } },
  { key = "key", label = "Keys", classes = { 13 } },
  { key = "misc", label = "Miscellaneous", classes = { 15, 8, 10, 16, 17, 18, 19 } },
  { key = "junk", label = "Junk" },
  { key = "other", label = "Other" },
}
B.CATS = CATS
local CLASS_CAT = {}
for i, c in ipairs(CATS) do
  c.order = i
  for _, id in ipairs(c.classes or {}) do CLASS_CAT[id] = c end
end
local CAT = {}
for _, c in ipairs(CATS) do CAT[c.key] = c end

local function Categorise(it)
  if it.new then return CAT.new end
  if it.isQuest then return CAT.quest end
  if it.quality == 0 then return CAT.junk end
  return CLASS_CAT[it.classID] or CAT.other
end

------------------------------------------------------------------------
-- Item buttons (the game's own container buttons, restyled)
------------------------------------------------------------------------

local buttonType
local function ButtonType()
  if buttonType then return buttonType end
  local ok, probe = pcall(CreateFrame, "ItemButton", nil, UIParent, "ContainerFrameItemButtonTemplate")
  if ok and probe then probe:Hide() end
  buttonType = ok and "ItemButton" or "Button"
  return buttonType
end

local function Fade(obj)
  if type(obj) == "table" and obj.SetAlpha then obj:SetAlpha(0) end
end

function B:Holder(win, bag)
  local h = win.holders[bag]
  if h then return h end
  h = CreateFrame("Frame", nil, win.content)
  h:SetID(bag)
  h:SetAllPoints(win.content)
  win.holders[bag] = h
  return h
end

function B:NewButton(win, bag, slot)
  local name = ("KUI%sItem%s_%d"):format(win.kind == "bank" and "Bank" or "Bag", bag < 0 and ("m" .. -bag) or bag, slot)
  local b = _G[name] or CreateFrame(ButtonType(), name, self:Holder(win, bag), "ContainerFrameItemButtonTemplate")
  b:SetID(slot)
  if b.SetBagID then pcall(b.SetBagID, b, bag) end
  if b.GetBagID then
    local ok, id = pcall(b.GetBagID, b)
    if not ok or id ~= bag then b.bagID = bag end
  end
  b.fuiBag, b.fuiSlot = bag, slot

  -- Our look instead of the slot art.
  if b.ClearNormalTexture then b:ClearNormalTexture() else b:SetNormalTexture("") end
  for _, k in ipairs({ "IconBorder", "IconQuestTexture", "JunkIcon", "UpgradeIcon", "flash", "NewItemTexture",
                       "BattlepayItemTexture", "ItemContextOverlay", "IconOverlay", "IconOverlay2", "ExtendedSlot" }) do
    Fade(b[k])
  end
  local hl = b:GetHighlightTexture()
  if hl then hl:SetColorTexture(1, 1, 1, 0.15) end
  local pushed = b.GetPushedTexture and b:GetPushedTexture()
  if pushed then pushed:SetColorTexture(1, 1, 1, 0.1) end

  b.fuiIcon = b.icon or b.Icon or _G[name .. "IconTexture"]
  b.fuiIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  b.fuiCount = b.Count or _G[name .. "Count"]
  if b.fuiCount then
    b.fuiCount:SetDrawLayer("OVERLAY", 7)
    b.fuiCount:ClearAllPoints()
    b.fuiCount:SetPoint("BOTTOMRIGHT", -2, 2)
  end
  b.fuiCooldown = b.Cooldown or _G[name .. "Cooldown"]
  b.fuiSlotBg = S.Tex(b, "BACKGROUND", -6)
  b.fuiSlotBg:SetAllPoints()
  b.fuiSlotBg:SetColorTexture(1, 1, 1, 0.04)
  b.fuiGlow = S.Glow(b, b, ns.db.bagSize)
  b.fuiLevel = S.Text(b, nil, "LEFT", "OVERLAY", ns.db.countSize - 1, ns.db.outline)
  b.fuiLevel:SetDrawLayer("OVERLAY", 7)
  b.fuiLevel:SetPoint("TOPLEFT", 2, -2)
  b.fuiMark = S.Text(b, nil, "RIGHT", "OVERLAY", ns.db.countSize + 2, "OUTLINE")
  b.fuiMark:SetDrawLayer("OVERLAY", 7)
  b.fuiMark:SetPoint("TOPRIGHT", -2, -1)
  b.fuiNew = S.Tex(b, "OVERLAY", 7)
  b.fuiNew:SetSize(6, 6)
  b.fuiNew:SetPoint("TOPLEFT", 3, -3)
  b.fuiNew:SetColorTexture(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 1)
  if b.fuiCount then S.SetFont(b.fuiCount, ns.db.countSize, ns.db.outline) end
  return b
end

function B:Button(win, bag, slot)
  win.buttons[bag] = win.buttons[bag] or {}
  local b = win.buttons[bag][slot]
  if not b then
    if InCombatLockdown() then
      self.pendingButtons = true
      return nil
    end
    b = self:NewButton(win, bag, slot)
    win.buttons[bag][slot] = b
  end
  return b
end

-- Draw one slot.
function B:Paint(b, it)
  local db = ns.db
  if it then
    SetItemButtonTexture(b, it.icon)
    SetItemButtonCount(b, it.count)
    SetItemButtonDesaturated(b, it.locked)
    S.PaintGlow(b.fuiGlow, it.quality)
    b.fuiLevel:SetText(db.ilvl and it.level and it.level > 1 and it.level or "")
    if it.level and it.quality then
      local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[it.quality]
      if c then b.fuiLevel:SetTextColor(c.r, c.g, c.b) end
    end
    b.fuiMark:SetText(it.starts and "|cffffd100!|r" or "")
    b.fuiNew:SetShown(it.new and true or false)
    b.fuiSlotBg:SetColorTexture(1, 1, 1, 0.04)
  else
    SetItemButtonTexture(b, nil)
    SetItemButtonCount(b, 0)
    SetItemButtonDesaturated(b, false)
    S.PaintGlow(b.fuiGlow, nil)
    b.fuiLevel:SetText("")
    b.fuiMark:SetText("")
    b.fuiNew:Hide()
    b.fuiSlotBg:SetColorTexture(1, 1, 1, 0.025)
  end
  b.fuiItem = it
  self:PaintCooldown(b)
end

function B:PaintCooldown(b)
  local cd = b.fuiCooldown
  if not cd then return end
  if not b.fuiItem then cd:Hide() return end
  local start, duration, enable = Cooldown(b.fuiBag, b.fuiSlot)
  if CooldownFrame_Set and start then
    CooldownFrame_Set(cd, start, duration, enable)
  elseif cd.SetCooldown and start and duration and duration > 0 then
    cd:SetCooldown(start, duration)
    cd:Show()
  else
    cd:Hide()
  end
end

------------------------------------------------------------------------
-- Windows
------------------------------------------------------------------------

local function Money()
  local m = GetMoney and GetMoney() or 0
  if GetCoinTextureString then return GetCoinTextureString(m) end
  return ("%dg %ds %dc"):format(floor(m / 10000), floor(m / 100) % 100, m % 100)
end

function B:Window(kind)
  if self.windows[kind] then return self.windows[kind] end
  local db = ns.db
  local win = { kind = kind, holders = {}, buttons = {}, headers = {} }
  local name = kind == "bank" and "KUIBank" or "KUIBags"
  local f = CreateFrame("Frame", name, UIParent)
  f:SetFrameStrata("MEDIUM")
  f:SetToplevel(true)
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:Hide()
  S.Panel(f)
  S.Header(f, HEADER_H)
  table.insert(UISpecialFrames, name)

  local header = CreateFrame("Frame", nil, f)
  header:SetPoint("TOPLEFT", 1, -1)
  header:SetPoint("TOPRIGHT", -1, -1)
  header:SetHeight(HEADER_H - 1)
  header:EnableMouse(true)
  header:RegisterForDrag("LeftButton")
  header:SetScript("OnDragStart", function() f:StartMoving() end)
  header:SetScript("OnDragStop", function()
    f:StopMovingOrSizing()
    local l, t = floor(f:GetLeft() + 0.5), floor(f:GetTop() + 0.5)
    if kind == "bank" then db.bankLeft, db.bankTop = l, t else db.bagLeft, db.bagTop = l, t end
  end)
  f.title = S.Text(header, "GameFontNormal", "LEFT", nil, 14)
  f.title:SetPoint("LEFT", 8, 0)
  f.title:SetTextColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3])
  f.title:SetText(kind == "bank" and "Bank" or "Bags")
  f.free = S.Text(header, nil, "LEFT", nil, 12)
  f.free:SetPoint("LEFT", f.title, "RIGHT", 8, 0)
  f.free:SetTextColor(0.75, 0.75, 0.75)

  f.close = S.Button(header, "x", 20, function() f:Hide() end)
  f.close:SetPoint("RIGHT", -2, 0)
  local right = f.close
  if kind == "bags" then
    f.cog = S.Button(header, "Settings", 58, function() B:ToggleSettings() end, "Columns, slot size, gaps, fonts and more")
    f.cog:SetPoint("RIGHT", right, "LEFT", -2, 0)
    right = f.cog
  end
  local sortFn = kind == "bank" and (CC and CC.SortBankBags or SortBankBags) or (CC and CC.SortBags or SortBags)
  if sortFn then
    f.sort = S.Button(header, "Sort", 36, function() pcall(sortFn) end, "Tidy the items in your bags")
    f.sort:SetPoint("RIGHT", right, "LEFT", -2, 0)
    right = f.sort
  end

  -- Search box
  local sb = CreateFrame("EditBox", name .. "Search", header)
  sb:SetSize(110, 18)
  sb:SetPoint("RIGHT", right, "LEFT", -6, 0)
  sb:SetAutoFocus(false)
  sb:SetTextInsets(6, 6, 0, 0)
  S.SetFont(sb, 12)
  local sbg = S.Tex(sb, "BACKGROUND", -8)
  sbg:SetAllPoints()
  sbg:SetColorTexture(0, 0, 0, 0.35)
  S.ColorEdges(S.Edges(sb, "BACKGROUND", -7), S.EDGE[1], S.EDGE[2], S.EDGE[3], 0.6)
  sb.hint = S.Text(sb, nil, "LEFT", nil, 12)
  sb.hint:SetPoint("LEFT", 6, 0)
  sb.hint:SetText("Search")
  sb.hint:SetTextColor(0.5, 0.5, 0.5)
  sb:SetScript("OnEscapePressed", function(self) self:SetText(""); self:ClearFocus() end)
  sb:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
  sb:SetScript("OnTextChanged", function(self)
    local t = self:GetText() or ""
    self.hint:SetShown(t == "")
    B:Search(win, t)
  end)
  f.search = sb

  local content = CreateFrame("Frame", nil, f)
  content:SetPoint("TOPLEFT", PAD, -(HEADER_H + PAD - 2))
  content:SetSize(10, 10)
  win.content = content

  f.money = S.Text(f, nil, "RIGHT", nil, 13)
  f.money:SetPoint("BOTTOMRIGHT", -PAD, 7)
  f.info = S.Text(f, nil, "LEFT", nil, 12)
  f.info:SetPoint("BOTTOMLEFT", PAD, 7)
  f.info:SetTextColor(0.6, 0.6, 0.6)

  if kind == "bank" and PurchaseSlot and GetNumBankSlots then
    f.buy = S.Button(f, "Buy bag slot", 90, function()
      if StaticPopup_Show then StaticPopup_Show("CONFIRM_BUY_BANK_SLOT") end
    end, "Buy another bank bag slot")
    f.buy:SetPoint("BOTTOMLEFT", PAD - 2, 4)
  end

  f:SetScript("OnShow", function()
    B:Layout(win)
    if kind == "bags" and PlaySound and SOUNDKIT and SOUNDKIT.IG_BACKPACK_OPEN then PlaySound(SOUNDKIT.IG_BACKPACK_OPEN) end
  end)
  f:SetScript("OnHide", function()
    sb:SetText("")
    sb:ClearFocus()
    if kind == "bags" then
      if PlaySound and SOUNDKIT and SOUNDKIT.IG_BACKPACK_CLOSE then PlaySound(SOUNDKIT.IG_BACKPACK_CLOSE) end
      if C_NewItems and C_NewItems.ClearAll then C_NewItems.ClearAll() end
      if B.settings then B.settings:Hide() end
    elseif B.bankOpen and CloseBankFrame then
      CloseBankFrame()
    end
  end)

  win.frame = f
  self.windows[kind] = win
  self:Place(win)
  return win
end

function B:Place(win)
  local f, db = win.frame, ns.db
  f:SetScale(db.bagScale)
  f:ClearAllPoints()
  if win.kind == "bank" then
    if db.bankLeft then f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", db.bankLeft, db.bankTop)
    else f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 40, -120) end
  else
    if db.bagLeft then f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", db.bagLeft, db.bagTop)
    else f:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -60, 110) end
  end
end

-- Everything in a set of bags: items (with what's needed to sort them) and empty slots.
function B:Read(bags)
  local items, empty, total = {}, {}, 0
  for _, bag in ipairs(bags) do
    local n = NumSlots(bag)
    for slot = 1, n do
      total = total + 1
      local info = ItemInfo(bag, slot)
      if info and info.iconFileID then
        local id = info.itemID
        local _, _, _, equipLoc, _, classID, subClassID = Instant(id or info.hyperlink or 0)
        local isQuest, questID, active = QuestInfo(bag, slot)
        local it = {
          bag = bag, slot = slot, id = id, icon = info.iconFileID, count = info.stackCount,
          locked = info.isLocked, quality = info.quality, link = info.hyperlink,
          classID = classID, subClassID = subClassID, equipLoc = equipLoc,
          isQuest = isQuest or classID == 12, starts = questID and questID > 0 and not active,
          new = IsNew(bag, slot),
        }
        it.name = id and ItemName(id)
        if not it.name then self.missingNames = true end
        if (classID == 2 or classID == 4) and it.link then it.level = ItemLevel(it.link) end
        items[#items + 1] = it
      else
        empty[#empty + 1] = { bag = bag, slot = slot }
      end
    end
  end
  return items, empty, total
end

local function SortItems(a, b)
  if (a.quality or 0) ~= (b.quality or 0) then return (a.quality or 0) > (b.quality or 0) end
  if (a.classID or 99) ~= (b.classID or 99) then return (a.classID or 99) < (b.classID or 99) end
  if (a.subClassID or 99) ~= (b.subClassID or 99) then return (a.subClassID or 99) < (b.subClassID or 99) end
  if (a.name or "") ~= (b.name or "") then return (a.name or "") < (b.name or "") end
  if (a.count or 0) ~= (b.count or 0) then return (a.count or 0) > (b.count or 0) end
  if a.bag ~= b.bag then return a.bag < b.bag end
  return a.slot < b.slot
end

function B:Header(win, i)
  local h = win.headers[i]
  if not h then
    h = S.Text(win.content, nil, "LEFT", "OVERLAY", ns.db.headerSize)
    h:SetTextColor(S.LABEL[1], S.LABEL[2], S.LABEL[3])
    win.headers[i] = h
  end
  h:Show()
  return h
end

-- Sections flow left to right and wrap, like words on a line; empties last, full width.
function B:Layout(win)
  local f = win.frame
  if not f:IsShown() then win.dirty = true return end
  if InCombatLockdown() and self.protected then win.dirty = true return end
  win.dirty = false
  local db = ns.db
  local bags = win.kind == "bank" and BankIDs() or BagIDs()
  self.missingNames = false
  local items, empty, total = self:Read(bags)

  local sections = {}
  if db.categories then
    local byCat = {}
    for _, it in ipairs(items) do
      local c = Categorise(it)
      if not byCat[c] then
        byCat[c] = { cat = c, items = {} }
        sections[#sections + 1] = byCat[c]
      end
      table.insert(byCat[c].items, it)
    end
    table.sort(sections, function(a, b) return a.cat.order < b.cat.order end)
  elseif #items > 0 then
    sections[1] = { cat = { label = "Items" }, items = items }
  end
  for _, s in ipairs(sections) do table.sort(s.items, SortItems) end

  local size, gx, gy, cols = db.bagSize, db.gapX, db.gapY, db.bagCols
  local headH = db.headerSize + 6
  local width = cols * size + (cols - 1) * gx
  local x, y, rowH, colUsed = 0, 0, 0, 0
  local used, hi, shown = {}, 0, {}
  local function place(b, px, py)
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", win.content, "TOPLEFT", px, -py)
    b:SetSize(size, size)
    S.GlowSize(b.fuiGlow, size)
    b:Show()
    used[b] = true
  end
  local function grid(list, label, startCol, top, span)
    hi = hi + 1
    local h = self:Header(win, hi)
    h:ClearAllPoints()
    h:SetPoint("TOPLEFT", win.content, "TOPLEFT", startCol * (size + gx), -top)
    h:SetText(label .. "  |cff808080" .. #list .. "|r")
    h:SetWidth(span * (size + gx) - gx)
    local rows = 0
    for i, it in ipairs(list) do
      local b = self:Button(win, it.bag, it.slot)
      if b then
        local c, r = (i - 1) % span, floor((i - 1) / span)
        place(b, (startCol + c) * (size + gx), top + headH + r * (size + gy))
        self:Paint(b, it.bag and it.icon and it or nil)
        shown[#shown + 1] = b
        rows = r + 1
      end
    end
    return headH + rows * (size + gy) - gy
  end

  for _, s in ipairs(sections) do
    local span = min(#s.items, cols)
    if colUsed > 0 and colUsed + 1 + span > cols then
      y = y + rowH + db.sectionGap
      colUsed, rowH = 0, 0
    end
    local start = colUsed > 0 and colUsed + 1 or 0
    local h = grid(s.items, s.cat.label, start, y, span)
    rowH = max(rowH, h)
    colUsed = start + span
  end
  if colUsed > 0 then y = y + rowH + db.sectionGap end
  if #empty > 0 then
    y = y + grid(empty, "Empty", 0, y, cols)
  elseif y > 0 then
    y = y - db.sectionGap
  end

  -- Slots not shown this time (bag swapped out) are hidden.
  for _, list in pairs(win.buttons) do
    for _, b in pairs(list) do
      if not used[b] then b:Hide() end
    end
  end
  for i = hi + 1, #win.headers do win.headers[i]:Hide() end
  win.shown = shown

  win.content:SetSize(width, max(size, y))
  f:SetWidth(width + 2 * PAD)
  f:SetHeight(HEADER_H + PAD - 2 + max(size, y) + PAD + FOOTER_H)
  f.free:SetText(("%d/%d"):format(total - #empty, total))
  f.money:SetText(win.kind == "bags" and Money() or "")
  f.info:SetText(f.buy and f.buy:IsShown() and "" or (#empty .. " free"))
  if f.buy then
    local have, cost = GetNumBankSlots()
    f.buy:SetShown(not cost and have < (NUM_BANKBAGSLOTS or 6))
  end
  self:Search(win, f.search:GetText() or "")
  if self.pendingButtons then self:Retry(win) end
end

-- Created in combat? Try again after.
function B:Retry(win)
  self.retry = self.retry or {}
  self.retry[win] = true
end

function B:Search(win, text)
  text = lower(text or "")
  for _, b in ipairs(win.shown or {}) do
    local it = b.fuiItem
    local match = true
    if text ~= "" then
      match = false
      if it then
        local n = it.name or ""
        if lower(n):find(text, 1, true) then match = true end
        local _, itemType, subType = Instant(it.id or 0)
        if not match and itemType and lower(itemType):find(text, 1, true) then match = true end
        if not match and subType and lower(subType):find(text, 1, true) then match = true end
      end
    end
    b:SetAlpha(match and 1 or 0.18)
  end
end

function B:Refresh()
  for _, win in pairs(self.windows) do
    S.Panel(win.frame)
    for _, h in ipairs(win.headers) do S.SetFont(h, ns.db.headerSize) end
    for _, list in pairs(win.buttons) do
      for _, b in pairs(list) do
        if b.fuiCount then S.SetFont(b.fuiCount, ns.db.countSize, ns.db.outline) end
        S.SetFont(b.fuiLevel, ns.db.countSize - 1, ns.db.outline)
      end
    end
    self:Place(win)
    if win.frame:IsShown() then self:Layout(win) else win.dirty = true end
  end
  if self.settings then self:FillSettings() end
end

------------------------------------------------------------------------
-- Opening and closing (the game's bag functions now open these windows)
------------------------------------------------------------------------

function B:Open()
  local win = self:Window("bags")
  if not win.frame:IsShown() then win.frame:Show() end
end
function B:Close()
  local win = self.windows.bags
  if win and win.frame:IsShown() then win.frame:Hide() end
end
function B:Toggle()
  local win = self:Window("bags")
  if win.frame:IsShown() then self:Close() else self:Open() end
end

function B:TakeOver()
  self.originals = {
    OpenAllBags = OpenAllBags, CloseAllBags = CloseAllBags, ToggleAllBags = ToggleAllBags,
    ToggleBackpack = ToggleBackpack, OpenBackpack = OpenBackpack, CloseBackpack = CloseBackpack,
    ToggleBag = ToggleBag, OpenBag = OpenBag, CloseBag = CloseBag,
  }
  OpenAllBags = function() B:Open() end
  CloseAllBags = function() B:Close() end
  ToggleAllBags = function() B:Toggle() end
  ToggleBackpack = function() B:Toggle() end
  OpenBackpack = function() B:Open() end
  CloseBackpack = function() B:Close() end
  ToggleBag = function(id)
    if B.bankOpen and id and id > EQUIPPED then return end
    B:Toggle()
  end
  OpenBag = function() B:Open() end
  CloseBag = function() end
  IsBagOpen = function(id)
    local win = B.windows.bags
    if id and id > EQUIPPED then
      local bank = B.windows.bank
      return bank and bank.frame:IsShown() or false
    end
    return win and win.frame:IsShown() or false
  end
  -- Blizzard's own bag windows, if something opens them anyway.
  for i = 1, (NUM_CONTAINER_FRAMES or 13) do
    local cf = _G["ContainerFrame" .. i]
    if cf and cf.HookScript then cf:HookScript("OnShow", function(self) self:Hide() end) end
  end
  if ContainerFrameCombinedBags and ContainerFrameCombinedBags.HookScript then
    ContainerFrameCombinedBags:HookScript("OnShow", function(self) self:Hide() end)
  end
end

------------------------------------------------------------------------
-- Settings panel
------------------------------------------------------------------------

local function Cycle(list, current, dir)
  local idx = 1
  for i, v in ipairs(list) do if v.key == current then idx = i end end
  idx = (idx - 1 + dir) % #list + 1
  return list[idx]
end

local SETTINGS = {
  { kind = "step", label = "Columns", key = "bagCols", min = 4, max = 30, step = 1 },
  { kind = "step", label = "Slot size", key = "bagSize", min = 24, max = 64, step = 2 },
  { kind = "step", label = "Horizontal gap", key = "gapX", min = 0, max = 20, step = 1 },
  { kind = "step", label = "Vertical gap", key = "gapY", min = 0, max = 20, step = 1 },
  { kind = "step", label = "Gap between categories", key = "sectionGap", min = 0, max = 40, step = 2 },
  { kind = "cycle", label = "Font", key = "font", list = function() return S.FONTS end },
  { kind = "step", label = "Count size", key = "countSize", min = 8, max = 24, step = 1 },
  { kind = "step", label = "Heading size", key = "headerSize", min = 8, max = 24, step = 1 },
  { kind = "cycle", label = "Text outline", key = "outline", list = function() return S.OUTLINES end },
  { kind = "step", label = "Glow strength", key = "glow", min = 0, max = 1, step = 0.1, fmt = "%.1f" },
  { kind = "step", label = "Opacity", key = "alpha", min = 0, max = 1, step = 0.05, fmt = "%.2f" },
  { kind = "step", label = "Scale", key = "bagScale", min = 0.5, max = 2, step = 0.05, fmt = "%.2f" },
  { kind = "toggle", label = "Categories", key = "categories" },
  { kind = "toggle", label = "Item level on gear", key = "ilvl" },
  { kind = "toggle", label = "Glow on common items", key = "common" },
}
B.SETTINGS = SETTINGS
local ROW = 22

function B:BuildSettings()
  local p = CreateFrame("Frame", "KUIBagSettings", UIParent)
  p:SetFrameStrata("HIGH")
  p:SetClampedToScreen(true)
  p:EnableMouse(true)
  p:SetWidth(250)
  p:SetHeight(HEADER_H + #SETTINGS * ROW + PAD * 2)
  p:Hide()
  S.Panel(p)
  S.Header(p, HEADER_H)
  local t = S.Text(p, nil, "LEFT", nil, 14)
  t:SetPoint("TOPLEFT", 8, -6)
  t:SetText("Bag settings")
  t:SetTextColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3])
  local x = S.Button(p, "x", 20, function() p:Hide() end)
  x:SetPoint("TOPRIGHT", -2, -3)
  p.rows = {}
  for i, def in ipairs(SETTINGS) do
    local r = CreateFrame("Frame", nil, p)
    r:SetPoint("TOPLEFT", 1, -(HEADER_H + PAD + (i - 1) * ROW))
    r:SetPoint("TOPRIGHT", -1, -(HEADER_H + PAD + (i - 1) * ROW))
    r:SetHeight(ROW)
    r.label = S.Text(r, nil, "LEFT", nil, 12)
    r.label:SetPoint("LEFT", 9, 0)
    r.label:SetText(def.label)
    r.label:SetTextColor(0.85, 0.85, 0.85)
    r.value = S.Text(r, nil, "CENTER", nil, 12)
    local function change(dir)
      local db = ns.db
      if def.kind == "step" then
        local v = db[def.key] + dir * def.step
        v = max(def.min, min(def.max, floor(v / def.step + 0.5) * def.step))
        db[def.key] = v
      elseif def.kind == "cycle" then
        db[def.key] = Cycle(def.list(), db[def.key], dir).key
      else
        db[def.key] = not db[def.key]
      end
      if def.key == "font" then S.ApplyFonts() end
      FUI:Refresh()
    end
    if def.kind == "toggle" then
      r.value:SetPoint("RIGHT", -10, 0)
      r.value:SetWidth(90)
      local hit = S.Button(r, "", 90, function() change(1) end)
      hit:SetPoint("RIGHT", -10, 0)
    else
      local plus = S.Button(r, def.kind == "cycle" and ">" or "+", 20, function() change(1) end)
      plus:SetPoint("RIGHT", -8, 0)
      r.value:SetPoint("RIGHT", plus, "LEFT", -2, 0)
      r.value:SetWidth(def.kind == "cycle" and 104 or 44)
      local minus = S.Button(r, def.kind == "cycle" and "<" or "-", 20, function() change(-1) end)
      minus:SetPoint("RIGHT", r.value, "LEFT", -2, 0)
    end
    r.def = def
    p.rows[i] = r
  end
  self.settings = p
  self:FillSettings()
end

function B:FillSettings()
  local db = ns.db
  for _, r in ipairs(self.settings.rows) do
    local def, v = r.def, db[r.def.key]
    if def.kind == "step" then
      r.value:SetText(def.fmt and def.fmt:format(v) or tostring(v))
    elseif def.kind == "cycle" then
      local name = tostring(v)
      for _, it in ipairs(def.list()) do if it.key == v then name = it.name end end
      r.value:SetText(name)
    else
      r.value:SetText(v and "|cff7fc8ffOn|r" or "|cff808080Off|r")
    end
  end
end

function B:ToggleSettings()
  if not self.settings then self:BuildSettings() end
  local p, bags = self.settings, self.windows.bags.frame
  if p:IsShown() then p:Hide() return end
  p:ClearAllPoints()
  p:SetPoint("TOPRIGHT", bags, "TOPLEFT", -6, 0)
  self:FillSettings()
  p:Show()
end

------------------------------------------------------------------------
-- Events
------------------------------------------------------------------------

local function LayoutShown()
  for _, win in pairs(B.windows) do
    if win.frame:IsShown() then B:Layout(win) else win.dirty = true end
  end
end

local pendingLayout
local function LayoutSoon(delay)
  if pendingLayout then return end
  pendingLayout = true
  C_Timer.After(delay or 0.05, function()
    pendingLayout = false
    LayoutShown()
  end)
end

function B:Enable()
  local loaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
  if loaded and loaded("Baganator") then
    FUI:Print("Bags: Baganator is on, so kUI bags are staying out of the way. Untick Baganator (and Baganator Sleek) to use them.")
    return
  end
  self.enabled = true
  local win = self:Window("bags")
  -- Make every slot now, out of combat.
  for _, bag in ipairs(BagIDs()) do
    for slot = 1, NumSlots(bag) do self:Button(win, bag, slot) end
  end
  local any = next(win.buttons[0] or {}) and win.buttons[0][1]
  self.protected = any and any.IsProtected and any:IsProtected() or false
  self:TakeOver()

  local ev = CreateFrame("Frame")
  for _, e in ipairs({ "BAG_UPDATE", "BAG_UPDATE_DELAYED", "ITEM_LOCK_CHANGED", "BAG_UPDATE_COOLDOWN",
                       "PLAYER_MONEY", "GET_ITEM_INFO_RECEIVED", "QUEST_ACCEPTED", "QUEST_REMOVED",
                       "BAG_NEW_ITEMS_UPDATED", "PLAYER_REGEN_ENABLED", "PLAYERBANKSLOTS_CHANGED",
                       "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "INVENTORY_SEARCH_UPDATE" }) do
    pcall(ev.RegisterEvent, ev, e)
  end
  if ns.db.bank and BankFrame then
    pcall(BankFrame.UnregisterEvent, BankFrame, "BANKFRAME_OPENED")
    self.ownBank = true
  end
  ev:SetScript("OnEvent", function(_, event, a1, a2)
    if event == "BAG_UPDATE_DELAYED" or event == "BAG_NEW_ITEMS_UPDATED" or event == "QUEST_ACCEPTED"
       or event == "QUEST_REMOVED" or event == "PLAYERBANKSLOTS_CHANGED" then
      LayoutSoon()
    elseif event == "BAG_UPDATE" then
      for _, w in pairs(B.windows) do w.dirty = true end
    elseif event == "ITEM_LOCK_CHANGED" then
      if a1 and a2 then
        for _, w in pairs(B.windows) do
          local b = w.buttons[a1] and w.buttons[a1][a2]
          if b and b.fuiItem then
            local info = ItemInfo(a1, a2)
            SetItemButtonDesaturated(b, info and info.isLocked)
          end
        end
      end
    elseif event == "BAG_UPDATE_COOLDOWN" then
      for _, w in pairs(B.windows) do
        for _, b in ipairs(w.shown or {}) do B:PaintCooldown(b) end
      end
    elseif event == "PLAYER_MONEY" then
      local w = B.windows.bags
      if w then w.frame.money:SetText(Money()) end
    elseif event == "GET_ITEM_INFO_RECEIVED" then
      if B.missingNames then LayoutSoon(0.3) end
    elseif event == "PLAYER_REGEN_ENABLED" then
      if B.pendingButtons then
        B.pendingButtons = false
        LayoutShown()
      else
        for _, w in pairs(B.windows) do if w.dirty and w.frame:IsShown() then B:Layout(w) end end
      end
    elseif event == "BANKFRAME_OPENED" and B.ownBank then
      B.bankOpen = true
      local bank = B:Window("bank")
      bank.frame:Show()
      B:Open()
    elseif event == "BANKFRAME_CLOSED" and B.ownBank then
      B.bankOpen = false
      local bank = B.windows.bank
      if bank and bank.frame:IsShown() then bank.frame:Hide() end
    end
  end)
end

FUI:Register(B)

-- /kui bags ...
function B:Slash(arg)
  local db = ns.db
  local k, v = (arg or ""):match("^(%S*)%s*(.-)$")
  local n = tonumber(v)
  local map = { cols = "bagCols", columns = "bagCols", size = "bagSize", gapx = "gapX", gapy = "gapY",
                gap = "gap", sections = "sectionGap", count = "countSize", heading = "headerSize", scale = "bagScale" }
  if k == "" then
    if self.enabled then self:Open(); self:ToggleSettings() else FUI:Print("Bags are off. /kui bags on, then /reload.") end
    return
  end
  if k == "gap" and n then
    db.gapX, db.gapY = n, n
  elseif map[k] and n then
    db[map[k]] = n
  elseif k == "categories" or k == "ilvl" then
    db[k] = not db[k]
  elseif k == "reset" then
    for key, val in pairs(FUI.defaults) do
      if key:find("^bag") or key:find("^gap") or key:find("^bank") or key == "sectionGap" or key == "categories"
         or key == "ilvl" or key == "countSize" or key == "headerSize" or key == "outline" then
        db[key] = val
      end
    end
  else
    FUI:Print("/kui bags (settings) · cols 10 · size 36 · gapx 4 · gapy 4 · gap 4 · sections 10 · count 12 · heading 12 · scale 1 · categories · ilvl · reset")
    return
  end
  FUI:Refresh()
  FUI:Print("bags: %d columns, %d px slots, gaps %d x %d.", db.bagCols, db.bagSize, db.gapX, db.gapY)
end
