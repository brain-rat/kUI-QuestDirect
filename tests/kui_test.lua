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
  local m = setmetatable({ kind = kind, scripts = {}, shown = true, alpha = 1, regions = {}, points = {}, parent = parent, flevel = 1, events = {} }, Meta)
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
function Mock:GetFrameLevel() return self.flevel end
function Mock:SetFrameLevel(l) self.flevel = l end
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
  f.tmpl = template
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
-- Unit frames world
function Mock:SetStatusBarTexture(t) self.sbt = t end
function Mock:GetStatusBarTexture() self.fill = self.fill or new("Texture", nil, self); return self.fill end
function Mock:SetMinMaxValues(a, b) self.minv, self.maxv = a, b end
function Mock:SetValue(v) self.value = v end
function Mock:SetVertexColor(r, g, b) self.vc = { r, g, b } end
function Mock:GetThumbTexture() self.thumb = self.thumb or new("Texture", nil, self); return self.thumb end
function Mock:GetBottom() return 200 end
function Mock:SetParent(p) self.parent = p end
function Mock:GetParent() return self.parent end
function Mock:UnregisterAllEvents() for e in pairs(self.events) do self:UnregisterEvent(e) end; self.allOff = true end
function Mock:SetCooldown(s, d) self.cooldown = { s, d } end
function Mock:SetCooldownFromDurationObject(o) self.cooldownObj = o end
function Mock:SetTimerDuration(d, _, dir) self.timerDur, self.timerDir = d, dir end
function Mock:SetFormattedText(fmt, ...)
  for i = 1, select("#", ...) do
    if issecretvalue and issecretvalue((select(i, ...))) then self.text = "<secret>"; return end
  end
  self.text = fmt:format(...)
