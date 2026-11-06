-- Stubbed WoW environment for kUI. Run: texlua tests/kui_test.lua KUI
local DIR = arg[1]
function wipe(t) for k in pairs(t) do t[k] = nil end return t end
local unpack = table.unpack
local passed, failed, errors = 0, 0, {}
local function check(c, label) if c then passed = passed + 1 else failed = failed + 1; print("  FAIL: " .. label) end end
local timers = {}
C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end }
local function runTimers() local t = timers; timers = {}; for _, fn in ipairs(t) do fn() end end

local Mock = {}
local Meta = { __index = function(t, k)
  if Mock[k] ~= nil then return Mock[k] end
  if type(k) == "string" and k:match("^%u") then return function() end end
end }
local eventFrames = {}
local function new(kind, name, parent)
  local m = setmetatable({ kind = kind, scripts = {}, shown = true, alpha = 1, regions = {}, points = {}, parent = parent, level = 1, events = {} }, Meta)
  if name then _G[name] = m end
  return m
end
function Mock:SetScript(k, fn) self.scripts[k] = fn end
function Mock:HookScript(k, fn) local o = self.scripts[k]; self.scripts[k] = function(...) if o then o(...) end; fn(...) end end
function Mock:Show() if not self.shown then self.shown = true; if self.scripts.OnShow then self.scripts.OnShow(self) end end end
function Mock:Hide() if self.shown then self.shown = false; if self.scripts.OnHide then self.scripts.OnHide(self) end end end
function Mock:IsShown() return self.shown end
function Mock:SetShown(v) if v then self:Show() else self:Hide() end end
function Mock:SetAlpha(a) self.alpha = a end
function Mock:SetText(t) self.text = t end
function Mock:GetText() return self.text end
function Mock:SetTextColor(r, g, b) self.color = { r, g, b } end
function Mock:SetColorTexture(r, g, b, a) self.ctex = { r, g, b, a } end
function Mock:SetTexture(t) self.tex = t end
function Mock:SetDesaturated(v) self.desat = v end
function Mock:SetGradient(o, a, b) self.grad = { o, a, b } end
function Mock:SetHeight(h) self.h = h end
function Mock:SetWidth(w) self.w = w end
function Mock:GetWidth() return self.w or 0 end
function Mock:GetHeight() return self.h or 0 end
function Mock:SetSize(w, h) self.w, self.h = w, h end
function Mock:SetPoint(...) table.insert(self.points, { ... }) end
function Mock:ClearAllPoints() self.points = {} end
function Mock:GetLeft() return 300 end
function Mock:GetTop() return 600 end
function Mock:GetEffectiveScale() return 1 end
function Mock:GetFrameLevel() return self.level end
function Mock:SetFrameLevel(l) self.level = l end
function Mock:IsObjectType(k) return self.kind == k end
function Mock:GetRegions() return unpack(self.regions) end
function Mock:CreateTexture(_, layer) local t = new("Texture", nil, self); t.layer = layer; table.insert(self.regions, t); return t end
function Mock:CreateFontString() local t = new("FontString", nil, self); t.text = ""; return t end
function Mock:RegisterEvent(e) self.events[e] = true; eventFrames[e] = eventFrames[e] or {}; table.insert(eventFrames[e], self) end
function Mock:UnregisterEvent(e) self.events[e] = nil; for i, f in ipairs(eventFrames[e] or {}) do if f == self then table.remove(eventFrames[e], i) break end end end
function Mock:SetMaskTexture(t) self.mask = t end
function Mock:GetZoom() return self.zoom or 0 end
function Mock:SetZoom(z) self.zoom = z end
function Mock:GetZoomLevels() return 6 end
function Mock:StartMoving() end
function Mock:StopMovingOrSizing() end
function CreateFrame(kind, name, parent) return new(kind, name, parent) end
local function fire(e, ...) for _, f in ipairs(eventFrames[e] or {}) do if f.events[e] then f.scripts.OnEvent(f, e, ...) end end end
function hooksecurefunc(t, k, fn) local o = t[k]; t[k] = function(...) local r = { o(...) }; fn(...); return unpack(r) end end
function CreateColor(r, g, b, a) return { r = r, g = g, b = b, a = a } end
UIParent = new("Frame", "UIParent")
GameTooltip = new("GameTooltip")
function GameTooltip:SetLootItem(slot) self.lootSlot = slot end
UISpecialFrames = {}
local chat = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) chat[#chat + 1] = m end }
SlashCmdList = {}
ITEM_QUALITY_COLORS = { [0] = { r = 0.62, g = 0.62, b = 0.62 }, [1] = { r = 1, g = 1, b = 1 }, [2] = { r = 0.12, g = 1, b = 0 }, [3] = { r = 0, g = 0.44, b = 0.87 }, [4] = { r = 0.64, g = 0.21, b = 0.93 } }
Enum = { LootSlotType = { None = 0, Item = 1, Money = 2, Currency = 3 } }

-- Loot
local loot = {}
local looted, closed = {}, 0
function GetNumLootItems() return #loot end
function LootSlotHasItem(i) return loot[i] ~= nil and not loot[i].gone end
function GetLootSlotInfo(i) local l = loot[i]; if not l or l.gone then return nil end; return l.icon, l.name, l.count, nil, l.q, l.locked, l.quest, l.qid, l.active end
function GetLootSlotType(i) return loot[i] and loot[i].money and 2 or 1 end
function GetLootSlotLink(i) return "|Hitem:" .. i .. "|h" end
function LootSlot(i) looted[#looted + 1] = i end
function CloseLoot() closed = closed + 1 end
local modified, handledLink = false, nil
function IsModifiedClick() return modified end
function HandleModifiedItemClick(l) handledLink = l; return true end
local cvar = false
function GetCVarBool() return cvar end
function GetCursorPosition() return 500, 400 end
function UnitExists() return true end
function UnitIsDead() return true end
function UnitName() return "Mottled Boar" end
function GetItemInfo(id) return "Item" .. id, nil, id == 774 and 2 or 1, nil, nil, nil, nil, nil, nil, "icon" .. id end
LootFrame = new("Frame", "LootFrame")
for _, e in ipairs({ "LOOT_OPENED", "LOOT_SLOT_CLEARED", "LOOT_SLOT_CHANGED", "LOOT_CLOSED", "OPEN_MASTER_LOOT_LIST" }) do LootFrame:RegisterEvent(e) end
LootFrame.scripts.OnEvent = function() LootFrame.blizzShown = true end

-- Minimap world
Minimap = new("Minimap", "Minimap")
MinimapCluster = new("Frame", "MinimapCluster")
local hideNames = { "MinimapBorder", "MinimapBorderTop", "MinimapZoomIn", "MinimapZoomOut", "MiniMapWorldMapButton", "MinimapZoneTextButton", "GameTimeFrame", "MinimapToggleButton" }
for _, n in ipairs(hideNames) do new("Frame", n) end
MinimapBackdrop = new("Frame", "MinimapBackdrop")
local backdropArt = MinimapBackdrop:CreateTexture()
MiniMapMailFrame = new("Frame", "MiniMapMailFrame")
MiniMapTrackingFrame = new("Frame", "MiniMapTrackingFrame")
function GetZonePVPInfo() return "friendly" end
function GetMinimapZoneText() return "Razor Hill" end
C_Map = { GetBestMapForUnit = function() return 1411 end, GetPlayerMapPosition = function() return { x = 0.523, y = 0.414 } end }
local worldMap = 0
function ToggleWorldMap() worldMap = worldMap + 1 end
local trackingMenu
MiniMapTrackingDropDown = {}
function ToggleDropDownMenu(_, _, menu, anchor) trackingMenu = anchor end


-- Bags world
function Mock:SetID(i) self.id = i end
function Mock:GetID() return self.id end
function Mock:SetFont(path, size, flags) self.font = { path, size, flags } end
function Mock:GetFont() return self.font and self.font[1] end
function Mock:SetDrawLayer(l, s) self.layer = l; self.sub = s end
function Mock:GetAlpha() return self.alpha end
function Mock:GetHighlightTexture() self.hlTex = self.hlTex or new("Texture"); return self.hlTex end
function Mock:GetPushedTexture() self.pushTex = self.pushTex or new("Texture"); return self.pushTex end
function Mock:ClearNormalTexture() self.normalCleared = true end
function Mock:IsProtected() return false end
function Mock:GetObjectType() return self.kind end
function Mock:SetAttribute(k, v) self.attrs = self.attrs or {}; self.attrs[k] = v end
function Mock:SetUnit(u) self.modelUnit = u end
function Mock:SetCreature(id) self.modelCreature = id end
function Mock:SetScale(s) self.scale = s end
local baseCreate = CreateFrame
function CreateFrame(kind, name, parent, template)
  local f = baseCreate(kind, name, parent)
  if template == "ContainerFrameItemButtonTemplate" then
    f.icon = f:CreateTexture()
    f.Count = f:CreateFontString()
    f.IconBorder = f:CreateTexture()
    f.Cooldown = new("Cooldown")
    f.template = true
  end
  return f
end
function SetItemButtonTexture(b, t) b.icon.tex = t end
function SetItemButtonCount(b, c) b.Count.text = (c and c > 1) and tostring(c) or "" end
function SetItemButtonDesaturated(b, d) b.desat = d end
function CooldownFrame_Set(cd, s, d, e) cd.cd = { s, d, e } end
local inCombat = false
function InCombatLockdown() return inCombat end
C_AddOns = { IsAddOnLoaded = function(n) return false end }
NUM_BAG_SLOTS, NUM_BANKBAGSLOTS, BANK_CONTAINER = 4, 6, -1
local BAGS = { [0] = {}, [1] = {}, [-1] = {} }
local SIZES = { [0] = 16, [1] = 10, [2] = 0, [3] = 0, [4] = 0, [-1] = 24 }
local ITEMS = {
  [6948] = { "Hearthstone", 15, 0, 1 }, [2589] = { "Linen Cloth", 7, 5, 1 }, [774] = { "Malachite", 7, 7, 2 },
  [818] = { "Tigerseye", 7, 7, 2 }, [25] = { "Worn Shortsword", 2, 7, 1 }, [2138] = { "Sharpened Letter Opener", 2, 15, 2 },
  [117] = { "Tough Jerky", 0, 0, 1 }, [4865] = { "Ruined Pelt", 15, 0, 0 }, [5571] = { "Small Black Pouch", 1, 0, 1 },
  [4881] = { "Aged Envelope", 12, 0, 1 }, [6145] = { "Clarice's Pendant", 4, 2, 4 },
}
local function put(bag, slot, id, count, extra)
  local d = ITEMS[id]
  BAGS[bag][slot] = { iconFileID = "icon" .. id, stackCount = count or 1, quality = d[4], itemID = id, hyperlink = "item:" .. id, isLocked = false }
  if extra then for k, v in pairs(extra) do BAGS[bag][slot][k] = v end end
end
put(0, 1, 6948); put(0, 2, 2589, 12); put(0, 3, 774); put(0, 4, 25); put(0, 5, 117, 5); put(0, 6, 4865, 2)
put(0, 8, 2138); put(0, 9, 818); put(1, 1, 5571); put(1, 3, 4881, 1, { quest = { isQuestItem = true, questID = 123, isActive = false } }); put(1, 4, 6145)
C_Container = {
  GetContainerNumSlots = function(b) return SIZES[b] or 0 end,
  GetContainerItemInfo = function(b, s) return BAGS[b] and BAGS[b][s] end,
  GetContainerItemQuestInfo = function(b, s) local i = BAGS[b] and BAGS[b][s]; return i and i.quest or { isQuestItem = false } end,
  GetContainerItemCooldown = function() return 0, 0, 1 end,
  SortBags = function() sorted = true end,
}
C_Item = {
  GetItemInfoInstant = function(id) local d = ITEMS[id]; if not d then return nil end; return id, d[2] == 7 and "Trade Goods" or "Thing", d[2] == 7 and "Metal & Stone" or "Sub", "", "icon", d[2], d[3] end,
  GetItemInfo = function(id) local d = ITEMS[id]; return d and d[1] end,
  GetDetailedItemLevelInfo = function() return 11 end,
}
function GetMoney() return 123456 end
function GetCoinTextureString(m) return "12g 34s 56c" end
local bankClosed = 0
function CloseBankFrame() bankClosed = bankClosed + 1 end
BankFrame = new("Frame", "BankFrame")
BankFrame:RegisterEvent("BANKFRAME_OPENED")
BankFrame.scripts.OnEvent = function() BankFrame.blizzOpened = true end
ContainerFrame1 = new("Frame", "ContainerFrame1")
PlaySound = function() end

-- Tooltips world
GameTooltip.NineSlice = new("Frame")
function GameTooltip:GetName() return "GameTooltip" end
GameTooltip.nlines = 0
function GameTooltip:NumLines() return self.nlines end
function GameTooltip:AddDoubleLine(a, b) self.dlines = self.dlines or {}; table.insert(self.dlines, { a, b }) end
local tipItem
function GameTooltip:GetItem() return tipItem and tipItem[1], tipItem and tipItem[2] end
ItemRefTooltip = new("GameTooltip", "ItemRefTooltip")
ItemRefTooltip.SetBackdropColor = function(self, r, g, b, a) self.bd = { r, g, b, a } end
ItemRefTooltip.SetBackdropBorderColor = function(self, r, g, b, a) self.bdb = { r, g, b, a } end
GameTooltipStatusBar = new("StatusBar", "GameTooltipStatusBar")
GameTooltipStatusBar.SetStatusBarTexture = function(self, t) self.sbt = t end
GameTooltipHeaderText = new("Font", "GameTooltipHeaderText")
GameTooltipText = new("Font", "GameTooltipText")
GameTooltipTextSmall = new("Font", "GameTooltipTextSmall")
Enum.TooltipDataType = { Item = 0 }
local postCalls = {}
TooltipDataProcessor = { AddTooltipPostCall = function(kind, fn) table.insert(postCalls, fn) end }
GoldForever = { db = { drops = {
  n3129 = { name = "Kul Tiras Marine", loots = 10, it = { ["5469"] = { seen = 1 }, ["2589"] = { seen = 4 } } },
  n3128 = { name = "Kul Tiras Sailor", loots = 23, it = { ["2589"] = { seen = 6 } } },
  o106318 = { name = "Node: Refreshing Spring Water", loots = 4, it = { ["2589"] = { seen = 2 } } },
} } }
-- load
local ns = {}
for line in io.lines(DIR .. "/KUI.toc") do
  if line:match("%.lua$") then assert(loadfile(DIR .. "/" .. line))("KUI", ns) end
end
fire("ADDON_LOADED", "KUI")
fire("PLAYER_LOGIN")
check(KUIDB and KUIDB.alpha == 0.85 and KUIDB.loot and KUIDB.map, "defaults")

print("== Loot")
local f = KUILoot
check(f and not f.shown, "loot window made, hidden")
check(not LootFrame.events.LOOT_OPENED and LootFrame.events.OPEN_MASTER_LOOT_LIST, "Blizzard's loot window stops listening (master loot untouched)")
check(UISpecialFrames[1] == "KUILoot", "Esc closes it")
check(f.fuiPanel.fill.ctex[1] == 0.04 and f.fuiPanel.edges[1].ctex[1] == 0.35, "QuestDirect colours")
loot = {
  { icon = "i1", name = "Ruined Leather Scraps", count = 1, q = 1 },
  { icon = "i2", name = "Malachite", count = 1, q = 2 },
  { icon = "c", name = "12 Copper\n", money = true },
  { icon = "i4", name = "Scorpid Tail", count = 3, q = 1, quest = true },
  { icon = "i5", name = "Grimy Note", count = 1, q = 1, quest = true, qid = 900, active = false },
  { icon = "i6", name = "Sword", count = 1, q = 4, locked = true },
}
fire("LOOT_OPENED")
check(f.shown and not LootFrame.blizzShown, "opens on loot, Blizzard's stays closed")
check(f.title.text == "Mottled Boar", "title is the corpse's name")
local L = ns.Loot
local r = L.rows
check(r[1].name.text == "Ruined Leather Scraps" and r[1].name.color[1] == 1, "common item, white name")
check(r[2].name.color[2] == 1 and r[2].glow.edges[1].ctex[2] == 1 and r[2].glow.glow[1].shown ~= false, "uncommon: green name, outline and glow")
check(r[1].glow.edges[1].ctex[1] == 0.35 and r[1].glow.glow[1].shown == false, "common: no glow by default")
check(r[3].name.text == "12 Copper ", "coins on one line")
check(r[4].tag.text:find("Quest") and r[4].count.text == 3, "quest item tagged, stack count")
check(r[5].tag.text:find("Starts a quest"), "quest starters tagged")
check(r[6].icon.desat and r[6].name.color[1] == 0.6, "locked items dimmed")
check(r[6].glow.edges[1].ctex[1] == 0.64, "epic purple outline")
check(f.h == 24 + 2 + 6 * 30 + 4, "height fits the rows: " .. tostring(f.h))
r[2].scripts.OnClick(r[2])
check(looted[#looted] == 2, "click loots the slot")
modified = true
r[2].scripts.OnClick(r[2])
modified = false
check(handledLink and handledLink:find("item:2"), "shift-click links")
r[1].scripts.OnEnter(r[1])
check(GameTooltip.lootSlot == 1, "tooltip")
loot[2].gone = true
fire("LOOT_SLOT_CLEARED", 2)
check(#L:Read() == 5 and r[6].shown == false and r[2].name.text == "Coins" or r[2].name.text == "12 Copper ", "cleared slot drops out, rest move up")
looted = {}
f.all.scripts.OnClick(f.all)
check(#looted == 4, "All loots everything not locked (" .. #looted .. ")")
f.close.scripts.OnClick(f.close)
check(closed == 1, "x closes loot")
fire("LOOT_CLOSED")
check(not f.shown and closed == 1, "closes with the game, no double close")
fire("LOOT_OPENED")
f:Hide() -- Esc
check(closed == 2, "Esc closes loot")
fire("LOOT_CLOSED")
cvar = true
fire("LOOT_OPENED")
local p = f.points[1]
check(p and p[4] == 470, "under the mouse when that option is on")
fire("LOOT_CLOSED")
loot = {}
SlashCmdList.KUI("test")
check(f.shown and f.title.text == "Sample loot" and #L.rows >= 10, "/fui test shows a sample")
local c0 = closed
r[1].scripts.OnClick(r[1])
check(#looted == 4, "sample rows don't loot")
f:Hide()
check(closed == c0, "closing the sample doesn't touch real loot")

-- auto loot: nothing shows until what's left is known
loot = { { icon = "i1", name = "Linen Cloth", count = 1, q = 1 } }
fire("LOOT_OPENED", true)
check(not f.shown, "auto loot: no flash of the window")
loot[1].gone = true
runTimers()
check(not f.shown, "auto loot took it all: window never shows")
fire("LOOT_CLOSED")
loot = { { icon = "i1", name = "Linen Cloth", count = 1, q = 1, locked = true } }
fire("LOOT_OPENED", true)
runTimers()
check(f.shown, "auto loot left something: window shows it")
fire("LOOT_CLOSED")
print("== Minimap"); for _, m in ipairs(chat) do print("  chat: " .. m) end
check(Minimap.mask == "Interface\\Buttons\\WHITE8X8", "square mask")
check(GetMinimapShape() == "SQUARE", "other add-ons see a square map")
check(MinimapBorder.shown == false and MinimapZoomIn.shown == false and MinimapZoneTextButton.shown == false and GameTimeFrame.shown == false, "round border, zoom, zone banner, clock hidden")
MinimapZoomIn:Show()
check(MinimapZoomIn.shown == false, "and stay hidden")
check(backdropArt.alpha == 0 and MinimapBackdrop.shown, "round art faded, its buttons kept")
check(MiniMapMailFrame.shown and MiniMapMailFrame.points[1][1] == "TOPRIGHT", "mail icon kept, in the corner")
local strip = KUIMinimapStrip
ns.Minimap:UpdateText()
check(strip.zone.text == "Razor Hill" and strip.zone.color[2] == 1, "zone in its PvP colour")
check(strip.coords.text == "52.3, 41.4", "coordinates: " .. tostring(strip.coords.text))
strip.scripts.OnClick(strip)
check(worldMap == 1, "click the strip for the world map")
Minimap.scripts.OnMouseWheel(Minimap, 1)
check(Minimap.zoom == 1, "wheel zooms in")
Minimap.scripts.OnMouseWheel(Minimap, -1); Minimap.scripts.OnMouseWheel(Minimap, -1)
check(Minimap.zoom == 0, "and out, not past the limit")
Minimap.scripts.OnMouseUp(Minimap, "RightButton")
check(trackingMenu == "cursor", "right-click opens tracking")
check(#ns.Minimap.edges == 4 and ns.Minimap.edges[1].ctex[1] == 0.35, "1px border")

print("== Bags")
local Bg = ns.Bags
check(Bg.enabled, "bags enabled")
local bagsWin = Bg.windows.bags
local bf = KUIBags
check(bf and not bf.shown, "bag window made, hidden")
local made = 0
for bag, list in pairs(bagsWin.buttons) do for _ in pairs(list) do made = made + 1 end end
check(made == 26, "a button for every slot, made at login: " .. made)
local b02 = bagsWin.buttons[0][2]
check(b02.template and b02.id == 2 and b02.parent.id == 0, "the game's own container buttons: slot id, bag id on the holder")
check(b02.normalCleared and b02.IconBorder.alpha == 0, "slot art and Blizzard border gone")
ToggleAllBags()
check(bf.shown, "B opens the bag window")
local function posOf(b) local p = b.points[#b.points]; return p[4], -p[5] end
local labels = {}
for i, h in ipairs(bagsWin.headers) do if h.shown then labels[#labels + 1] = (h.text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end end
print("  sections: " .. table.concat(labels, " | "))
check(labels[1]:find("^New") == nil and labels[1]:find("Quest"), "quest items first")
check(labels[#labels]:find("^Empty") and labels[#labels]:find("15"), "every empty slot at the bottom: " .. labels[#labels])
local order = {}
for _, l in ipairs(labels) do order[#order + 1] = l:match("^(%S+)") end
local want = { "Quest", "Equipment", "Consumables", "Trade", "Bags", "Miscellaneous", "Junk", "Empty" }
check(table.concat(order, ",") == table.concat(want, ","), "category order: " .. table.concat(order, ","))
-- empties after everything
local emptyTop = math.huge
local itemBottom = 0
for _, b in ipairs(bagsWin.shown) do
  local _, y = posOf(b)
  if b.fuiItem then itemBottom = math.max(itemBottom, y) else emptyTop = math.min(emptyTop, y) end
end
check(emptyTop > itemBottom, "empty slots below all items")
-- gaps
local db = KUIDB
local trade = {}
for _, b in ipairs(bagsWin.shown) do if b.fuiItem and b.fuiItem.classID == 7 then trade[#trade + 1] = b end end
local x1, y1 = posOf(trade[1]); local x2, y2 = posOf(trade[2])
check(x2 - x1 == db.bagSize + db.gapX and y1 == y2, "horizontal gap between slots")
local empties = {}
for _, b in ipairs(bagsWin.shown) do if not b.fuiItem then empties[#empties + 1] = b end end
local ex1, ey1 = posOf(empties[1]); local ex11, ey11 = posOf(empties[11])
check(ey11 - ey1 == db.bagSize + db.gapY and ex11 == ex1, "vertical gap between rows")
-- flow: small categories share a row
local rowsY = {}
for i, h in ipairs(bagsWin.headers) do if h.shown then local p = h.points[#h.points]; rowsY[-p[5]] = (rowsY[-p[5]] or 0) + 1 end end
local shared = false
for _, n in pairs(rowsY) do if n > 1 then shared = true end end
check(shared, "small categories sit side by side")
-- glow
local epic, quest
for _, b in ipairs(bagsWin.shown) do
  if b.fuiItem and b.fuiItem.quality == 4 then epic = b end
  if b.fuiItem and b.fuiItem.starts then quest = b end
end
check(epic and epic.fuiGlow.edges[1].ctex[1] == 0.64 and epic.fuiGlow.glow[1].shown ~= false, "epic: purple outline and glow")
check(quest and quest.fuiMark.text:find("!"), "quest starters marked")
check(b02.Count.text == "12" and b02.Count.font and b02.Count.font[1]:find("Barlow") and b02.Count.font[3] == "OUTLINE", "stack count in the bag font, outlined")
check(bf.money.text == "12g 34s 56c" and bf.free.text == "11/26", "money and slots used: " .. bf.free.text)
check(bf.w == db.bagCols * db.bagSize + (db.bagCols - 1) * db.gapX + 16, "window width from columns, size and gaps")
-- search
bf.search:SetText("mala")
bf.search.scripts.OnTextChanged(bf.search)
local bright, dim = 0, 0
for _, b in ipairs(bagsWin.shown) do if b.alpha == 1 then bright = bright + 1 else dim = dim + 1 end end
check(bright == 1 and dim == #bagsWin.shown - 1, "search dims everything else")
bf.search:SetText("metal")
bf.search.scripts.OnTextChanged(bf.search)
bright = 0
for _, b in ipairs(bagsWin.shown) do if b.alpha == 1 then bright = bright + 1 end end
check(bright == 3, "search matches item types too")
bf.search:SetText(""); bf.search.scripts.OnTextChanged(bf.search)
-- settings
SlashCmdList.KUI("bags gapx 8")
local nx1 = posOf(trade[1]); local nx2 = posOf(trade[2])
check(nx2 - nx1 == db.bagSize + 8, "/fui bags gapx changes the horizontal gap live")
SlashCmdList.KUI("bags gapy 10")
local _, a1 = posOf(empties[1]); local _, a11 = posOf(empties[11])
check(a11 - a1 == db.bagSize + 10, "/fui bags gapy changes the vertical gap live")
SlashCmdList.KUI("bags cols 8")
check(bf.w == 8 * db.bagSize + 7 * 8 + 16, "columns")
SlashCmdList.KUI("bags")
local panel = KUIBagSettings
check(panel and panel.shown and #panel.rows == #Bg.SETTINGS, "settings panel opens")
local fontRow
for _, r in ipairs(panel.rows) do if r.def.key == "font" then fontRow = r end end
check(fontRow.value.text == "Barlow", "font row shows the font")
-- press > on the font row
local plus
for _, r in ipairs(panel.rows) do if r.def.key == "gapY" then end end
db.font = "rajdhani"; ns.Style.ApplyFonts(); ns.FUI:Refresh()
check(b02.Count.font[1]:find("Rajdhani") and bf.title.font[1]:find("Rajdhani"), "changing the font restyles everything")
check(fontRow.value.text == "Rajdhani", "panel follows")
SlashCmdList.KUI("font chakra")
check(db.font == "chakra" and b02.Count.font[1]:find("ChakraPetch"), "/fui font")
SlashCmdList.KUI("bags categories")
labels = {}
for i, h in ipairs(bagsWin.headers) do if h.shown then labels[#labels + 1] = h.text:match("^(%S+)") end end
check(table.concat(labels, ",") == "Items,Empty", "categories off: one grid, empties last")
SlashCmdList.KUI("bags categories")
SlashCmdList.KUI("bags reset")
check(db.gapX == 4 and db.bagCols == 10, "bags reset")
-- item moves
BAGS[0][7] = BAGS[0][2]; BAGS[0][2] = nil
fire("BAG_UPDATE", 0); fire("BAG_UPDATE_DELAYED"); runTimers()
check(bagsWin.buttons[0][7].fuiItem and not bagsWin.buttons[0][2].fuiItem, "moves show up")
-- close
ToggleAllBags()
check(not bf.shown and not panel.shown, "B closes it (and the settings)")
OpenAllBags()
check(bf.shown, "merchant/mail open the bags")
CloseAllBags()
check(not bf.shown, "and close them")
ContainerFrame1:Hide(); ContainerFrame1:Show()
check(not ContainerFrame1.shown, "Blizzard's bag windows stay shut")
-- bank
fire("BANKFRAME_OPENED")
local bk = KUIBank
check(bk and bk.shown and bf.shown and not BankFrame.blizzOpened, "bank opens ours (and the bags)")
check(bk.free.text == "0/24", "bank slots: " .. bk.free.text)
bk:Hide()
check(bankClosed == 1, "closing our bank closes the banker")
fire("BANKFRAME_CLOSED")
check(bankClosed == 1, "no double close")

print("== Rares")
local Ra = ns.Rares
check(Ra.enabled and KUIRareAlert and not KUIRareAlert.shown, "rare scanner on, alert hidden")
-- fake Durotar for placing spawn points
local Z = { xs = -1500, xn = 1300, yw = -3600, ye = -6000 }
function CreateVector2D(x, y) return { x = x, y = y } end
C_Map.GetMapInfo = function(m) return ({ [1411] = { name = "Durotar", mapType = 3, parentMapID = 1414 }, [1414] = { name = "Kalimdor", mapType = 2 } })[m] end
C_Map.GetWorldPosFromMapPos = function(m, v)
  if m == 1414 then return 1, { x = 12000 - v.y * 24000, y = 12000 - v.x * 24000 } end
  if m == 1411 then return 1, { x = Z.xn - v.y * (Z.xn - Z.xs), y = Z.yw - v.x * (Z.yw - Z.ye) } end
end
C_Map.GetMapPosFromWorldPos = function(inst, v, m)
  if inst ~= 1 then return nil end
  if m == 1414 then return m, { x = (12000 - v.y) / 24000, y = (12000 - v.x) / 24000 } end
  if m == 1411 then return m, { x = (Z.yw - v.y) / (Z.yw - Z.ye), y = (Z.xn - v.x) / (Z.xn - Z.xs) } end
end
C_Map.GetMapInfoAtPosition = function(m, cx, cy)
  local wx, wy = 12000 - cy * 24000, 12000 - cx * 24000
  if wx >= Z.xs and wx <= Z.xn and wy <= Z.yw and wy >= Z.ye then return { mapID = 1411, mapType = 3 } end
end
C_Map.GetPlayerMapPosition = function() return { x = 0.5, y = 0.5 } end
-- world map
local canvas = new("Frame")
canvas.w, canvas.h = 1000, 667
WorldMapFrame = new("Frame", "WorldMapFrame")
WorldMapFrame.ScrollContainer = new("Frame")
function WorldMapFrame:GetCanvas() return canvas end
function WorldMapFrame:GetMapID() return 1411 end
function WorldMapFrame.OnMapChanged() end
Ra:SetupMap()
Ra:PlaceAll()
check(Ra.spots[5808] and #Ra.spots[5808] == 3 and Ra.spots[5808][1].m == 1411, "Classic rare spawns placed: Warlord Kolkanis in Durotar")
local pins = 0
for _, p in ipairs(Ra.wm.pins) do if p.shown then pins = pins + 1 end end
check(pins >= 3, "spawn points pinned on the world map (" .. pins .. ")")
GameTooltip.lines = {}; function GameTooltip:AddLine(t) table.insert(self.lines, t) end
Ra.wm.pins[1].scripts.OnEnter(Ra.wm.pins[1])
check(#GameTooltip.lines >= 2, "pin tooltip")

-- a rare nameplate appears
local units = {}
function UnitExists(u) return units[u] ~= nil end
function UnitIsPlayer() return false end
function UnitClassification(u) return units[u] and units[u].class end
function UnitGUID(u) return units[u] and ("Creature-0-1-1-1-" .. units[u].id .. "-0") end
function UnitName(u) return units[u] and units[u].name end
function UnitLevel(u) return units[u] and units[u].level end
function UnitIsDead(u) return units[u] and units[u].dead or false end
function strsplit(sep, s) local t = {}; for p in (s .. sep):gmatch("(.-)%" .. sep) do t[#t + 1] = p end; return table.unpack(t) end
function time() return 1000000 end
local now = 500
function GetTime() return now end
local sounds = 0
PlaySound = function() sounds = sounds + 1 end
SOUNDKIT = { RAID_WARNING = 8959 }
local flashed = false
function FlashClientIcon() flashed = true end
local marked
function GetRaidTargetIndex() return nil end
function SetRaidTarget(u, i) marked = { u, i } end
function IsInGroup() return false end
units.nameplate1 = { class = "normal", id = 3098, name = "Mottled Boar", level = 2 }
fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
check(not KUIRareAlert.shown, "normal mobs don't alert")
units.nameplate2 = { class = "rareelite", id = 5808, name = "Warlord Kolkanis", level = 9 }
fire("NAME_PLATE_UNIT_ADDED", "nameplate2")
local A = KUIRareAlert
check(A.shown and A.name.text == "Warlord Kolkanis", "rare nameplate: alert shows")
check(A.info.text:find("Level 9") and A.info.text:find("Rare Elite") and A.info.text:find("Durotar"), "level, kind and where: " .. A.info.text)
check(A.name.color[1] == 1 and A.name.color[2] == 0.82, "rare elites in gold")
check(A.model.modelUnit == "nameplate2", "its model")
check(sounds == 1 and flashed, "sound and flash")
check(chat[#chat]:find("Warlord Kolkanis"), "chat line")
local T = KUIRareTarget
check(T.shown and T.attrs.macrotext:find("/target Warlord Kolkanis"), "secure target button set up")
check(KUIDB.rareSeen[5808] and KUIDB.rareSeen[5808].m == 1411, "sighting saved")
fire("NAME_PLATE_UNIT_ADDED", "nameplate2")
check(sounds == 1, "no repeat alert for the same rare")
-- target it: skull
units.target = units.nameplate2
fire("PLAYER_TARGET_CHANGED")
check(marked and marked[2] == 8, "skull on the rare when you target it")
-- dies
units.target.dead = true
fire("UNIT_HEALTH", "target")
check(KUIDB.rareKilled[5808] == 1000000 and A.kind.text:find("dead"), "kill recorded")
-- waypoint button
local wp
TomTom = { AddWaypoint = function(_, m, x, y, o) wp = { m, x, y, o.title }; return 1 end, RemoveWaypoint = function() end }
A.way.scripts.OnClick(A.way)
check(wp and wp[1] == 1411 and wp[4] == "Warlord Kolkanis", "waypoint")
A.close.scripts.OnClick(A.close)
check(not A.shown and not T.shown, "dismiss hides it and the target button")
-- combat: target button waits
local combatNow = true
InCombatLockdown = function() return combatNow end
now = now + 1000
units.mouseover = { class = "rare", id = 3398, name = "Gesharahan", level = 20 }
fire("UPDATE_MOUSEOVER_UNIT")
check(A.shown and A.name.color[1] == 0.85, "rare from mouseover, silver")
check(not T.shown and A.targetSpot.text.text == "After combat", "target button waits for combat to end")
combatNow = false
fire("PLAYER_REGEN_ENABLED")
check(T.shown and T.attrs.macrotext:find("Gesharahan"), "then it's set up")
A.ignore.scripts.OnClick(A.ignore)
check(KUIDB.rareIgnored[3398] and not A.shown, "ignore")
now = now + 1000
fire("UPDATE_MOUSEOVER_UNIT")
check(not A.shown, "ignored rares don't alert")
-- vignettes
C_VignetteInfo = {
  GetVignettes = function() return { "v1", "v2" } end,
  GetVignetteInfo = function(g)
    if g == "v1" then return { name = "Sarkoth", objectGUID = "Creature-0-1-1-1-3281-0", atlasName = "VignetteKill" } end
    return { name = "Chest", objectGUID = "GameObject-0-1-1-1-99-0", atlasName = "VignetteLoot" }
  end,
  GetVignettePosition = function(g, m) return { x = 0.4, y = 0.6 } end,
}
now = now + 1000
fire("VIGNETTES_UPDATED")
check(A.shown and A.name.text == "Sarkoth" and A.kind.text:find("on your map") and A.info.text:find("40.0, 60.0"), "rare map marker: alert with its position")
check(KUIDB.finds[99] and KUIDB.finds[99].name == "Chest" and A.name.text == "Sarkoth", "treasure marker remembered, without covering the rare")
-- list
SlashCmdList.KUI("rares")
local L2 = KUIRareList
check(L2 and L2.shown and L2.title.text:find("Durotar"), "/fui rares lists this zone's rares")
local listed = {}
for _, r in ipairs(L2.rows) do if r.shown then listed[#listed + 1] = r.name.text end end
print("  list: " .. table.concat(listed, "; "))
local hasK = false
for _, n in ipairs(listed) do if n:find("Kolkanis") then hasK = true end end
check(hasK and #listed >= 3, "Classic rares and ones you've seen")
SlashCmdList.KUI("rares test")
check(A.shown and A.name.text == "Warlord Kolkanis", "/fui rares test")
SlashCmdList.KUI("rares unignore")
check(next(KUIDB.rareIgnored) == nil, "unignore")

print("== Treasures")
local Tr = ns.Treasures
local here = 0
for _ in pairs(Tr.byMap[1411] or {}) do here = here + 1 end
print("  Classic chest/find kinds placed in fake Durotar: " .. here)
local nowT = 1000000
time = function() return nowT end
-- hover a world object, then loot it
GameTooltipTextLeft1 = new("FontString", "GameTooltipTextLeft1")
GameTooltipTextLeft1.text = "Dinosaur Hatchling"
GameTooltip.scripts.OnShow(GameTooltip)
local lootGUID = "GameObject-0-1-1-1-777777-0"
function GetLootSourceInfo() return lootGUID end
C_Map.GetPlayerMapPosition = function() return { x = 0.30, y = 0.30 } end
fire("LOOT_OPENED")
local fnd = KUIDB.finds[777777]
check(fnd and fnd.name == "Dinosaur Hatchling" and fnd.kind == "find" and fnd.n == 1 and fnd.spots[1].x == 0.3, "world lootables you loot are remembered with where")
-- gathering isn't
C_Spell = { GetSpellName = function(id) return id == 2366 and "Herb Gathering" or "Opening" end }
fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast", 2366)
lootGUID = "GameObject-0-1-1-1-888888-0"
fire("LOOT_OPENED")
check(not KUIDB.finds[888888], "herbs, ore, fishing and skinning aren't")
now = now + 10
fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast", 3365)
GameTooltipTextLeft1.text = "Battered Chest"
GameTooltip.scripts.OnShow(GameTooltip)
lootGUID = "GameObject-0-1-1-1-2843-0"
fire("LOOT_OPENED")
check(KUIDB.finds[2843] and KUIDB.finds[2843].kind == "chest", "opened chests are remembered as chests")

-- quest objects aren't treasure; nameless objects are named after what was in them
loot = { { icon = "q", name = "Broken Bone Trident", count = 1, q = 1, quest = true } }
lootGUID = "GameObject-0-1-1-1-693669-0"
GameTooltip.scripts.OnShow = GameTooltip.scripts.OnShow
Tr.lastName = nil
fire("LOOT_OPENED")
check(not KUIDB.finds[693669], "quest objects aren't remembered as treasure")
fire("LOOT_CLOSED")
loot = { { icon = "p", name = "Prickly Pear Fruit", count = 2, q = 1 } }
lootGUID = "GameObject-0-1-1-1-656177-0"
C_Map.GetPlayerMapPosition = function() return { x = 0.80, y = 0.80 } end
fire("LOOT_OPENED")
C_Map.GetPlayerMapPosition = function() return { x = 0.30, y = 0.30 } end
check(KUIDB.finds[656177] and KUIDB.finds[656177].name == "Object with Prickly Pear Fruit", "nameless objects are named after their loot")
fire("LOOT_CLOSED")
-- an item filed as a quest item, even without the loot window's quest flag
loot = { { icon = "c", name = "Cactus Apple", count = 1, q = 1 } }
lootGUID = "GameObject-0-1-1-1-171938-0"
local oldInstant = C_Item.GetItemInfoInstant
C_Item.GetItemInfoInstant = function(x) if type(x) == "string" and x:find("item:1") then return 11583, "Quest", "Quest", "", "i", 12, 0 end return oldInstant(x) end
fire("LOOT_OPENED")
C_Item.GetItemInfoInstant = oldInstant
check(not KUIDB.finds[171938], "quest items are recognised by their item type too")
fire("LOOT_CLOSED")
loot = {}
-- second loot at the same spot merges
lootGUID = "GameObject-0-1-1-1-777777-0"
GameTooltipTextLeft1.text = "Dinosaur Hatchling"; GameTooltip.scripts.OnShow(GameTooltip)
fire("LOOT_OPENED")
check(#fnd.spots == 1 and fnd.n == 2, "same spot counted once, loots counted")
-- pins
Ra:DrawPins()
local findPin = false
local tipOK = false
for _, p in ipairs(Ra.wm.pins) do
  if p.shown and p.kind == "find" and p.learned and p.tkey == 777777 then
    findPin = true; GameTooltip.lines = {}; p.scripts.OnEnter(p)
    for _, l in ipairs(GameTooltip.lines) do if l:find("looted this 2 times") then tipOK = true end end
  end
end
check(findPin and tipOK, "on the map, with how often you've looted it")
-- walk near it later: alert
A.close.scripts.OnClick(A.close)
nowT = nowT + 2000
now = now + 2000
C_Map.GetPlayerMapPosition = function() return { x = 0.31, y = 0.30 } end
Tr:CheckNearby()
check(A.shown and A.name.text == "Dinosaur Hatchling" and A.kind.text:find("FIND") and A.kind.text:find("yd away"), "alert when you're near a spot you looted before")
check(not A.targetSpot.shown and not KUIRareTarget.shown, "no Target button for objects")
A.close.scripts.OnClick(A.close)
Tr:CheckNearby()
check(not A.shown, "and not again straight away")
-- just looted: no alert
nowT = nowT + 100
fnd.spots[1].t = nowT
now = now + 1000
Tr.alerted = {}
Tr:CheckNearby()
check(not A.shown, "no alert while the spot is probably still empty")
-- list
Ra.listMode = "treasures"; Ra:FillList()
local tnames = {}
for _, r in ipairs(L2.rows) do if r.shown then tnames[#tnames + 1] = r.name.text end end
print("  treasures list: " .. table.concat(tnames, "; "))
check(tnames[1] == "Dinosaur Hatchling" or tnames[2] == "Dinosaur Hatchling", "Treasures list shows what you've looted here")
L2.rows[1].scripts.OnClick(L2.rows[1], "LeftButton")
check(wp and wp[4], "click for a waypoint")
SlashCmdList.KUI("rares chests")
check(KUIDB.chestPins == false, "chest pins toggle")
SlashCmdList.KUI("rares chests")

print("== Tooltips")
local Tt = ns.Tooltips
check(Tt.enabled and GameTooltip.fuiPanel and GameTooltip.NineSlice.alpha == 0, "tooltip: flat panel, Blizzard frame hidden")
GameTooltip.NineSlice:SetAlpha(1)
check(GameTooltip.NineSlice.alpha == 0, "and it stays hidden")
check(ItemRefTooltip.fuiPanel and ItemRefTooltip.bd and ItemRefTooltip.bd[4] == 0, "old-style backdrops cleared too")
check(GameTooltipStatusBar.sbt == "Interface\\Buttons\\WHITE8X8" and GameTooltipStatusBar.h == 4, "thin flat health bar")
check(GameTooltipText.font and GameTooltipText.font[1]:find("Fonts"), "tooltip text in the Forever UI font")
check(#postCalls >= 1, "item lines hooked")
-- an uncommon cloth item
local items2 = { [2589] = { "Linen Cloth", 1, 5, 7, 0, 13 }, [5469] = { "Strider Meat", 1, 10, 0, 0, 4 }, [774] = { "Malachite", 2, 7, 7, 0, 25 }, [2138] = { "Sharpened Letter Opener", 2, 15, 2, 15, 200 } }
GetItemInfo = function(x)
  local id = tonumber(tostring(x):match("(%d+)"))
  local d = items2[id]; if not d then return nil end
  return d[1], "item:" .. id, d[2], d[3], 1, "", "", 1, "", "icon", d[6]
end
C_Item.GetItemInfo = GetItemInfo
local oldInst = C_Item.GetItemInfoInstant
C_Item.GetItemInfoInstant = function(x)
  local id = tonumber(tostring(x):match("(%d+)"))
  local d = items2[id]; if d then return id, "", "", "", "icon", d[4], d[5] end
  return oldInst(x)
end
GameTooltip.lines, GameTooltip.dlines = {}, {}
tipItem = { "Linen Cloth", "item:2589" }
for _, fn in ipairs(postCalls) do fn(GameTooltip) end
local dl = {}
for _, l in ipairs(GameTooltip.dlines) do dl[#dl + 1] = l[1] .. " = " .. l[2] end
print("  lines: " .. table.concat(GameTooltip.lines, " | ") .. " || " .. table.concat(dl, " | "))
local hasHeader = false
for _, l in ipairs(GameTooltip.lines) do if l:find("Drops from") then hasHeader = true end end
check(hasHeader and GameTooltip.dlines[2][1]:find("Battered Chest") and GameTooltip.dlines[3][1]:find("Kul Tiras Marine") and GameTooltip.dlines[3][2]:find("40%%"), "drops from your loot record, best chance first, chests by name")
check(GameTooltip.dlines[1][1] == "Vendor" and GameTooltip.dlines[1][2] == "12g 34s 56c", "vendor price when the game doesn't show one")
GameTooltip.lines, GameTooltip.dlines = {}, {}
GameTooltip.shownMoneyFrames = 1
for _, fn in ipairs(postCalls) do fn(GameTooltip) end
check(GameTooltip.dlines[1][1] ~= "Vendor", "no vendor line when the game shows its own")
GameTooltip.shownMoneyFrames = nil
-- gear: rarity border and item level
GameTooltip.lines, GameTooltip.dlines = {}, {}
tipItem = { "Sharpened Letter Opener", "item:2138" }
for _, fn in ipairs(postCalls) do fn(GameTooltip) end
check(GameTooltip.fuiPanel.edges[1].ctex[2] == 1 and GameTooltip.fuiPanel.edges[1].ctex[1] == 0.12, "green border for an uncommon item")
check(GameTooltip.lines[1] == "Item level 15", "item level on gear")
GameTooltip.scripts.OnHide(GameTooltip)
GameTooltip.scripts.OnShow(GameTooltip)
check(GameTooltip.fuiPanel.edges[1].ctex[1] == 0.35, "border back to normal for the next tooltip")
SlashCmdList.KUI("tooltips drops")
check(KUIDB.tipDrops == false, "tooltip lines can be turned off")
SlashCmdList.KUI("tooltips drops")

print("== Junk")
local sold = {}
C_Container.UseContainerItem = function(b, s) sold[#sold + 1] = b .. ":" .. s; BAGS[b][s] = nil end
BAGS[0][10] = { iconFileID = "g", stackCount = 3, quality = 0, itemID = 4865, hyperlink = "item:4865" }
BAGS[0][11] = { iconFileID = "g", stackCount = 1, quality = 0, itemID = 2138, hyperlink = "item:2138", hasNoValue = true }
BAGS[0][12] = { iconFileID = "g", stackCount = 1, quality = 0, itemID = 5469, hyperlink = "item:5469", isLocked = true }
items2[4865] = { "Ruined Pelt", 0, 1, 15, 0, 5 }
local chatBefore = #chat
fire("MERCHANT_SHOW")
for _ = 1, 20 do runTimers() end
check(#sold >= 1 and sold[1] == "0:6" or sold[1] == "0:10", "greys sold at the vendor: " .. table.concat(sold, ","))
local soldSet = {}
for _, x in ipairs(sold) do soldSet[x] = true end
check(not soldSet["0:11"] and not soldSet["0:12"], "items with no value, or locked, are left alone")
check(not soldSet["0:2"] and not soldSet["0:3"], "nothing but greys")
check(chat[#chat]:find("Sold %d junk item"), "summary: " .. chat[#chat])
fire("MERCHANT_CLOSED")
-- shift skips
BAGS[0][10] = { iconFileID = "g", stackCount = 3, quality = 0, itemID = 4865, hyperlink = "item:4865" }
IsShiftKeyDown = function() return true end
sold = {}
fire("MERCHANT_SHOW")
for _ = 1, 5 do runTimers() end
check(#sold == 0, "hold Shift to skip")
IsShiftKeyDown = function() return false end
fire("MERCHANT_CLOSED")
-- the slot changes before it's sold: not sold
fire("MERCHANT_SHOW")
BAGS[0][10] = { iconFileID = "x", stackCount = 1, quality = 2, itemID = 774, hyperlink = "item:774" }
for _ = 1, 5 do runTimers() end
check(#sold == 0, "re-checked before selling: a slot that changed isn't sold")
fire("MERCHANT_CLOSED")
BAGS[0][10] = nil

print("== Fonts redraw")
local lbl = KUIBagSettings.rows[1].label
lbl.redraws = 0
local oldSet = lbl.SetText
lbl.SetText = function(self, t) self.redraws = self.redraws + 1; oldSet(self, t) end
SlashCmdList.KUI("font rajdhani")
check(lbl.font[1]:find("Rajdhani") and lbl.redraws >= 1 and lbl.text == "Columns", "settings text redrawn in the new font")
SlashCmdList.KUI("font barlow")
check(lbl.font[1]:find("Barlow") and lbl.text == "Columns", "and back again")

print("== Settings")
SlashCmdList.KUI("alpha 0.5")
check(math.abs(f.fuiPanel.fill.ctex[4] - 0.5) < 1e-9 and math.abs(strip.fuiPanel.fill.ctex[4] - 0.5) < 1e-9, "opacity applies everywhere")
SlashCmdList.KUI("common")
check(KUIDB.common, "common toggle")
SlashCmdList.KUI("map off")
check(KUIDB.map == false and chat[#chat]:find("reload"), "modules switch off (after reload)")
SlashCmdList.KUI("")
check(chat[#chat]:find("/kui bags"), "help")

for _, m in ipairs(chat) do print("  chat: " .. m) end
print(string.format("\n%d passed, %d failed", passed, failed))