end
local unitWatch = {}
function RegisterUnitWatch(f) unitWatch[f] = true end
function UnregisterUnitWatch(f) unitWatch[f] = nil end
RAID_CLASS_COLORS = { SHAMAN = { r = 0, g = 0.44, b = 0.87 }, ROGUE = { r = 1, g = 0.96, b = 0.41 } }
DebuffTypeColor = { Magic = { r = 0.2, g = 0.6, b = 1 } }
Enum.PowerType = { ComboPoints = 14 }
function GetCreatureDifficultyColor() return { r = 1, g = 1, b = 0 } end
local UNITS
local function unitInfo(u) return UNITS and UNITS[u] or {} end
local castInfo, chanInfo = {}, {}
local playerClass, combo = "SHAMAN", 0
local unitApi = {
  UnitHealth = function(u) return unitInfo(u).hp or 100 end,
  UnitHealthMax = function(u) return unitInfo(u).hpMax or 100 end,
  UnitPower = function(u, k) if k == 14 then return combo end; return unitInfo(u).pw or 50 end,
  UnitPowerMax = function(u, k) if k == 14 then return 5 end; return unitInfo(u).pwMax or 100 end,
  UnitPowerType = function(u) local i = unitInfo(u); return i.pkind or 0, i.ptoken or "MANA" end,
  UnitLevel = function(u) return unitInfo(u).level or 7 end,
  UnitClass = function(u) local i = unitInfo(u); return "Class", i.class or playerClass end,
  UnitIsPlayer = function(u) return unitInfo(u).isPlayer end,
  UnitReaction = function(u) return unitInfo(u).reaction end,
  UnitIsTapDenied = function(u) return unitInfo(u).tapped end,
  UnitIsConnected = function(u) local c = unitInfo(u).connected; if c == nil then return true end; return c end,
  UnitIsGhost = function(u) return unitInfo(u).ghost end,
  UnitClassification = function(u) return unitInfo(u).classif or "normal" end,
  UnitAffectingCombat = function(u) return unitInfo(u).combat end,
  UnitIsGroupLeader = function(u) return unitInfo(u).lead end,
  UnitIsPVP = function(u) return unitInfo(u).pvp end,
  UnitIsEnemy = function(u) return unitInfo(u).enemy end,
  UnitIsFriend = function(u) return unitInfo(u).friend end,
  GetRaidTargetIndex = function(u) return unitInfo(u).raid end,
  SetRaidTargetIconTexture = function(t, i) t.raidIndex = i end,
  GetComboPoints = function() return combo end,
  IsResting = function() return UNITS and UNITS.resting end,
  UnitCastingInfo = function(u) local c = castInfo[u]; if c then return c.name, c.name, c.icon, c.st, c.en, false, c.guid, c.locked, 1 end end,
  UnitChannelInfo = function(u) local c = chanInfo[u]; if c then return c.name, c.name, c.icon, c.st, c.en, false, c.locked, 1 end end,
  BreakUpLargeNumbers = function(v) if issecretvalue and issecretvalue(v) then return v end; return tostring(v) end,
}
unitApi.UnitGUID = function(u) return u end
unitApi.UnitIsVisible = function() return true end
for k, fn in pairs(unitApi) do if _G[k] == nil then _G[k] = fn end end
PlayerFrame = new("Frame", "PlayerFrame")
PlayerFrame:RegisterEvent("UNIT_HEALTH")
PlayerFrame.healthbar = new("StatusBar"); PlayerFrame.healthbar:RegisterEvent("UNIT_HEALTH")
TargetFrame = new("Frame", "TargetFrame")
TargetFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
PetFrame = new("Frame", "PetFrame")
TargetFrameToT = new("Frame", "TargetFrameToT")
TargetFrameSpellBar = new("StatusBar", "TargetFrameSpellBar")
ComboFrame = new("Frame", "ComboFrame")
TotemFrame = new("Frame", "TotemFrame")
PlayerCastingBarFrame = new("StatusBar", "PlayerCastingBarFrame")
PlayerCastingBarFrame:RegisterEvent("UNIT_SPELLCAST_START")
function PlayerCastingBarFrame:SetUnit(u) self.barUnit = u or "none" end
for _, b in ipairs({ PlayerFrame, TargetFrame, PetFrame, TargetFrameToT }) do unitWatch[b] = true end

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
check(chat[#chat]:find("/kui edit") and chat[#chat]:find("bags"), "help")

print("== Unit frames")
for k, fn in pairs(unitApi) do _G[k] = fn end
UNITS = {
  player = { hp = 269, hpMax = 269, pw = 171, pwMax = 171, level = 7, isPlayer = true, class = "SHAMAN", reaction = 5 },
  target = { hp = 40, hpMax = 80, pw = 10, pwMax = 20, ptoken = "RAGE", level = 9, reaction = 2, classif = "elite", enemy = true },
  targettarget = { hp = 269, hpMax = 269 },
  pet = { hp = 30, hpMax = 60, pw = 5, pwMax = 10 },
}
function UnitExists(u) return UNITS[u] ~= nil end
function UnitIsDead(u) return unitInfo(u).dead end
function UnitName(u) return unitInfo(u).name or u end
UNITS.player.name, UNITS.target.name = "Test Hero", "Razormane Scout"
local now = 100
GetTime = function() return now end
local U, CB, St = ns.UnitFrames, ns.Castbar, ns.Style
local P, T, ToT, Pet = KUIPlayerFrame, KUITargetFrame, KUIToTFrame, KUIPetFrame
local started = true
for _, m in ipairs(chat) do if m:find("couldn't start") then started = false end end
check(started, "every module starts")
check(KUIDB.frames and KUIDB.castbar and KUIDB.targetCast and KUIDB.frameScale == 1, "defaults on")

-- Blizzard's frames
local hidden = St.HiddenParent()
for _, b in ipairs({ PlayerFrame, TargetFrame, PetFrame, TargetFrameToT, TargetFrameSpellBar, ComboFrame }) do
  check(b.parent == hidden and b.shown == false and b.allOff, "Blizzard frame hidden and silent")
end
check(PlayerFrame.healthbar.allOff, "its bars stop listening too")
for _, b in ipairs({ PlayerFrame, TargetFrame, PetFrame, TargetFrameToT }) do check(not unitWatch[b], "Blizzard frame off unit watch") end
check(TotemFrame.parent == UIParent and TotemFrame.shown ~= false, "totem frame moved out, still showing")
check(TotemFrame.points[1][2] == P, "totems sit on the kUI player frame")
TotemFrame:SetPoint("TOPLEFT", PlayerFrame, "BOTTOMLEFT", 0, 0)
check(#TotemFrame.points == 1 and TotemFrame.points[1][2] == P, "and stay there when Blizzard re-anchors them")
check(PlayerCastingBarFrame.parent == hidden and PlayerCastingBarFrame.barUnit == "none" and PlayerCastingBarFrame.allOff, "Blizzard's cast bar gone")

-- Secure setup
for _, fr in ipairs({ P, T, ToT, Pet }) do
  check(fr.tmpl == "SecureUnitButtonTemplate" and fr.attrs.type1 == "target" and fr.attrs.type2 == "togglemenu", "click targets, right-click menu")
  check(ClickCastFrames[fr], "click-cast add-ons can see it")
end
check(P.attrs.unit == "player" and T.attrs.unit == "target" and ToT.attrs.unit == "targettarget" and Pet.attrs.unit == "pet", "right units")
check(unitWatch[T] and unitWatch[ToT] and unitWatch[Pet] and not unitWatch[P], "only the player frame stays up without a unit")
check(P.fuiPanel.fill.ctex[1] == 0.04 and P.fuiPanel.edges[1].ctex[1] == 0.35, "shared panel colours")
check(P.h == 18 + 20 + 1 + 12 + 1 and ToT.h == 16 + 10 + 1 and Pet.h == 16 + 10 + 1 + 5 + 1, "heights fit the bars")

-- Player
fire("PLAYER_ENTERING_WORLD")
check(P.name.text == "Test Hero" and P.name.color[1] == 0.5, "player name in the accent colour")
check(P.hp.minv == 0 and P.hp.maxv == 269 and P.hp.value == 269, "health bar")
check(P.hpText.text == "269 / 269" and P.hpPct.text == "100%", "health text: " .. tostring(P.hpText.text))
check(P.pwText.text == "171 / 171" and P.pw.value == 171, "power text")
check(P.level.text == 7, "level")
local vc = P.hp:GetStatusBarTexture().vc
check(vc[1] == 0 and vc[2] == 0.44, "class colour on your health")
SlashCmdList.KUI("frames class")
vc = P.hp:GetStatusBarTexture().vc
check(not KUIDB.classColor and vc[1] == 0.3 and vc[2] == 0.7, "class colours can be turned off")
SlashCmdList.KUI("frames class")
UNITS.player.hp = 100
fire("UNIT_HEALTH", "nameplate1")
check(P.hp.value == 269, "other units' events don't touch it")
fire("UNIT_HEALTH", "player")
check(P.hp.value == 100 and P.hpText.text == "100 / 269" and P.hpPct.text == "37%", "health updates: " .. tostring(P.hpPct.text))
UNITS.player.pw = 20
fire("UNIT_POWER_FREQUENT", "player")
check(P.pwText.text == "20 / 171", "power updates")
UNITS.player.combat = true
fire("PLAYER_REGEN_ENABLED")
check(P.tag.text:find("Combat"), "combat tag")
UNITS.player.combat, UNITS.resting = nil, true
fire("PLAYER_UPDATE_RESTING")
check(P.tag.text:find("Rested") and not P.tag.text:find("Combat"), "rested tag")
UNITS.resting, UNITS.player.lead, UNITS.player.pvp = nil, true, true
fire("PARTY_LEADER_CHANGED")
check(P.tag.text:find("Lead") and P.tag.text:find("PvP"), "leader and PvP tags")
UNITS.player.lead, UNITS.player.pvp = nil, nil
UNITS.player.dead = true
fire("UNIT_HEALTH", "player")
check(P.hpText.text == "Dead" and P.hpPct.text == "", "dead")
UNITS.player.dead, UNITS.player.ghost = nil, true
fire("UNIT_HEALTH", "player")
check(P.hpText.text == "Ghost", "ghost")
UNITS.player.ghost = nil

-- Target
local fsounds = {}
PlaySound = function(id) fsounds[#fsounds + 1] = id end
SOUNDKIT = { INTERFACE_SOUND_LOST_TARGET_UNIT = "lost", IG_CREATURE_AGGRO_SELECT = "aggro", IG_CHARACTER_NPC_SELECT = "npc", IG_CREATURE_NEUTRAL_SELECT = "neutral" }
fsounds = {}
fire("PLAYER_TARGET_CHANGED")
check(T.name.text == "Razormane Scout", "target name")
check(T.tag.text:find("Elite"), "elite tag")
check(T.level.text == 9 and T.level.color[2] == 1, "level in its difficulty colour")
vc = T.hp:GetStatusBarTexture().vc
check(vc[1] == 0.8 and T.name.color[1] == 0.8, "hostile: red")
check(T.hpText.text == "40 / 80" and T.hpPct.text == "50%", "target health")
check(T.pw:GetStatusBarTexture().vc[1] == 0.85, "rage colour")
check(fsounds[1] == "aggro", "hostile target sound")
UNITS.target.reaction = 4
fire("UNIT_FACTION", "target")
check(T.hp:GetStatusBarTexture().vc[1] == 0.9 and T.name.color[1] == 0.9, "neutral: yellow")
UNITS.target.reaction, UNITS.target.tapped = 2, true
fire("UNIT_FACTION", "target")
check(T.hp:GetStatusBarTexture().vc[1] == 0.5, "tapped by someone else: grey")
UNITS.target.tapped, UNITS.target.level = nil, -1
fire("PLAYER_TARGET_CHANGED")
check(T.level.text == "??", "skull level")
UNITS.target.level, UNITS.target.pwMax = 9, 0
fire("UNIT_MAXPOWER", "target")
check(T.pwText.text == "", "no power, no numbers")
UNITS.target.pwMax, UNITS.target.isPlayer, UNITS.target.connected = 20, true, false
UNITS.target.class = "ROGUE"
fire("PLAYER_TARGET_CHANGED")
check(T.hpText.text == "Offline" and T.hp:GetStatusBarTexture().vc[1] == 1, "offline player, class coloured")
UNITS.target.isPlayer, UNITS.target.connected, UNITS.target.class = nil, nil, nil
UNITS.target.raid = 8
fire("RAID_TARGET_UPDATE")
check(T.raid.shown and T.raid.raidIndex == 8, "raid icon")
UNITS.target.raid = nil
fire("RAID_TARGET_UPDATE")
check(not T.raid.shown, "raid icon cleared")
local keep = UNITS.target
UNITS.target = nil
fsounds = {}
fire("PLAYER_TARGET_CHANGED")
check(fsounds[1] == "lost", "lost-target sound")
UNITS.target = keep

-- Small frames
ToT.name.text = ""
ToT.scripts.OnUpdate(ToT, 0.1)
check(ToT.name.text == "", "target of target checks now and then, not every frame")
ToT.scripts.OnUpdate(ToT, 0.2)
check(ToT.name.text == "targettarget" and ToT.hp.value == 269, "target of target updates")
check(ToT.hpText.shown == false and ToT.pw.shown == false and ToT.level.shown == false, "target of target: name and health only")
fire("UNIT_PET", "player")
check(Pet.name.text == "pet" and Pet.hp.value == 30 and Pet.pw.value == 5 and Pet.hpText.shown == false, "pet frame")

-- Auras
local AURAS = { HARMFUL = {}, HELPFUL = {} }
local tipAura
function GameTooltip:SetUnitAuraByAuraInstanceID(u, id) tipAura = id end
C_UnitAuras = { GetAuraDataByIndex = function(_, i, filter) return AURAS[filter][i] end }
AURAS.HARMFUL[1] = { icon = "d1", applications = 3, duration = 10, expirationTime = 150, dispelName = "Magic", auraInstanceID = 11 }
AURAS.HARMFUL[2] = { icon = "d2", applications = 0, duration = 0, expirationTime = 0, isFromPlayerOrPlayerPet = true, auraInstanceID = 12 }
AURAS.HELPFUL[1] = { icon = "b1", applications = 1, duration = 5, expirationTime = 120, auraInstanceID = 13 }
fire("UNIT_AURA", "player")
check(#U.auras == 0, "other units' auras ignored")
fire("UNIT_AURA", "target")
local a = U.auras
check(#a == 3 and a[1].icon.tex == "d1" and a[3].icon.tex == "b1", "debuffs first, then buffs")
check(a[1].count.text == 3 and a[2].count.text == "", "stacks only above one")
check(a[1].cd.cooldown[1] == 140 and a[1].cd.cooldown[2] == 10 and a[2].cd.shown == false, "cooldown spiral only with a duration")
check(a[1].edges[1].ctex[1] == 0.2, "dispel type colours the border")
check(a[2].edges[1].ctex[1] == 0.5, "yours in the accent colour")
a[1].scripts.OnEnter(a[1])
check(tipAura == 11, "aura tooltip")
check(a[1].points[1][4] == 0 and a[2].points[1][4] == 25, "icons in a row")
for i = 3, 20 do AURAS.HARMFUL[i] = { icon = "x", applications = 0, duration = 0, expirationTime = 0, auraInstanceID = 100 + i } end
fire("UNIT_AURA", "target")
check(#a == 16 and a[10].points[1][5] == 25 and a[10].points[1][4] == 0, "stops at 16, next row goes up")
for i = 3, 20 do AURAS.HARMFUL[i] = nil end
AURAS.HARMFUL[2] = nil
fire("UNIT_AURA", "target")
check(a[1].shown and a[2].icon.tex == "b1" and a[3].shown == false and a[16].shown == false, "gone auras hide")
AURAS.HARMFUL[1] = nil

-- Castbar
local Bar, TBar = KUICastbar, KUITargetCastbar
check(Bar.shown == false and TBar.shown == false, "cast bars hidden until something casts")
check(TBar.parent == T, "target bar belongs to the target frame")
check(U.auraRow.points[1][2] == T, "auras above the target frame")
castInfo.player = { name = "Lightning Bolt", icon = "bolt", st = 100000, en = 102000, guid = "g1" }
fire("UNIT_SPELLCAST_START", "player", "g1")
check(Bar.shown and Bar.label.text == "Lightning Bolt" and Bar.icon.tex == "bolt", "cast shows")
check(Bar.bar.maxv == 2 and Bar.bar:GetStatusBarTexture().vc[1] == 0.5, "accent colour, runs for the cast time")
now = 101
Bar.scripts.OnUpdate(Bar, 1)
check(Bar.bar.value == 1 and Bar.time.text == "1.0", "fills as it goes")
fire("UNIT_SPELLCAST_FAILED", "player", "g2")
check(Bar.mode == "cast", "another spell failing doesn't end this cast")
fire("UNIT_SPELLCAST_STOP", "player", "g2")
check(Bar.mode == "cast", "another cast's stop doesn't end this one")
castInfo.player.en = 103000
fire("UNIT_SPELLCAST_DELAYED", "player", "g1")
check(Bar.bar.maxv == 3, "pushback extends it")
castInfo.player = nil
fire("UNIT_SPELLCAST_STOP", "player", "g1")
check(Bar.mode == "fade" and Bar.bar.value == 1 and Bar.time.text == "", "finished cast fills up and fades")
Bar.scripts.OnUpdate(Bar, 0.1)
check(Bar.alpha < 1 and Bar.shown, "fading")
Bar.scripts.OnUpdate(Bar, 1)
check(Bar.shown == false and Bar.mode == nil and Bar.alpha == 1, "then gone")
castInfo.player = { name = "Heal", icon = "h", st = 101000, en = 103000, guid = "g3" }
fire("UNIT_SPELLCAST_START", "player", "g3")
castInfo.player = nil
fire("UNIT_SPELLCAST_INTERRUPTED", "player", "g3")
check(Bar.label.text == "Interrupted" and Bar.bar:GetStatusBarTexture().vc[1] == 0.85, "interrupted: red")
fire("UNIT_SPELLCAST_STOP", "player", "g3")
check(Bar.label.text == "Interrupted", "the stop after an interrupt doesn't hide the message")
Bar.scripts.OnUpdate(Bar, 0.3)
check(Bar.alpha == 1, "message holds")
Bar.scripts.OnUpdate(Bar, 1)
check(Bar.shown == false, "then fades")
castInfo.player = { name = "Heal", icon = "h", st = 101000, en = 103000, guid = "g4" }
fire("UNIT_SPELLCAST_START", "player", "g4")
castInfo.player = nil
fire("UNIT_SPELLCAST_FAILED", "player", "g4")
check(Bar.label.text == "Failed", "failed")
Bar.scripts.OnUpdate(Bar, 2)
chanInfo.player = { name = "Drain", icon = "c", st = 101000, en = 105000 }
fire("UNIT_SPELLCAST_CHANNEL_START", "player")
check(Bar.mode == "channel" and Bar.bar:GetStatusBarTexture().vc[1] == 0.45 and Bar.bar.value == 4, "channel: green, starts full")
now = 102
Bar.scripts.OnUpdate(Bar, 1)
check(Bar.bar.value == 3, "channel empties")
fire("UNIT_SPELLCAST_FAILED", "player", "zz")
check(Bar.mode == "channel", "a failed spell doesn't end a channel")
chanInfo.player = nil
fire("UNIT_SPELLCAST_CHANNEL_STOP", "player")
check(Bar.mode == "fade", "channel ends")
Bar.scripts.OnUpdate(Bar, 2)
-- target cast
castInfo.target = { name = "Shadow Bolt", icon = "s", st = 102000, en = 104000, guid = "t1", locked = true }
fire("UNIT_SPELLCAST_START", "target", "t1")
check(TBar.shown and Bar.shown == false, "target's cast only on the target's bar")
check(TBar.bar:GetStatusBarTexture().vc[1] == 0.55, "can't be interrupted: grey")
check(U.auraRow.points[1][2] == TBar, "auras move up above the cast bar")
castInfo.target = nil
fire("PLAYER_TARGET_CHANGED")
check(TBar.shown == false and U.auraRow.points[1][2] == T, "new target: bar gone, auras back down")
castInfo.target = { name = "Shadow Bolt", icon = "s", st = 102000, en = 104000, guid = "t2" }
fire("PLAYER_TARGET_CHANGED")
check(TBar.shown and TBar.label.text == "Shadow Bolt", "targeting something mid-cast shows it")
castInfo.target = nil
fire("PLAYER_TARGET_CHANGED")
-- a lost stop event can't leave the bar stuck
castInfo.player = { name = "Heal", icon = "h", st = 101000, en = 102500, guid = "g9" }
fire("UNIT_SPELLCAST_START", "player", "g9")
castInfo.player = nil
now = 104
Bar.scripts.OnUpdate(Bar, 0.1)
check(Bar.mode == "fade", "a lost stop event can't leave the bar stuck")
Bar.scripts.OnUpdate(Bar, 2)
-- sample
SlashCmdList.KUI("castbar test")
check(Bar.shown and TBar.shown and Bar.label.text == "Sample cast", "/kui castbar test")
now = now + 3.5
Bar.scripts.OnUpdate(Bar, 0.1)
check(Bar.mode == "fade", "sample ends by itself")
Bar.scripts.OnUpdate(Bar, 2)
TBar.scripts.OnUpdate(TBar, 0.1)
TBar.scripts.OnUpdate(TBar, 2)
check(Bar.shown == false and TBar.shown == false, "sample gone")

-- Combo points
check(rawget(U, "pips") == nil, "no combo pips on a Shaman")
playerClass = "ROGUE"
UNITS.player.class = "ROGUE"
combo = 3
U:BuildPips()
U:UpdatePips()
check(#U.pips.pips == 5 and U.pips.pips[3].value == 3 and U.pips.pips[3].minv == 2 and U.pips.pips[3].maxv == 3, "five pips, filled by the count")
check(U.pips.shown, "Rogue: always there")
combo = 4
fire("UNIT_POWER_UPDATE", "player")
check(U.pips.pips[1].value == 4, "pips update")
U.pips.druid, combo = true, 0
U:UpdatePips()
check(U.pips.shown == false, "Druid: only with points")
combo = 1
U:UpdatePips()
check(U.pips.shown, "Druid: shows with points")
combo = 0
playerClass, UNITS.player.class = "SHAMAN", "SHAMAN"
U.pips = nil

-- Secret values: bars and text take them untouched, and Lua never does sums on them.
local SecretMeta = {}
local function boom() error("a secret value was used in Lua", 2) end
for _, m in ipairs({ "__add", "__sub", "__mul", "__div", "__mod", "__idiv", "__unm", "__concat", "__len", "__lt", "__le", "__tostring", "__call", "__index", "__newindex" }) do SecretMeta[m] = boom end
local function Secret() return setmetatable({}, SecretMeta) end
issecretvalue = function(v) return getmetatable(v) == SecretMeta end
local sHp, sMax, sPw = Secret(), Secret(), Secret()
UnitHealth, UnitHealthMax = function() return sHp end, function() return sMax end
UnitPower, UnitPowerMax = function() return sPw end, function() return sPw end
UnitPowerType = function() return Secret(), Secret() end
UnitName, UnitLevel = function() return Secret() end, function() return Secret() end
UnitClass = function() return Secret(), Secret() end
for _, k in ipairs({ "UnitIsPlayer", "UnitReaction", "UnitIsTapDenied", "UnitIsConnected", "UnitIsDead", "UnitIsGhost", "UnitClassification", "UnitAffectingCombat", "UnitIsGroupLeader", "UnitIsPVP", "GetRaidTargetIndex", "UnitIsEnemy", "UnitIsFriend", "GetComboPoints" }) do
  _G[k] = function() return Secret() end
end
UnitExists = function() return Secret() end
CurveConstants = { ScaleTo100 = "to100" }
local pctAsked
UnitHealthPercent = function(_, _, curve) pctAsked = curve; return Secret() end
C_StringUtil = { RoundToNearestString = function(v) return v end }
local ok, err = pcall(function()
  fire("PLAYER_ENTERING_WORLD")
  fire("UNIT_HEALTH", "target")
  fire("UNIT_POWER_UPDATE", "target")
  fire("PLAYER_TARGET_CHANGED")
  fire("UNIT_FACTION", "target")
  fire("PLAYER_FLAGS_CHANGED")
  fire("RAID_TARGET_UPDATE")
  ToT.scripts.OnUpdate(ToT, 1)
end)
check(ok, "secret unit values: no errors: " .. tostring(err))
check(T.hp.value == sHp and T.hp.maxv == sMax, "secret health goes straight into the bar")
check(T.hpText.text == "<secret>" and T.hpPct.text == "<secret>" and pctAsked == "to100", "secret health text comes from the game")
check(T.pw.value == sPw and T.pwText.text == "<secret>", "secret power")
check(T.level.text == "", "secret level just isn't shown")
check(issecretvalue(T.name.text), "secret name still shows")
ok, err = pcall(function() SlashCmdList.KUI("font rajdhani"); SlashCmdList.KUI("font barlow") end)
check(ok, "changing font with a secret name on screen: " .. tostring(err))
-- secret auras
local durObj = {}
C_UnitAuras = {
  GetAuraDataByIndex = function(_, i, f) if i == 1 and f == "HARMFUL" then return { icon = Secret(), applications = Secret(), duration = Secret(), expirationTime = Secret(), dispelName = Secret(), isFromPlayerOrPlayerPet = Secret(), auraInstanceID = 77 } end end,
  GetAuraApplicationDisplayCount = function(_, id, lo, hi) return "x" .. id end,
  GetAuraDuration = function() return durObj end,
}
ok, err = pcall(function() fire("UNIT_AURA", "target") end)
check(ok, "secret auras: no errors: " .. tostring(err))
check(a[1].count.text == "x77" and a[1].cd.cooldownObj == durObj and a[1].cd.shown, "secret aura: count and spiral from the game")
-- secret cast
local cObj = { GetRemainingDuration = function() return Secret() end }
local sLocked = Secret()
UnitCastingDuration = function() return cObj end
Enum.StatusBarTimerDirection = { ElapsedTime = 0, RemainingTime = 1 }
C_CurveUtil = { EvaluateColorValueFromBoolean = function(flag, a1, b1) if flag == sLocked then return a1 end; return b1 end }
castInfo.target = { name = Secret(), icon = Secret(), st = Secret(), en = Secret(), guid = Secret(), locked = sLocked }
ok, err = pcall(function()
  fire("UNIT_SPELLCAST_START", "target", Secret())
  TBar.scripts.OnUpdate(TBar, 0.1)
end)
check(ok, "secret cast: no errors: " .. tostring(err))
check(TBar.shown and TBar.bar.timerDur == cObj and TBar.bar.timerDir == 0 and TBar.time.text == "<secret>", "secret cast: the game's duration drives the bar")
check(TBar.bar:GetStatusBarTexture().vc[1] == 0.55, "secret can't-interrupt still colours it")
ok, err = pcall(function() fire("UNIT_SPELLCAST_STOP", "target", Secret()) end)
check(ok and TBar.mode == "fade", "secret cast ends: " .. tostring(err))
TBar.scripts.OnUpdate(TBar, 2)
castInfo.target = nil
issecretvalue = nil
for k, fn in pairs(unitApi) do _G[k] = fn end
function UnitExists(u) return UNITS[u] ~= nil end
function UnitIsDead(u) return unitInfo(u).dead end
function UnitName(u) return unitInfo(u).name or u end
C_UnitAuras = { GetAuraDataByIndex = function(_, i, filter) return AURAS[filter][i] end }
AURAS.HARMFUL[1] = { icon = "d1", applications = 3, duration = 10, expirationTime = 150, auraInstanceID = 11 }
fire("PLAYER_TARGET_CHANGED")
fire("UNIT_AURA", "target")
check(a[1].shown, "back to plain values")

-- Moving
InCombatLockdown = function() return inCombat end
inCombat = true
SlashCmdList.KUI("unlock")
check(not U.unlocked and chat[#chat]:find("combat"), "can't unlock in combat")
inCombat = false
SlashCmdList.KUI("unlock")
check(U.unlocked and P.mover.shown and T.mover.shown and Bar.mover.shown and Bar.shown, "/kui unlock shows the drag overlays")
check(not unitWatch[T] and not unitWatch[ToT] and not unitWatch[Pet] and T.shown and T.unit == "player" and T.name.text == "Test Hero", "target frame stays up to place it, showing you")
check(a[1].shown == false, "no auras while placing")
P.mover.scripts.OnDragStart(P.mover)
P.mover.scripts.OnDragStop(P.mover)
check(KUIDB.playerLeft == 300 and KUIDB.playerTop == 600, "dragging saves the spot")
Bar.mover.scripts.OnDragStop(Bar.mover)
check(KUIDB.castLeft == 300 and KUIDB.castTop == 600, "castbar spot saved")
SlashCmdList.KUI("lock")
check(not U.unlocked and P.mover.shown == false and Bar.mover.shown == false and Bar.shown == false, "/kui lock")
check(unitWatch[T] and unitWatch[ToT] and unitWatch[Pet] and T.unit == "target", "frames follow their units again")
local watchCalls = 0
local rw = RegisterUnitWatch
RegisterUnitWatch = function(f) watchCalls = watchCalls + 1; rw(f) end
inCombat = true
SlashCmdList.KUI("lock")
check(watchCalls == 0, "/kui lock in combat when already locked touches nothing protected")
inCombat = false
SlashCmdList.KUI("frames unlock")
check(U.unlocked, "/kui frames unlock too")
fire("PLAYER_REGEN_DISABLED")
check(not U.unlocked and P.mover.shown == false and Bar.mover.shown == false and watchCalls == 3, "entering combat locks them")
RegisterUnitWatch = rw
U:Place(); CB:Place()
check(P.points[1][1] == "TOPLEFT" and P.points[1][4] == 300, "saved spot used")
check(Bar.points[1][1] == "TOPLEFT" and Bar.points[1][4] == 300, "saved castbar spot used")
SlashCmdList.KUI("frames scale 1.2")
check(KUIDB.frameScale == 1.2 and T.scale == 1.2 and ToT.scale == 1.2, "scale")
inCombat = true
SlashCmdList.KUI("frames scale 0.9")
check(KUIDB.frameScale == 1.2 and chat[#chat]:find("combat"), "no scaling in combat")
inCombat = false
SlashCmdList.KUI("frames reset")
check(not KUIDB.playerLeft and KUIDB.frameScale == 1 and P.points[1][1] == "CENTER", "frames reset")
SlashCmdList.KUI("castbar scale 1.5")
check(KUIDB.castScale == 1.5 and Bar.scale == 1.5, "castbar scale")
SlashCmdList.KUI("castbar reset")
check(not KUIDB.castLeft and KUIDB.castScale == 1 and Bar.points[1][1] == "CENTER", "castbar reset")
SlashCmdList.KUI("castbar target")
check(KUIDB.targetCast == false and TBar.off, "target cast bar switch")
SlashCmdList.KUI("castbar target")
SlashCmdList.KUI("alpha 0.6")
check(math.abs(P.fuiPanel.fill.ctex[4] - 0.6) < 1e-9 and math.abs(Bar.fuiPanel.fill.ctex[4] - 0.6) < 1e-9 and math.abs(TBar.fuiPanel.fill.ctex[4] - 0.6) < 1e-9, "opacity reaches the frames and bars")
SlashCmdList.KUI("frames off")
check(KUIDB.frames == false and chat[#chat]:find("reload"), "/kui frames off")
SlashCmdList.KUI("frames on")
SlashCmdList.KUI("castbar off")
check(KUIDB.castbar == false, "/kui castbar off")
SlashCmdList.KUI("castbar on")
SlashCmdList.KUI("frames")
check(chat[#chat]:find("/kui edit"), "frames help")
SlashCmdList.KUI("castbar")
check(chat[#chat]:find("/kui castbar test"), "castbar help")

print("== Edit mode")
UnitGUID = function(u) return unitInfo(u).guid or u end
UnitIsVisible = function() return true end
local portraitCalls = {}
SetPortraitTexture = function(t, u) portraitCalls[#portraitCalls + 1] = { t, u } end
inCombat = false

-- Names come in two parts on this client
local realName = UnitName
RegionalUniqueNamesEnabled = function() return true end
Constants = { CharacterNameSeparatorConsts = { CHARACTERNAME_SURNAME_SEPARATOR = " " } }
UnitName = function(u) if u == "player" then return "Test", "Hero" end; return realName(u) end
U:Update(P)
check(P.name.text == "Test Hero", "both parts of a player's name: " .. tostring(P.name.text))
UnitName = function(u) if u == "player" then return "Test", "" end; return realName(u) end
U:Update(P)
check(P.name.text == "Test", "no empty second part")
UnitName = function(u) if u == "player" then return "Test", "Hero" end; return realName(u) end
RegionalUniqueNamesEnabled = nil
U:Update(P)
check(P.name.text == "Test", "a second value only counts where the client uses two-part names")
RegionalUniqueNamesEnabled = function() return true end

-- Opening
SlashCmdList.KUI("edit")
local Panel = KUIEditMode
local E = ns.EditMode
check(Panel and Panel.shown and U.unlocked and P.mover.shown and ToT.mover.shown and Pet.mover.shown and Bar.mover.shown, "/kui edit opens the panel and overlays")
check(#E.tabs == 5 and E.tab == "player", "a tab for each frame")
check(UISpecialFrames[#UISpecialFrames] == "KUIEditMode", "Esc closes it")
local function row(key)
  for _, r in ipairs(E.rows) do if r.shown ~= false and r.def and r.def.key == key then return r end end
  error("no row " .. key)
end
local function plus(key, n) for _ = 1, n or 1 do row(key):Step(1) end end
local function minus(key, n) for _ = 1, n or 1 do row(key):Step(-1) end end

-- Clicking a frame picks its tab
T.mover.scripts.OnMouseUp(T.mover)
check(E.tab == "target" and row("auras") and row("elite"), "clicking a frame opens its settings")
check(math.abs(T.mover.fill.ctex[4] - 0.45) < 1e-9 and math.abs(P.mover.fill.ctex[4] - 0.2) < 1e-9, "the chosen frame stands out")
Bar.mover.scripts.OnMouseUp(Bar.mover)
check(E.tab == "cast" and row("castWidth"), "castbar overlay opens its tab")
E:Select("player")
local hasAuras = false
for _, r in ipairs(E.rows) do if r.shown ~= false and r.def.key == "auras" then hasAuras = true end end
check(not hasAuras, "only the target has aura settings")

-- Sizes
local w0 = P.w
plus("width", 2)
check(P.w == w0 + 10 and U:Cfg("player").width == w0 + 10 and T.w == 230, "width changes this frame only")
check(row("width").value.text == tostring(w0 + 10), "the panel shows the new value")
minus("width", 2)
plus("hpHeight", 5)
check(P.hp.h == 25 and P.h == 18 + 25 + 1 + 12 + 1, "health bar height")
minus("hpHeight", 5)
for _ = 1, 60 do minus("hpHeight") end
check(P.hp.h == 4, "stops at the minimum")
U:Cfg("player").hpHeight = 20
U:Layout(P)
plus("pwHeight", 2)
check(P.pw.h == 14, "power bar height")
minus("pwHeight", 2)
minus("power")
check(P.pw.shown == false and P.h == 18 + 20 + 1, "power bar off, frame shrinks")
plus("power")
check(P.pw.shown and P.h == 18 + 20 + 1 + 12 + 1, "and back")

-- Fonts
plus("nameSize", 3)
check(P.name.font[2] == 16 and P.level.font[2] == 15 and P.h == 21 + 20 + 1 + 12 + 1, "name font size, header grows to fit")
minus("nameSize", 3)
plus("barSize", 2)
check(P.hpText.font[2] == 14 and P.hpPct.font[2] == 14, "health font size")
minus("barSize", 2)
plus("pwSize")
check(P.pwText.font[2] == 11, "power font size")
minus("pwSize")

-- What shows
plus("name")
check(U:Cfg("player").name == "first" and P.name.text == "Test" and P.name.shown, "first name only")
plus("name")
check(U:Cfg("player").name == "off" and P.name.shown == false, "no name")
minus("level")
check(P.level.shown == false, "no level")
check(P.tag.points[1][2] == P, "tags move over when the level goes")
minus("tags")
check(P.tag.shown == false and P.strip.shown == false and P.h == 1 + 20 + 1 + 12 + 1 and P.hp.points[1][5] == -1, "nothing in the header: the strip goes too")
plus("tags"); plus("level"); plus("name")
check(U:Cfg("player").name == "full" and P.name.text == "Test Hero" and P.strip.shown and P.h == 18 + 20 + 1 + 12 + 1, "and back")
minus("hpText")
check(P.hpText.shown == false, "no health numbers")
UNITS.player.dead = true
fire("UNIT_HEALTH", "player")
check(P.hpText.shown and P.hpText.text == "Dead", "Dead still shows with numbers off")
UNITS.player.dead = nil
fire("UNIT_HEALTH", "player")
check(P.hpText.shown == false, "and goes again")
plus("hpText")
minus("hpPct")
check(P.hpPct.shown == false, "no health percent")
plus("hpPct")
minus("pwText")
check(P.pwText.shown == false, "no power numbers")
plus("pwText")

-- Class colours per frame
minus("classColor")
check(P.hp:GetStatusBarTexture().vc[2] == 0.7 and U:Cfg("target").classColor, "class colours off for this frame only")
plus("classColor")
check(P.hp:GetStatusBarTexture().vc[2] == 0.44, "and on")

-- Portraits
portraitCalls = {}
plus("portrait")
check(U:Cfg("player").portrait == "2d" and P.portrait2d.shown, "flat portrait")
check(portraitCalls[1] and portraitCalls[1][1] == P.portrait2d and portraitCalls[1][2] == "player", "painted from the unit")
local size = P.h - 2
check(P.portrait2d.w == size and P.portrait2d.h == size, "square, the frame's height")
check(P.hp.points[1][4] == size + 2 and P.hp.points[2][4] == -1, "bars move over")
plus("portraitSide")
check(P.hp.points[1][4] == 1 and P.hp.points[2][4] == -(size + 2) and P.portrait2d.points[1][1] == "TOPRIGHT", "other side")
minus("portraitSide")
plus("portrait")
check(U:Cfg("player").portrait == "3d" and P.portrait3d and P.portrait3d.shown and P.portrait2d.shown == false, "3D portrait")
check(P.portrait3d.modelUnit == "player" and P.portrait3d.points[1][1] == "TOPLEFT", "model of the unit")
P.portrait3d.modelUnit = nil
U:Update(P, true)
check(P.portrait3d.modelUnit == nil, "the model isn't reloaded when nothing changed")
U:Update(P)
check(P.portrait3d.modelUnit == "player", "a real update does reload it")
P.portrait3d.modelUnit = nil
fire("UNIT_MODEL_CHANGED", "player")
check(P.portrait3d.modelUnit == "player", "new model when the game says so")
plus("portrait")
check(U:Cfg("player").portrait == "off" and P.portrait3d.shown == false and P.hp.points[1][4] == 1, "portrait off, bars back")

-- Target of target: its own settings, including a light update every so often
E:Select("tot")
plus("portrait")
check(ToT.portrait2d.shown and U:Cfg("player").portrait == "off", "each frame has its own portrait setting")
portraitCalls = {}
ToT.scripts.OnUpdate(ToT, 1)
check(#portraitCalls == 0, "target of target doesn't repaint an unchanged portrait")
minus("portrait")
plus("level")
check(ToT.level.shown and ToT.level.text ~= nil, "small frames can show their level too")
minus("level")
plus("hpPct")
check(ToT.hpPct.shown and ToT.hpPct.text:find("%%"), "and numbers")
minus("hpPct")

-- Elite and rare
E:Select("target")
local edge, glow = T.eliteGlow.edges[1], T.eliteGlow.glow[1]
check(edge.shown == false and glow.shown == false, "nothing while previewing as normal")
plus("previewClass")
check(row("previewClass").current == "Elite" and edge.shown and edge.ctex[1] == 1 and edge.ctex[2] == 0.82 and glow.shown and T.tag.text:find("Elite"), "preview: gold border, glow and tag")
plus("previewClass")
check(row("previewClass").current == "Rare" and edge.ctex[3] == 1 and T.tag.text:find("Rare"), "preview: rare")
plus("previewClass", 2)
check(row("previewClass").current == "Boss" and edge.ctex[1] == 1 and edge.ctex[2] == 0.33, "preview: boss")
minus("elite")
check(U:Cfg("target").elite == "border" and edge.shown and glow.shown == false, "border only")
minus("elite")
check(U:Cfg("target").elite == "off" and edge.shown == false and T.tag.text:find("Boss"), "style off, the tag has its own switch")
plus("elite", 2)
check(U:Cfg("target").elite == "glow", "back to border and glow")
check(T.over.flevel > T.flevel, "drawn above the bars")

-- Auras and the target's cast bar
plus("auraSize", 3)
check(U:Cfg("target").auraSize == 25, "aura size")
check(TBar.shown and TBar.preview, "the target's cast bar shows to set it up")
plus("targetCastH", 2)
check(TBar.h == 20 and KUIDB.targetCastH == 20, "target cast bar height")
minus("targetCastH", 2)
minus("targetCast")
check(KUIDB.targetCast == false and TBar.shown == false and TBar.off, "target cast bar off, straight away")
castInfo.target = { name = "Shadow Bolt", icon = "s", st = 102000, en = 104000, guid = "t5" }
fire("UNIT_SPELLCAST_START", "target", "t5")
check(TBar.shown == false, "and it stays off")
castInfo.target = nil
plus("targetCast")
check(KUIDB.targetCast and TBar.shown, "and on again")

-- Castbar tab
E:Select("cast")
plus("castWidth", 2)
check(Bar.w == 270 and KUIDB.castWidth == 270, "castbar width")
minus("castWidth", 2)
plus("castHeight", 4)
check(Bar.h == 26 and Bar.icon.w == 24, "castbar height, icon keeps up")
minus("castHeight", 4)
plus("castSize", 2)
check(Bar.label.font[2] == 14 and Bar.time.font[2] == 14, "castbar font size")
minus("castSize", 2)
minus("castIcon")
check(Bar.icon.shown == false and Bar.bar.points[1][2] == Bar, "no icon: the bar takes its place")
check(TBar.icon.shown == false, "both bars follow")
plus("castIcon")
check(Bar.icon.shown and Bar.bar.points[1][2] == Bar.icon, "icon back")
minus("castTime")
check(Bar.time.shown == false and Bar.label.points[2][2] == Bar.bar, "no time: the name gets the room")
plus("castTime")
minus("castSpark")
check(Bar.spark.shown == false, "no spark")
plus("castSpark")
plus("castScale", 2)
check(math.abs(Bar.scale - 1.1) < 1e-9, "castbar scale")
Bar.mover.scripts.OnDragStop(Bar.mover)
E.reset.scripts.OnClick()
check(KUIDB.castWidth == 260 and KUIDB.castScale == 1 and not KUIDB.castLeft and Bar.points[1][1] == "CENTER", "reset the castbar")

-- Everything-wide settings
plus("font")
check(KUIDB.font ~= "barlow" and P.name.font[1]:find("Barlow"), "font from the panel")
minus("font")
check(KUIDB.font == "barlow", "and back")
minus("alpha")
check(math.abs(KUIDB.alpha - 0.55) < 1e-9 and math.abs(P.fuiPanel.fill.ctex[4] - 0.55) < 1e-9, "opacity from the panel")
plus("alpha")

-- Reset a frame
E:Select("target")
plus("width", 3)
minus("level")
T.mover.scripts.OnDragStop(T.mover)
check(KUIDB.targetLeft == 300, "target spot saved")
minus("targetCast")
E.reset.scripts.OnClick()
check(U:Cfg("target").width == 230 and U:Cfg("target").level and T.w == 230 and T.level.shown, "reset this frame")
check(not KUIDB.targetLeft and T.points[1][1] == "CENTER", "spot too")
check(KUIDB.targetCast and not TBar.off, "and its cast bar")

-- Target-of-target and pet can move too
ToT.mover.scripts.OnDragStop(ToT.mover)
check(KUIDB.totLeft == 300, "target of target spot saved")
U:Place()
check(ToT.points[1][1] == "TOPLEFT" and ToT.points[1][2] == UIParent, "and used")
E:Select("tot")
E.reset.scripts.OnClick()
check(ToT.points[1][2] == T and Pet.points[1][2] == P, "by default they sit beside their frames")

-- The panel doesn't change anything in combat
E:Select("player")
local widthNow = U:Cfg("player").width
inCombat = true
plus("width")
E.reset.scripts.OnClick()
check(U:Cfg("player").width == widthNow, "nothing changes in combat")
inCombat = false

-- Closing
T.mover.scripts.OnMouseUp(T.mover)
plus("previewClass")
E.done.scripts.OnClick()
check(not Panel.shown and not U.unlocked and P.mover.shown == false and Bar.mover.shown == false, "Done closes it")
check(T.unit == "target" and unitWatch[T] and U.previewClass == nil, "frames back to real units, preview gone")
check(TBar.shown == false and not TBar.preview, "target cast bar back to casts only")
U:Update(T)
check(T.eliteGlow.edges[1].ctex and T.tag.text:find("Elite"), "the real target's elite tag again")
check(T.eliteGlow.edges[1].shown and T.eliteGlow.edges[1].ctex[2] == 0.82, "a real elite gets the gold border")
UNITS.target.classif = "normal"
fire("UNIT_CLASSIFICATION_CHANGED", "target")
check(T.eliteGlow.edges[1].shown == false, "a normal mob doesn't")
UNITS.target.classif = "elite"
SlashCmdList.KUI("edit")
check(Panel.shown, "/kui edit reopens")
SlashCmdList.KUI("edit")
check(not Panel.shown and not U.unlocked, "and closes")
SlashCmdList.KUI("unlock")
check(Panel.shown, "/kui unlock is the same thing")
Panel:Hide() -- Esc
check(not U.unlocked and P.mover.shown == false, "Esc leaves the edit mode")
SlashCmdList.KUI("edit")
fire("PLAYER_REGEN_DISABLED")
check(not Panel.shown and not U.unlocked, "combat closes it")
inCombat = true
SlashCmdList.KUI("edit")
check(not Panel.shown and chat[#chat]:find("combat"), "can't open in combat")
inCombat = false

-- Panel position
SlashCmdList.KUI("edit")
SlashCmdList.KUI("edit")
KUIDB.editLeft, KUIDB.editTop = 111, 222
SlashCmdList.KUI("edit")
check(Panel.points[1][4] == 111 and Panel.points[1][5] == 222, "the panel remembers its spot")
SlashCmdList.KUI("edit")

-- Settings from before the edit mode carry over
KUIDB.frameCfg = nil
KUIDB.classColor, KUIDB.frameScale = false, 1.3
check(U:Cfg("player").classColor == false and U:Cfg("target").scale == 1.3, "older settings carry over")
KUIDB.classColor, KUIDB.frameScale = true, 1
KUIDB.frameCfg = nil
U:Update(P)
check(U:Cfg("player").width == 230 and U:Cfg("player").portrait == "off", "new settings get defaults")
-- A frame whose saved settings are missing a newer option still works
KUIDB.frameCfg = { player = { width = 300 } }
check(U:Cfg("player").width == 300 and U:Cfg("player").nameSize == 13, "missing options filled in, saved ones kept")
KUIDB.frameCfg = nil
U:LayoutAll()
UnitName = realName

;(function() -- a function of its own: Lua allows 200 locals per function
print("== Settings controls")
SlashCmdList.KUI("edit")
local E2 = ns.EditMode
E2:Select("player")
local function rowOf(key)
  for _, r in ipairs(E2.rows) do if r.def.key == key then return r end end
  error("no row " .. key)
end
-- slider
local wr = rowOf("width")
check(wr.slider.minv == 80 and wr.slider.maxv == 500 and wr.slider.value == 230, "slider shows the setting and its range")
wr.slider.scripts.OnValueChanged(wr.slider, 262)
check(U:Cfg("player").width == 260 and P.w == 260 and wr.value.text == "260", "dragging a slider snaps to its step and applies")
wr.slider.scripts.OnMouseWheel(wr.slider, 1)
check(U:Cfg("player").width == 265, "wheel up steps it")
wr.slider.scripts.OnMouseWheel(wr.slider, -1)
wr.slider.scripts.OnValueChanged(wr.slider, 9999)
check(U:Cfg("player").width == 500, "limited to its range")
wr.slider.scripts.OnValueChanged(wr.slider, 230)
wr.filling = true
wr.slider.scripts.OnValueChanged(wr.slider, 300)
wr.filling = false
check(U:Cfg("player").width == 230, "the panel filling itself in doesn't count as a change")
local sr = rowOf("scale")
sr.slider.scripts.OnValueChanged(sr.slider, 1.2)
check(math.abs(P.scale - 1.2) < 1e-9 and sr.value.text == "1.20", "scale shows two decimals")
sr.slider.scripts.OnValueChanged(sr.slider, 1)
-- switch
local lr = rowOf("level")
check(lr.switch.track.ctex[1] == 0.5 and lr.switch.knob.points[1][1] == "RIGHT", "a switch that's on: accent, knob right")
lr.switch.scripts.OnClick(lr.switch)
check(U:Cfg("player").level == false and P.level.shown == false, "clicking the switch")
check(lr.switch.track.ctex[1] == 1 and lr.switch.knob.points[1][1] == "LEFT", "off: grey, knob left")
lr.switch.scripts.OnClick(lr.switch)
-- segments
local nr = rowOf("name")
check(#nr.segments == 3 and nr.segments[1].text.text == "Full", "choices side by side")
check(nr.segments[1].bg.ctex[1] == 0.5 and nr.segments[2].bg.ctex[1] == 1, "the chosen one is lit")
nr.segments[2].scripts.OnClick(nr.segments[2])
check(U:Cfg("player").name == "first" and nr.current == "First" and nr.segments[2].bg.ctex[1] == 0.5, "clicking a choice")
nr.segments[1].scripts.OnClick(nr.segments[1])
-- stepper for long lists
local fr = rowOf("font")
check(rawget(fr, "segments") == nil and fr.value.text == "Barlow", "long lists step instead")
fr.plus.scripts.OnClick(fr.plus)
check(KUIDB.font ~= "barlow" and fr.value.text ~= "Barlow", "next font")
fr.minus.scripts.OnClick(fr.minus)
check(KUIDB.font == "barlow", "previous font")
-- rows that have no effect dim
local pr, phr = rowOf("power"), rowOf("pwHeight")
check(phr.alpha == 1, "a live row is bright")
pr.switch.scripts.OnClick(pr.switch)
check(phr.alpha == 0.45, "power bar off: its settings dim")
pr.switch.scripts.OnClick(pr.switch)
check(phr.alpha == 1, "and wake up")
check(rowOf("portraitSide").alpha == 0.45, "portrait side dims while the portrait is off")
-- layout
local pg = E2.pages.player
local cols = {}
for _, r in ipairs(pg.rows) do cols[r.parent] = true end
local nCards, xs = 0, {}
for card in pairs(cols) do nCards = nCards + 1; xs[card.points[1][4]] = true end
local nCols = 0
for _ in pairs(xs) do nCols = nCols + 1 end
check(nCards >= 5 and nCols == 2, "rows grouped into cards, in two columns")
for card in pairs(cols) do check(card.title.color[1] == 0.5, "card titles in the accent colour") end
check(Panel.h == 28 + 26 + 8 + pg.height + 38, "window fits this page")
E2:Select("target")
local tallTarget = Panel.h
E2:Select("player")
check(tallTarget > Panel.h, "and resizes for a bigger one")
check(tallTarget < 768, "even the biggest page fits a screen: " .. tallTarget)
check(E2.tabs[1].line.shown and not E2.tabs[2].line.shown, "the current tab is underlined")
E2.tabs[2].scripts.OnClick(E2.tabs[2])
check(E2.tab == "target" and E2.tabs[2].line.shown and not E2.tabs[1].line.shown, "clicking a tab")
check(E2.done.bg.ctex[1] == 0.5, "Done is the filled button")
-- blocked in combat
E2:Select("player")
inCombat = true
wr.slider.scripts.OnValueChanged(wr.slider, 400)
check(U:Cfg("player").width == 230 and wr.slider.value == 230, "a slider snaps back in combat")
inCombat = false
SlashCmdList.KUI("edit")

-- Bag settings use the same controls
local bp = KUIBagSettings
local bagRow = {}
for _, r in ipairs(bp.rows) do bagRow[r.def.key] = r end
check(bagRow.bagCols.slider and bagRow.categories.switch and #bagRow.outline.segments == 3 and bagRow.font.value, "bag settings: same controls")
bagRow.bagCols.slider.scripts.OnValueChanged(bagRow.bagCols.slider, 12)
check(KUIDB.bagCols == 12 and bagRow.bagCols.value.text == "12", "bag slider applies")
local bagWin = ns.Bags.windows.bags.frame
ns.Bags:Open()
bagRow.bagCols.slider.scripts.OnValueChanged(bagRow.bagCols.slider, 11)
check(bagWin.w == 11 * KUIDB.bagSize + 10 * KUIDB.gapX + 16, "and the bag window redraws: " .. tostring(bagWin.w))
bagRow.bagCols.slider.scripts.OnValueChanged(bagRow.bagCols.slider, 10)
local catBefore = KUIDB.categories
bagRow.categories.switch.scripts.OnClick(bagRow.categories.switch)
check(KUIDB.categories ~= catBefore, "bag switch applies")
bagRow.categories.switch.scripts.OnClick(bagRow.categories.switch)
SlashCmdList.KUI("alpha 0.85")
check(bagRow.alpha.value.text == "0.85", "follows a change made elsewhere")

print("== Minimap icon")
local Ic = ns.MinimapIcon
local Btn = KUIMinimapButton
check(Btn and Btn.parent == Minimap and Btn.glyph.text == "k" and Btn.glyph.color[1] == 0.5, "the icon, on the map")
check(KUIDB.icon and KUIDB.iconAngle == 315, "defaults")
-- position: inside the corners of the square map
KUIDB.map = true
Minimap:SetSize(140, 140)
Ic:Place()
local pt = Btn.points[1]
check(pt[2] == Minimap and pt[1] == "CENTER" and math.abs(pt[4] - 55) < 1e-9 and math.abs(pt[5] + 55) < 1e-9, "bottom right corner, inside the map")
KUIDB.iconAngle = 0
Ic:Place()
check(math.abs(Btn.points[1][4] - 55) < 1e-9 and math.abs(Btn.points[1][5]) < 1e-9, "follows the edge")
KUIDB.map = false
KUIDB.iconAngle = 180
Ic:Place()
check(math.abs(Btn.points[1][4] + 70) < 1e-9, "on the edge of a round map")
KUIDB.map = true
-- dragging
function Minimap:GetCenter() return 500, 300 end
function GetCursorPosition() return 500, 500 end
Btn.scripts.OnDragStart(Btn)
Btn.scripts.OnUpdate(Btn, 0.01)
check(math.abs(KUIDB.iconAngle - 90) < 1e-6, "dragging moves it around")
Btn.scripts.OnDragStop(Btn)
check(Btn.scripts.OnUpdate == nil, "and stops")
KUIDB.iconAngle = 315
Ic:Place()
-- tooltip
Btn.scripts.OnEnter(Btn)
Btn.scripts.OnLeave(Btn)

-- the menu
check(KUIMenu == nil or not KUIMenu.shown, "menu shut to start")
Btn.scripts.OnClick(Btn, "LeftButton")
local Menu = KUIMenu
check(Menu and Menu.shown, "clicking the icon opens the menu")
check(UISpecialFrames[#UISpecialFrames] == "KUIMenu", "Esc closes it")
local function menuRow(text)
  for _, r in ipairs(Ic.rows) do
    if r.shown ~= false and r.item and r.item.text == text then return r end
  end
end
local names = {}
for _, r in ipairs(Ic.rows) do if r.shown ~= false and r.item then names[#names + 1] = r.item.text end end
check(names[1] == "Customise" and names[2] == "Edit mode", "Edit mode comes first: " .. table.concat(names, ", "))
for _, want in ipairs({ "Bag settings", "Rares and treasures", "Sample cast", "Sample loot window", "Sample rare alert", "Unit frames", "Castbar", "Bags", "Rare scanner", "Hide this icon" }) do
  check(menuRow(want), "menu has " .. want)
end
check(not menuRow("Minimap icon"), "its own switch isn't in the list")
check(not menuRow("Reload to apply"), "no reload offered when nothing changed")
check(menuRow("Customise").item.kind == "section" and menuRow("Customise").text.color[1] == 0.5, "section titles in the accent colour")
Btn.scripts.OnClick(Btn, "RightButton")
check(not Menu.shown, "clicking again closes it")

-- edit mode from the menu
Btn.scripts.OnClick(Btn)
local em = menuRow("Edit mode")
em.scripts.OnClick(em)
check(U.unlocked and KUIEditMode.shown and not Menu.shown, "the menu opens the edit mode and gets out of the way")
Btn.scripts.OnClick(Btn)
check(menuRow("Edit mode").note.text == "open", "shows it's open")
em = menuRow("Edit mode")
em.scripts.OnClick(em)
check(not U.unlocked and not KUIEditMode.shown, "and closes it")
inCombat = true
Btn.scripts.OnClick(Btn)
em = menuRow("Edit mode")
check(em.note.text == "not in combat", "in combat it says why not")
em.scripts.OnClick(em)
check(not U.unlocked and Menu.shown, "and does nothing")
inCombat = false
Btn.scripts.OnClick(Btn)

-- the other actions
Btn.scripts.OnClick(Btn)
local c = menuRow("Sample cast")
c.scripts.OnClick(c)
check(Bar.label.text == "Sample cast" and Bar.shown and not Menu.shown, "sample cast")
Bar.scripts.OnUpdate(Bar, 0)
now = now + 5
Bar.scripts.OnUpdate(Bar, 0.1)
Bar.scripts.OnUpdate(Bar, 2)
TBar.scripts.OnUpdate(TBar, 0.1)
TBar.scripts.OnUpdate(TBar, 2)
Btn.scripts.OnClick(Btn)
c = menuRow("Sample loot window")
c.scripts.OnClick(c)
check(KUILoot.shown and KUILoot.title.text == "Sample loot", "sample loot window")
KUILoot:Hide()
Btn.scripts.OnClick(Btn)
c = menuRow("Bag settings")
KUIBagSettings:Hide()
c.scripts.OnClick(c)
check(KUIBagSettings.shown, "bag settings")
KUIBagSettings:Hide()
local listCalls = 0
local realToggle = ns.Rares.ToggleList
ns.Rares.ToggleList = function() listCalls = listCalls + 1 end
Btn.scripts.OnClick(Btn)
c = menuRow("Rares and treasures")
c.scripts.OnClick(c)
check(listCalls == 1, "rare list")
ns.Rares.ToggleList = realToggle
local testCalls = 0
local realTest = ns.Rares.Test
ns.Rares.Test = function() testCalls = testCalls + 1 end
Btn.scripts.OnClick(Btn)
c = menuRow("Sample rare alert")
c.scripts.OnClick(c)
check(testCalls == 1, "sample rare alert")
ns.Rares.Test = realTest

-- switches stay open and offer a reload
local reloads = 0
ReloadUI = function() reloads = reloads + 1 end
Btn.scripts.OnClick(Btn)
c = menuRow("Bags")
check(c.track.shown and c.track.ctex[1] == 0.5, "parts have switches, lit when on")
c.scripts.OnClick(c)
check(KUIDB.bags == false and Menu.shown, "switching one leaves the menu open")
check(menuRow("Bags").track.ctex[1] == 1, "switch shows off")
local re = menuRow("Reload to apply")
check(re and re.bg.ctex[1] == 0.5, "and offers a reload")
c = menuRow("Bags")
c.scripts.OnClick(c)
check(KUIDB.bags and not menuRow("Reload to apply"), "switching it back removes the offer")
c = menuRow("Bags")
c.scripts.OnClick(c)
re = menuRow("Reload to apply")
re.scripts.OnClick(re)
check(reloads == 1, "reloads")
KUIDB.bags = true

-- closing by clicking elsewhere
Btn.scripts.OnClick(Btn)
check(Menu.events.GLOBAL_MOUSE_DOWN, "listens for clicks only while open")
local overMenu, overIcon = true, false
MouseIsOver = function(f) if f == Menu then return overMenu end; return overIcon end
Menu.scripts.OnEvent(Menu, "GLOBAL_MOUSE_DOWN")
check(Menu.shown, "a click on the menu keeps it open")
overMenu, overIcon = false, true
Menu.scripts.OnEvent(Menu, "GLOBAL_MOUSE_DOWN")
check(Menu.shown, "a click on the icon is left to the icon")
overIcon = false
Menu.scripts.OnEvent(Menu, "GLOBAL_MOUSE_DOWN")
check(not Menu.shown and not Menu.events.GLOBAL_MOUSE_DOWN, "a click anywhere else closes it")

-- hiding
Btn.scripts.OnClick(Btn)
c = menuRow("Hide this icon")
c.scripts.OnClick(c)
check(KUIDB.icon == false and not Btn.shown and chat[#chat]:find("/kui icon on"), "hide this icon, and how to get it back")
SlashCmdList.KUI("icon on")
check(KUIDB.icon and chat[#chat]:find("reload"), "/kui icon on")
Btn:Show()
-- parts that are off leave the menu
local keepBags = ns.Bags.enabled
ns.Bags.enabled = nil
Btn.scripts.OnClick(Btn)
check(not menuRow("Bag settings"), "bag settings not offered when bags are off")
Btn.scripts.OnClick(Btn)
ns.Bags.enabled = keepBags
ns.Bags.enabled = true

end)()

;(function()
print("== Rare alert in combat")
local R, A, Tgt = ns.Rares, KUIRareAlert, KUIRareTarget
local spot = A.targetSpot
-- Everything the game refuses to do to a protected button in combat, counted.
local touched = {}
for _, m in ipairs({ "SetPoint", "ClearAllPoints", "SetAllPoints", "SetSize", "Show", "Hide", "SetAttribute", "SetAlpha", "SetParent", "EnableMouse" }) do
  local orig = Tgt[m]
  rawset(Tgt, m, function(...)
    if inCombat then touched[#touched + 1] = m end
    return orig(...)
  end)
end
local drivers = {}
RegisterStateDriver = function(f, _, v) drivers[f] = v end
UnregisterStateDriver = function(f) drivers[f] = nil end
inCombat = false
R:Dismiss()
now = now + 1000
R:Spotted({ id = 70001, name = "Test Rare", source = "nameplate" })
check(A.shown and Tgt.shown and Tgt.attrs.macrotext:find("/target Test Rare"), "alert and target button up")
-- The bug: a protected frame makes whatever it's anchored to protected too.
check(Tgt.parent == UIParent, "the target button isn't a child of the alert")
check(#Tgt.points == 1, "one anchor")
for _, p in ipairs(Tgt.points) do
  check(p[2] == UIParent, "anchored to the screen, never to the alert or anything on it")
end
check(Tgt.points[1][4] == 300 and Tgt.points[1][5] == 200, "sits over its spot")
check(Tgt.w == spot.w and Tgt.h == spot.h, "same size as its spot")
check(drivers[Tgt] == "[combat] hide; show", "hides itself in combat, securely")

-- Combat starts with the alert up, the way you'd pull a rare.
fire("PLAYER_REGEN_DISABLED")
check(spot.text.text == "After combat", "the spot says so")
inCombat = true
local wp
TomTom = { AddWaypoint = function(_, m, x, y, o) wp = o.title; return 1 end, RemoveWaypoint = function() end }
R.current.m, R.current.x, R.current.y = 1411, 0.5, 0.5
A.way.scripts.OnClick(A.way)
check(wp == "Test Rare", "Waypoint works in combat")
A.close.scripts.OnClick(A.close)
check(not A.shown, "x closes it in combat")
check(#touched == 0, "without touching the protected button: " .. table.concat(touched, ","))

-- A new rare while already in combat, then Ignore.
now = now + 1000
R:Spotted({ id = 70002, name = "Second Rare", source = "nameplate" })
check(A.shown and spot.text.text == "After combat", "a new alert in combat")
R.current.until_ = now - 1
A.scripts.OnUpdate(A, 1)
check(not A.shown, "and the alert's own timeout can close it in combat")
now = now + 1000
R:Spotted({ id = 70003, name = "Third Rare", source = "nameplate" })
A.ignore.scripts.OnClick(A.ignore)
check(not A.shown and KUIDB.rareIgnored[70003], "Ignore works in combat")
now = now + 1000
R:Spotted({ id = 70004, name = "Fourth Rare", source = "nameplate" })
A.scripts.OnDragStart(A)
A.scripts.OnDragStop(A)
check(#touched == 0, "dragging the alert in combat touches nothing either: " .. table.concat(touched, ","))

-- Combat ends with an alert still up.
inCombat = false
fire("PLAYER_REGEN_ENABLED")
check(Tgt.shown and Tgt.attrs.macrotext:find("Fourth Rare") and spot.text.text == "Target", "target button back for the current rare")
rawset(spot, "GetLeft", function() return 500 end)
A.scripts.OnDragStop(A)
check(Tgt.points[1][4] == 500 and #Tgt.points == 1, "and it follows when the alert is dragged")
rawset(spot, "GetLeft", nil)
R:Dismiss()
check(not Tgt.shown and drivers[Tgt] == nil, "closing the alert removes the button and its driver")

-- Combat ends with no alert: nothing comes back.
now = now + 1000
R:Spotted({ id = 70005, name = "Fifth Rare", source = "nameplate" })
fire("PLAYER_REGEN_DISABLED")
inCombat = true
A.close.scripts.OnClick(A.close)
inCombat = false
fire("PLAYER_REGEN_ENABLED")
check(not Tgt.shown and drivers[Tgt] == nil, "the button stays gone if the alert was closed in combat")

-- Without the state driver API it still hides, at the last safe moment.
local rd = RegisterStateDriver
RegisterStateDriver = nil
now = now + 1000
R:Spotted({ id = 70006, name = "Sixth Rare", source = "nameplate" })
check(Tgt.shown, "button up")
fire("PLAYER_REGEN_DISABLED")
check(not Tgt.shown, "hidden as combat starts")
fire("PLAYER_REGEN_ENABLED")
R:Dismiss()
RegisterStateDriver = rd

-- Treasure alerts have no target button.
now = now + 1000
R:Show({ treasure = true, name = "Chest", key = "chest1" })
check(not Tgt.shown and drivers[Tgt] == nil, "no target button for treasure")
fire("PLAYER_REGEN_DISABLED")
inCombat = true
A.close.scripts.OnClick(A.close)
check(not A.shown, "treasure alert closes in combat")
inCombat = false

-- Skull only out of combat.
local marked = 0
SetRaidTarget = function() marked = marked + 1 end
UNITS.target.classif = "rare"
UNITS.target.dead, UNITS.target.raid = nil, nil
inCombat = true
R:CheckUnit("target", "target")
check(marked == 0, "no skull attempt in combat")
inCombat = false
R:CheckUnit("target", "target")
check(marked == 1, "skull out of combat")
UNITS.target.classif = "elite"
R:Dismiss()

print("== Blocked actions")
KUIDB.blockedLog = nil
local before = #chat
fire("ADDON_ACTION_BLOCKED", "SomeOtherAddon", "Frame:Hide()")
check(#chat == before and not KUIDB.blockedLog, "other add-ons are their own business")
fire("ADDON_ACTION_BLOCKED", "KUI", "Frame:Hide()")
check(#chat == before + 1 and chat[#chat]:find("Frame:Hide()", 1, true), "kUI says what was blocked")
fire("ADDON_ACTION_BLOCKED", "KUI", "Frame:Hide()")
check(#chat == before + 1 and KUIDB.blockedLog["Frame:Hide()"] == 2, "once in chat, but counted")
inCombat = true
fire("ADDON_ACTION_FORBIDDEN", "KUI", "SetRaidTarget()")
check(chat[#chat]:find("SetRaidTarget", 1, true) and chat[#chat]:find("in combat"), "forbidden too, and whether it was in combat")
inCombat = false
KUIDB.blockedLog = nil
end)()

-- A /reload in combat waits, because secure frames can't be made then.
U.started = nil
inCombat = true
U:Enable()
check(not U.started, "in combat: waits")
inCombat = false
fire("PLAYER_REGEN_ENABLED")
check(U.started, "starts when combat ends")

for _, m in ipairs(chat) do print("  chat: " .. m) end
print(string.format("\n%d passed, %d failed", passed, failed))
