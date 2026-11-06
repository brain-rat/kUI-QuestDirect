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
allFontStrings = {}
function Mock:CreateFontString() local t = new("FontString", nil, self); t.text = ""; allFontStrings[#allFontStrings + 1] = t; return t end
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
  UnitCastingInfo = function(u) local c = castInfo[u]; if c then local d = c.display; if d == nil then d = c.name end; return c.name, d, c.icon, c.st, c.en, false, c.guid, c.locked, c.spellID end end,
  UnitChannelInfo = function(u) local c = chanInfo[u]; if c then local d = c.display; if d == nil then d = c.name end; return c.name, d, c.icon, c.st, c.en, false, c.locked, c.spellID end end,
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

-- Action bars world
local stateDrivers, attrDrivers = {}, {}
local function barStateDriver(f, kind, v) stateDrivers[f] = stateDrivers[f] or {}; stateDrivers[f][kind] = v end
RegisterStateDriver = barStateDriver
local function barStateDriverOff(f, kind) if stateDrivers[f] then stateDrivers[f][kind] = nil end end
UnregisterStateDriver = barStateDriverOff
function RegisterAttributeDriver(f, kind, v) attrDrivers[f] = attrDrivers[f] or {}; attrDrivers[f][kind] = v end
function Mock:GetAttribute(k) return self.attrs and self.attrs[k] end
function Mock:SetAttributeNoHandler(k, v) self.attrs = self.attrs or {}; self.attrs[k] = v end
function Mock:WrapScript(f, script, pre) f.wrapped = f.wrapped or {}; f.wrapped[script] = pre end
function Mock:SetJustifyH(j) self.justify = j end
function Mock:SetTexCoord(...) self.texCoord = { ... } end
function Mock:RemoveMaskTexture(t) self.maskRemoved = t end
function Mock:GetCheckedTexture() self.checkTex = self.checkTex or new("Texture"); return self.checkTex end
function Mock:SetChecked(v) self.checked = v end
function Mock:SetHideCountdownNumbers(v) self.hideNumbers = v end
function Mock:SetCountdownFont(n) self.countdownFont = n end
function Mock:SetSwipeColor(...) self.swipe = { ... } end
function Mock:Clear() self.cleared = true end
function Mock:SetFrameStrata(s) self.strata = s end
function Mock:EnableMouse(v) self.mouseOn = v end
local baseHook = hooksecurefunc
function hooksecurefunc(t, k, fn)
  if type(t) == "string" then return baseHook(_G, t, k) end
  return baseHook(t, k, fn)
end
local barKeys, barActions, equipped = {}, {}, {}
local boundKeys, bindCalls = {}, 0
function GetBindingKey(cmd) return unpack(barKeys[cmd] or {}) end
function SetOverrideBindingClick(owner, _, key, name, button) bindCalls = bindCalls + 1; boundKeys[key] = { owner = owner, name = name, button = button } end
function ClearOverrideBindings(owner) for k, v in pairs(boundKeys) do if v.owner == owner then boundKeys[k] = nil end end end
function HasAction(slot) return barActions[slot] == true end
function IsEquippedAction(slot) return equipped[slot] == true end
local barToggles = { true, false, false, false }
function GetActionBarToggles() return unpack(barToggles) end
function CreateFont(name) local f = new("Font", name); return f end
local forms = {}
function GetNumShapeshiftForms() return #forms end
function GetShapeshiftFormInfo(i) local x = forms[i]; if x then return x.icon, x.active, x.castable end end
function GetShapeshiftFormCooldown(i) local x = forms[i]; if x then return x.cdStart or 0, x.cdDur or 0, 1 end end
local petActions = {}
function GetPetActionInfo(i) return petActions[i] end
NUM_PET_ACTION_SLOTS = 10
local function actionButtonParts(f)
  f.icon = f:CreateTexture()
  f.IconMask = f:CreateTexture()
  f.NormalTexture = f:CreateTexture()
  f.SlotArt, f.SlotBackground, f.Border, f.Flash = f:CreateTexture(), f:CreateTexture(), f:CreateTexture(), f:CreateTexture()
  f.SpellHighlightTexture, f.NewActionTexture = f:CreateTexture(), f:CreateTexture()
  f.SpellCastAnimFrame, f.InterruptDisplay = new("Frame", nil, f), new("Frame", nil, f)
  f.HotKey, f.Count, f.Name = f:CreateFontString(), f:CreateFontString(), f:CreateFontString()
  f.cooldown = new("Cooldown", nil, f)
  f.buttonNormal = f:CreateTexture() -- not always the same texture as the NormalTexture key
  f.GetNormalTexture = function(self) return self.buttonNormal end
end
local baseCreate2 = CreateFrame
function CreateFrame(kind, name, parent, template, id)
  local f = baseCreate2(kind, name, parent, template)
  if template == "ActionBarButtonTemplate" or template == "StanceButtonTemplate" then
    actionButtonParts(f)
    if id then f.id = id end
    f.GetName = function() return name end
    if template == "ActionBarButtonTemplate" then
      f.updates, f.usables = 0, 0
      f.Update = function(self) self.updates = self.updates + 1 end
      f.UpdateUsable = function(self) self.usables = self.usables + 1; self.icon:SetVertexColor(1, 1, 1) end
    end
  end
  return f
end
MainActionBar = new("Frame", "MainActionBar")
MainActionBar:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
MainActionBar.actionButtons = { new("CheckButton", "ActionButton1") }
MainActionBar.actionButtons[1]:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
for _, n in ipairs({ "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarLeft", "MultiBarRight", "MultiBar5", "MultiBar6" }) do
  local b = new("Frame", n)
  b:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
  b.actionButtons = { new("CheckButton", n .. "Button1") }
end
StanceBar = new("Frame", "StanceBar")
StanceBar:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
StanceBar.actionButtons = { new("CheckButton", "StanceButton1") }
PetActionBar = new("Frame", "PetActionBar")
PetActionBar:RegisterEvent("PET_BAR_UPDATE")
PetActionBar.scripts.OnEvent = function() end
MainActionBar.scripts.OnEvent = function() end
PetActionBar.actionButtons = {}
for i = 1, 10 do
  local b = new("CheckButton", "PetActionButton" .. i, PetActionBar)
  actionButtonParts(b)
  b.id = i
  PetActionBar.actionButtons[i] = b
end
OverrideActionBar = new("Frame", "OverrideActionBar")
OverrideActionBarButton1 = new("CheckButton", "OverrideActionBarButton1")
OverrideActionBarButton1.IsVisible = function() return false end
MultiCastActionBarFrame = new("Frame", "MultiCastActionBarFrame")
MultiCastActionBarFrame.w, MultiCastActionBarFrame.h = 230, 40
MultiCastActionBarFrame.numActiveSlots = 0
local function namedButton(name, parent)
  local b = new("CheckButton", name, parent)
  b.GetName = function() return name end
  return b
end
local function totemButton(name, parent)
  local b = namedButton(name, parent)
  actionButtonParts(b)
  b.overlayTex = b:CreateTexture()
  return b
end
MultiCastSummonSpellButton = totemButton("MultiCastSummonSpellButton", MultiCastActionBarFrame)
MultiCastRecallSpellButton = totemButton("MultiCastRecallSpellButton", MultiCastActionBarFrame)
new("Texture", "MultiCastRecallSpellButtonHighlight")
for i = 1, 4 do
  local slot = namedButton("MultiCastSlotButton" .. i, MultiCastActionBarFrame)
  slot.background, slot.overlayTex = slot:CreateTexture(), slot:CreateTexture()
end
for i = 1, 12 do totemButton("MultiCastActionButton" .. i, MultiCastActionBarFrame) end
MultiCastFlyoutFrame = new("Frame", "MultiCastFlyoutFrame", MultiCastActionBarFrame)
MultiCastFlyoutFrame.top, MultiCastFlyoutFrame.middle = MultiCastFlyoutFrame:CreateTexture(), MultiCastFlyoutFrame:CreateTexture()
MultiCastFlyoutFrame.buttons = {}
function MultiCastActionButton_Update() end
function MultiCastFlyoutFrame_ToggleFlyout() end
-- What the game does when the totem slots change: it points two of the buttons somewhere new.
function MultiCastActionBarFrame_Update(self)
  MultiCastSlotButton1:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 41, 3)
  MultiCastRecallSpellButton:SetPoint("LEFT", MultiCastSlotButton4, "RIGHT", 8, 0)
end
-- The game's quick keybind mode. Closing it opens the game's settings.
QuickKeybindFrame = new("Button", "QuickKeybindFrame", UIParent)
QuickKeybindFrame.shown = false
SettingsPanel = new("Frame", "SettingsPanel", UIParent)
SettingsPanel.shown = false
QuickKeybindFrame.scripts.OnHide = function() SettingsPanel:Show() end
function QuickKeybindFrame:CancelBinding() self.cancelled = true; self:Hide() end
function HideUIPanel(f) f:Hide() end
MicroMenuContainer = new("Frame", "MicroMenuContainer", UIParent)
MicroMenu = new("Frame", "MicroMenu", MicroMenuContainer)
function MicroMenu:GetParent() return self.parent end
function MicroMenu:SetParent(p) self.parent = p end
local microRules = {}
local function microButton(name)
  local b = namedButton(name, MicroMenu)
  b.w, b.h = 32, 40
  b.Background, b.PushedBackground, b.FlashBorder = b:CreateTexture(), b:CreateTexture(), b:CreateTexture()
  b.normalArt, b.disabledArt = b:CreateTexture(), b:CreateTexture()
  b.GetNormalTexture = function(self) return self.normalArt end
  b.GetDisabledTexture = function(self) return self.disabledArt end
  b.FlashContent = b:CreateTexture()
  -- The game anchors the art again whenever a button changes state.
  b.SetNormal = function(self) self.normalArt:ClearAllPoints(); self.normalArt:SetPoint("TOPLEFT"); self.state = "normal" end
  b.SetPushed = function(self) self.normalArt:ClearAllPoints(); self.normalArt:SetPoint("TOPLEFT"); self.state = "pushed" end
  return b
end
for _, n in ipairs({ "CharacterMicroButton", "QuestLogMicroButton", "EJMicroButton", "HelpMicroButton", "StoreMicroButton", "MainMenuMicroButton" }) do
  microButton(n)
end
CharacterMicroButton.Shadow, CharacterMicroButton.PushedShadow = CharacterMicroButton:CreateTexture(), CharacterMicroButton:CreateTexture()
CharacterMicroButton.Portrait, CharacterMicroButton.PortraitMask = CharacterMicroButton:CreateTexture(), CharacterMicroButton:CreateTexture()
MainMenuMicroButton.MainMenuBarPerformanceBar = MainMenuMicroButton:CreateTexture()
HelpOpenWebTicketButton = new("Frame", "HelpOpenWebTicketButton")
MicroMenu.GenerateButtonInfos = function()
  return {
    { button = CharacterMicroButton }, { button = QuestLogMicroButton },
    { button = EJMicroButton, callback = function() return microRules.ej end },
    { button = HelpMicroButton }, { button = StoreMicroButton }, { button = MainMenuMicroButton },
  }
end
MicroMenu.UpdateHelpTicketButtonAnchor = function() end
BagsBar = new("Frame", "BagsBar", UIParent)
local function bagButton(name)
  local b = namedButton(name, BagsBar)
  b.w, b.h = 45, 45
  b.icon = b:CreateTexture()
  b.SquareMask, b.IconBorder, b.IconOverlay = b:CreateTexture(), b:CreateTexture(), b:CreateTexture()
  b.SlotHighlightTexture = b:CreateTexture()
  b.Count = b:CreateFontString()
  b.art = b:CreateTexture()
  b.GetNormalTexture = function(self) return self.art end
  -- What the game does on any bag change: back to its own art.
  b.UpdateTextures = function(self)
    self:GetHighlightTexture().atlas = "game"
    self:GetHighlightTexture().ctex = nil
    self:GetPushedTexture().ctex = nil
  end
  return b
end
for _, n in ipairs({ "KeyRingButton", "CharacterReagentBag0Slot", "CharacterBag3Slot", "CharacterBag2Slot", "CharacterBag1Slot", "CharacterBag0Slot", "MainMenuBarBackpackButton" }) do
  bagButton(n)
end
MainMenuBarBackpackButton.FreeSlots = MainMenuBarBackpackButton:CreateFontString()
MainMenuBarBackpackButton.SetCountShown = function(self, v) self.countShown = v end
NUM_BAG_SLOTS = 4
C_ActionBar = { ShouldShowKeyring = function() return true end }
-- What the game does when you pick up an item: it lays the bag buttons out again.
BagsBar.Layout = function(self)
  MainMenuBarBackpackButton:ClearAllPoints()
  MainMenuBarBackpackButton:SetPoint("RIGHT", self, "RIGHT")
end
local unregistered = {}
EventRegistry = { UnregisterCallback = function(_, ev, owner) unregistered[ev] = owner end }
ActionButtonSpellAlertManager = { alerts = {}, ShowAlert = function(self, b) self.alerts[b] = true end, HideAlert = function(self, b) self.alerts[b] = nil end }
ActionButton_UpdateCooldownNumberHidden = function(b) b.cooldown:SetHideCountdownNumbers(true) end
barKeys.ACTIONBUTTON1 = { "1", "F1" }
barKeys.ACTIONBUTTON2 = { "SHIFT-MOUSEWHEELUP" }
barKeys.MULTIACTIONBAR1BUTTON2 = { "SHIFT-Q" }
barActions[1] = true
barActions[49] = true -- something on bar 3, which the game has hidden

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
local lbl = KUILoot.title
local lblText = lbl.text
lbl.redraws = 0
local oldSet = lbl.SetText
lbl.SetText = function(self, t) self.redraws = self.redraws + 1; oldSet(self, t) end
SlashCmdList.KUI("font rajdhani")
check(lbl.font[1]:find("Rajdhani") and lbl.redraws >= 1 and lbl.text == lblText, "text redrawn in the new font")
SlashCmdList.KUI("font barlow")
check(lbl.font[1]:find("Barlow") and lbl.text == lblText, "and back again")

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
check(#E.tabs == 7 and E.tab == "player", "a tab for each frame")
check(KUIEditMode.w == 340 * 2 + 8 * 3, "the window has room for them")
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

;(function()
print("== Settings windows keep their font")
local E, St = ns.EditMode, ns.Style
local function inside(fs, root)
  local p = fs.parent
  while p do
    if p == root then return true end
    p = p.parent
  end
end
local function strays(root)
  local bad = {}
  for _, fs in ipairs(allFontStrings) do
    if inside(fs, root) and not (fs.font and fs.font[1]:find("Barlow%-SemiBold")) then
      bad[#bad + 1] = tostring(fs.text)
    end
  end
  return #bad, table.concat(bad, ", ")
end
-- Open everything once so it all exists.
SlashCmdList.KUI("edit")
for _, b in ipairs(E.tabs) do E:Select(b.tab) end
KUIMinimapButton.scripts.OnClick(KUIMinimapButton)
ns.Bags:Slash("")
-- Change the font the way the panel does it.
E:Select("player")
local fontRow
for _, r in ipairs(E.rows) do if r.def.key == "font" then fontRow = r end end
fontRow.io.set(fontRow.def, "rajdhani")
fontRow.io.changed(fontRow.def)
check(KUIDB.font == "rajdhani", "font changed")
check(KUIPlayerFrame.name.font[1]:find("Rajdhani"), "the frames follow it")
check(KUIPlayerFrame.hpText.font[1]:find("Rajdhani"), "and their numbers")
check(KUILoot.title.font[1]:find("Rajdhani"), "and other kUI windows")
local n, what = strays(KUIEditMode)
check(n == 0, "the edit mode window doesn't: " .. what)
n, what = strays(KUIMenu)
check(n == 0, "the minimap menu doesn't: " .. what)
n, what = strays(KUIBagSettings)
check(n == 0, "the bag settings don't: " .. what)
check(KUIPlayerFrame.mover.label.font[1]:find("Barlow%-SemiBold"), "the drag overlays don't")
check(KUIMinimapButton.glyph.font[1]:find("Barlow%-SemiBold"), "the icon doesn't")
check(fontRow.value.text == "Rajdhani", "the setting still shows what's chosen")
-- Built while another font is chosen, and repainted after.
E.pages.cast = nil
E:Select("cast")
n, what = strays(KUIEditMode)
check(n == 0, "a page built after the change is the same: " .. what)
KUIMinimapButton.scripts.OnClick(KUIMinimapButton)
KUIMinimapButton.scripts.OnClick(KUIMinimapButton)
n, what = strays(KUIMenu)
check(n == 0, "and the menu after repainting: " .. what)
-- Size can still change on a fixed one.
St.SetFont(fontRow.label, 14)
check(fontRow.label.font[2] == 14 and fontRow.label.font[1]:find("Barlow%-SemiBold"), "size changes, font doesn't")
St.SetFont(fontRow.label, 12)
KUIMinimapButton.scripts.OnClick(KUIMinimapButton)
ns.Bags:Slash("")
SlashCmdList.KUI("font barlow")
SlashCmdList.KUI("edit")
end)()

;(function()
print("== Cast bar text")
local Bar = KUICastbar
local function cast(c)
  c.icon, c.st, c.en, c.guid = "i", GetTime() * 1000, (GetTime() + 2) * 1000, "x" .. tostring(c.spellID)
  castInfo.player = c
  fire("UNIT_SPELLCAST_START", "player", c.guid)
  local text = Bar.label.text
  castInfo.player = nil
  fire("UNIT_SPELLCAST_STOP", "player", c.guid)
  Bar.scripts.OnUpdate(Bar, 2)
  return text
end
check(cast({ name = "Opening", display = "Opening" }) == "Opening", "the usual case")
check(cast({ name = "Opening - No Text", display = "Opening - No Text" }) == "Opening", "a water barrel: the designers' note comes off")
check(cast({ name = "Opening - No Text", display = "" }) == "Opening", "from the plain name too")
check(cast({ name = "Fishing - No Text Here", display = "" }) == "Fishing - No Text Here", "only as the end of a name")
check(cast({ name = "Hearthstone", display = "Hearthstone" }) == "Hearthstone", "other spells are left alone")
check(cast({ name = "", display = "Opening" }) == "Opening", "opening a chest: empty name, display name used")
check(cast({ name = "Internal", display = "Shown" }) == "Shown", "the display name wins, as on the game's own bar")
check(cast({ name = "Lightning Bolt", display = "" }) == "Lightning Bolt", "empty display name falls back to the name")
check(cast({ name = nil, display = "Opening" }) == "Opening", "no name at all still shows the bar")
C_Spell = { GetSpellName = function(id) return id == 3365 and "Opening" or nil end }
check(cast({ name = "", display = "", spellID = 3365 }) == "Opening", "both empty: the spell's own name")
check(cast({ name = "", display = "", spellID = 1 }) == "Casting", "nothing known: never a blank bar")
check(cast({ name = "", display = "" }) == "Casting", "no spell ID either")
C_Spell = nil
-- channels
chanInfo.player = { name = "", display = "Drain", icon = "i", st = GetTime() * 1000, en = (GetTime() + 2) * 1000 }
fire("UNIT_SPELLCAST_CHANNEL_START", "player")
check(Bar.mode == "channel" and Bar.label.text == "Drain", "channels use the display name too")
chanInfo.player = { name = "", display = "", icon = "i", st = GetTime() * 1000, en = (GetTime() + 2) * 1000 }
fire("UNIT_SPELLCAST_CHANNEL_UPDATE", "player")
check(Bar.label.text == "Channelling", "and never go blank")
chanInfo.player = nil
fire("UNIT_SPELLCAST_CHANNEL_STOP", "player")
Bar.scripts.OnUpdate(Bar, 2)
-- secret text goes straight to the widget
local SM = {}
for _, m in ipairs({ "__len", "__concat", "__lt", "__le", "__tostring", "__index" }) do SM[m] = function() error("a secret value was used in Lua", 2) end end
local secret = setmetatable({}, SM)
issecretvalue = function(v) return getmetatable(v) == SM end
castInfo.player = { name = secret, display = secret, icon = "i", st = GetTime() * 1000, en = (GetTime() + 2) * 1000, guid = "s1" }
local ok, err = pcall(function() fire("UNIT_SPELLCAST_START", "player", "s1") end)
check(ok and rawequal(Bar.label.text, secret), "a secret name is passed straight through: " .. tostring(ok and "" or err))
issecretvalue = nil
castInfo.player = nil
fire("UNIT_SPELLCAST_STOP", "player", "s1")
Bar.scripts.OnUpdate(Bar, 2)
end)()

;(function()
print("== Action bars")
local AB = ns.ActionBars
local E = ns.EditMode
inCombat = false
RegisterStateDriver, UnregisterStateDriver = barStateDriver, barStateDriverOff -- the rare alert's tests swapped in their own
check(AB.enabled and AB.started, "started at login")
local Bar1, Bar2, Bar3, Bar4 = KUIBar1, KUIBar2, KUIBar3, KUIBar4
local hidden = ns.Style.HiddenParent()

-- Which bars start on
check(KUIDB.barCfg.bar1.on, "bar 1 is on")
check(KUIDB.barCfg.bar2.on, "a bar the game was showing stays on")
check(KUIDB.barCfg.bar3.on, "a bar with something on it stays on")
check(not KUIDB.barCfg.bar4 or not KUIDB.barCfg.bar4.on, "an empty, hidden bar starts off")
check(Bar1 and Bar2 and Bar3 and not KUIBar4, "frames only for the bars that are on")
local names = {}
for _, it in ipairs(AB:List()) do names[#names + 1] = it.key end
check(table.concat(names, " ") == "bar1 bar2 bar3 bar4 bar5 bar6 bar7 stance pet totem", "only bars this client has: " .. table.concat(names, " "))
fire("PLAYER_ENTERING_WORLD")
check(KUIDB.barSeeded, "the first run's choice is remembered")
barActions[25] = true
AB:Seed()
check(not KUIDB.barCfg.bar4 or not KUIDB.barCfg.bar4.on, "and doesn't override your choices later")
barActions[25] = nil

-- The game's bars
check(MultiBarLeft.parent == hidden and MultiBarLeft.allOff, "the game's side bar is retired")
check(#MultiBarLeft.actionButtons == 0, "and forgets its buttons")
check(MainActionBar.parent == hidden and not MainActionBar.allOff and MainActionBar.events.ACTIONBAR_PAGE_CHANGED, "the main bar is hidden but keeps listening, for vehicles")
check(ActionButton1.allOff and ActionButton1.attrs.statehidden and not ActionButton1.shown, "its buttons are out of the way")
check(StanceBar.parent == hidden and #StanceBar.actionButtons == 1, "the stance bar is hidden, its buttons still listed")
check(PetActionBar.parent == hidden and PetActionBar.events.PET_BAR_UPDATE, "the pet bar is hidden but keeps updating")

-- Slots and templates
local b = KUIBar1Button1
check(b and b.tmpl == "ActionBarButtonTemplate" and b.parent == Bar1 and b.kind == "CheckButton", "buttons use the game's template")
check(b.id == 0 and b.attrs.action == 1, "the slot comes from the action attribute, not the game's paging")
check(KUIBar2Button1.attrs.action == 61 and KUIBar2Button12.attrs.action == 72, "bar 2: the game's bottom left slots")
check(KUIBar3Button1.attrs.action == 49, "bar 3: bottom right")
check(#Bar1.buttons == 12, "twelve buttons")

-- Keys
check(b.kKey.text == "1", "key text")
check(boundKeys["1"] and boundKeys["1"].owner == b.kBind and boundKeys["1"].name == "KUIBar1Button1Key" and boundKeys["1"].button == "HOTKEY", "your key presses this button")
check(boundKeys.F1 and boundKeys.F1.owner == b.kBind, "every key bound to it, not just the first")
check(KUIBar1Button2.kKey.text == "SWU", "long key names shortened: " .. tostring(KUIBar1Button2.kKey.text))
check(KUIBar2Button2.kKey.text == "SQ" and boundKeys["SHIFT-Q"].owner == KUIBar2Button2.kBind, "a multibar key")
local S0 = AB.ShortKey
check(S0("BUTTON4") == "M4" and S0("CTRL-NUMPAD3") == "CN3" and S0("BACKSPACE") == "Bs" and S0("ALT-SPACE") == "ASp" and S0(nil) == "", "short key names")
check(b.kBind.tmpl == "SecureActionButtonTemplate" and b.kBind.attrs["useparent-action"] and b.kBind.attrs.type == "action", "the key button borrows its parent's action")
check(b.kBind.wrapped and b.kBind.wrapped.OnClick, "key presses are turned into clicks")
local calls = bindCalls
fire("UPDATE_BINDINGS")
check(bindCalls == calls, "unchanged keys aren't rebound (setting them fires this event)")
barKeys.ACTIONBUTTON3 = { "E" }
inCombat = true
fire("UPDATE_BINDINGS")
check(KUIBar1Button3.kKey.text == "E", "the text updates in combat")
check(not boundKeys.E and AB.keysPending, "binding waits for combat to end")
inCombat = false
fire("PLAYER_REGEN_ENABLED")
check(boundKeys.E and boundKeys.E.owner == KUIBar1Button3.kBind and not AB.keysPending, "and happens after")

-- The look
check(b.NormalTexture.parent == hidden and b.buttonNormal.parent == hidden and b.SlotArt.parent == hidden and b.Border.parent == hidden and b.HotKey.parent == hidden, "the game's art is gone for good")
check(b.SpellCastAnimFrame.parent == hidden and b.InterruptDisplay.parent == hidden, "and its cast animations")
check(b.icon.maskRemoved == b.IconMask and b.icon.texCoord[1] == 0.07, "square icons, edges cropped")
check(b.kBack.ctex and b.kEdges[1].shown, "a flat dark slot and a thin border")
check(b.Name.parent == b.kText and b.Count.parent == b.kText, "text sits above the cooldown swipe")
check(b.kText.flevel > b.flevel, "the text layer is higher")
check(b.cooldown.hideNumbers == false and b.cooldown.countdownFont == "KUICooldownFontbar1", "cooldown numbers, in kUI's font")
check(KUICooldownFontbar1.font[2] == 14, "at the chosen size")
ActionButton_UpdateCooldownNumberHidden(b)
check(b.cooldown.hideNumbers == false, "kUI's setting wins over the game's on our bars")

-- Layout
check(Bar1.w == 12 * 36 + 11 * 3 and Bar1.h == 36, "the bar fits its buttons: " .. tostring(Bar1.w))
check(b.w == 36 and b.h == 36, "button size")
local function at(btn) local p = btn.points[#btn.points]; return p[4], p[5] end
local x, y = at(KUIBar1Button4)
check(x == 3 * 39 and y == 0, "buttons run left to right: " .. tostring(x))
local c = AB:Cfg("bar1")
c.perRow, c.count, c.size, c.gapX, c.gapY = 4, 10, 20, 2, 5
AB:Changed("bar1")
check(Bar1.w == 4 * 20 + 3 * 2 and Bar1.h == 3 * 20 + 2 * 5, "rows: " .. tostring(Bar1.w) .. "x" .. tostring(Bar1.h))
x, y = at(KUIBar1Button5)
check(x == 0 and y == 25, "a new row goes above")
x, y = at(KUIBar1Button4)
check(x == 66 and y == 0, "the row's end")
check(KUIBar1Button10.shown and not KUIBar1Button11.shown and KUIBar1Button11.attrs.statehidden, "spare buttons are hidden")
c.growX = "left"
AB:Changed("bar1")
x, y = at(KUIBar1Button1)
check(x == 66 and y == 0, "rows can fill to the left")
c.growY = "down"
AB:Changed("bar1")
x, y = at(KUIBar1Button1)
check(y == 50, "and be added downwards: " .. tostring(y))
c.scale = 1.5
AB:Changed("bar1")
check(Bar1.scale == 1.5, "scale")
c.left, c.top = 100, 200
AB:Changed("bar1")
local p = Bar1.points[#Bar1.points]
check(p[1] == "TOPLEFT" and p[4] == 100 and p[5] == 200, "a saved spot")
AB:ResetBar("bar1")
check(c.perRow == 12 and c.left == nil and c.on and Bar1.w == 465, "reset: default look and spot, still on")

-- Paging on bar 1
check(stateDrivers[Bar1].page:find("[bar:2]2", 1, true) and stateDrivers[Bar1].page:find("[bonusbar:1]7", 1, true), "bar 1 pages")
check(not stateDrivers[Bar2].page, "other bars don't")
local special = { tonumber = tonumber }
local handle
function handle(f)
  return setmetatable({}, { __index = function(_, k)
    if k == "GetAttribute" then return function(_, n) return f.attrs and f.attrs[n] end end
    if k == "SetAttribute" then return function(_, n, v) f.attrs = f.attrs or {}; f.attrs[n] = v end end
    if k == "ChildUpdate" then
      return function(_, id, msg)
        for _, kid in ipairs(f.buttons) do
          local code = kid.attrs["_childupdate-" .. id]
          if code then
            local fn = assert(load("local self, scriptid, message = ...; " .. code, "childupdate", "t", {}))
            fn(handle(kid), id, msg)
          end
        end
      end
    end
    if k == "CallMethod" then return function(_, m, ...) return f[m](f, ...) end end
  end })
end
local function page(state)
  local env = setmetatable({ control = handle(Bar1) }, { __index = special })
  local fn = assert(load("local self, stateid, newstate = ...; " .. Bar1.attrs["_onstate-page"], "onstate", "t", env))
  fn(handle(Bar1), "page", state)
end
page("2")
check(KUIBar1Button1.attrs.action == 13 and KUIBar1Button12.attrs.action == 24, "Shift-2: page two")
barActions[13] = nil
page("7")
check(KUIBar1Button1.attrs.action == 73, "a stance or form page")
page("1")
check(KUIBar1Button1.attrs.action == 1, "and back")
special.HasVehicleActionBar = function() return true end
special.GetVehicleBarIndex = function() return 16 end
page("special")
check(KUIBar1Button1.attrs.action == 181, "a vehicle's page comes from the game")
special.HasVehicleActionBar, special.GetVehicleBarIndex = nil, nil
special.HasOverrideActionBar = function() return true end
special.GetOverrideBarIndex = function() return 14 end
page("special")
check(KUIBar1Button1.attrs.action == 157, "an override page")
special.HasOverrideActionBar, special.GetOverrideBarIndex = nil, nil
special.HasTempShapeshiftActionBar = function() return true end
special.GetTempShapeshiftBarIndex = function() return 13 end
page("special")
check(KUIBar1Button1.attrs.action == 145, "a temporary form's page")
special.HasTempShapeshiftActionBar, special.GetTempShapeshiftBarIndex = nil, nil
special.HasBonusActionBar = function() return true end
special.GetBonusBarIndex = function() return 11 end
page("special")
check(KUIBar1Button1.attrs.action == 121, "possession")
special.HasBonusActionBar, special.GetBonusBarIndex = nil, nil
page("special")
check(KUIBar1Button1.attrs.action == 1, "nothing special after all: page one")
KUIBar1Button1.kOut = true
page("1")
check(not KUIBar1Button1.kOut, "turning a page forgets the old slot's range")

-- The other secure snippets at least run
local keyCode = KUIBar1Button1.kBind.wrapped.OnClick
local function keyClick(button, info)
  local env = { GetActionInfo = function() return info end }
  local me = { GetEffectiveAttribute = function() return 1 end }
  return assert(load("local self, button, down = ...; " .. keyCode, "key", "t", env))(me, button, true)
end
check(keyClick("HOTKEY", "spell") == "LeftButton", "a key press clicks")
check(keyClick("HOTKEY", "flyout") == false, "a flyout key press doesn't cast")
check(keyClick("LeftButton", "spell") == nil, "real clicks pass straight through")
local w = AB.wrap
check(OverrideActionBarButton1.wrapped.OnShow and OverrideActionBarButton1.wrapped.OnHide, "kUI watches the vehicle bar")
check(attrDrivers[w].petbattleui == "[petbattle]1;0", "and pet battles")
local keysSet = {}
local function override(name, over, pb)
  keysSet = {}
  w.attrs.overrideui, w.attrs.petbattleui = over, pb
  local me = {
    GetAttribute = function(_, n) return w.attrs[n] end,
    ClearBindings = function() keysSet.cleared = true end,
    RunAttribute = function(_, n, ...)
      local function setb(_, _, key, cmd) keysSet[key] = cmd end
      return assert(load("local self = ...; local function run(...) " .. w.attrs[n] .. " end; return run(select(2, ...))", n, "t", { select = select }))(setmetatable({ SetBinding = setb }, {}), ...)
    end,
  }
  local env = { GetBindingKey = function(cmd) return unpack(barKeys[cmd] or {}) end }
  assert(load("local self, name, value = ...; " .. w.attrs._onattributechanged, "ov", "t", env))(me, name, over)
end
override("overrideui", 1, 0)
check(keysSet.cleared and keysSet["1"] == "ACTIONBUTTON1" and keysSet.F1 == "ACTIONBUTTON1", "the vehicle bar takes keys 1-6 back")
override("overrideui", 0, 0)
check(keysSet.cleared and not keysSet["1"], "and lets go after")

-- Visibility
local cfg2 = AB:Cfg("bar2")
check(stateDrivers[Bar2].visibility == "[petbattle]hide;[overridebar][vehicleui]hide;show", "bars step aside for the vehicle bar: " .. tostring(stateDrivers[Bar2].visibility))
cfg2.mode = "combat"
AB:Changed("bar2")
check(stateDrivers[Bar2].visibility:find("%[combat%]show;hide$"), "only in combat")
cfg2.mode = "peace"
AB:Changed("bar2")
check(stateDrivers[Bar2].visibility:find("%[nocombat%]show;hide$"), "only out of combat")
cfg2.mode = "always"
AB:Changed("bar2")
local realOverride = OverrideActionBar
OverrideActionBar = nil
check(AB:Driver(Bar2) == "[petbattle]hide;show", "no vehicle bar on this client: nothing to step aside for")
OverrideActionBar = realOverride

-- Empty slots
local empty = KUIBar1Button2
check(empty.alpha == 1, "empty slots show by default")
local c1 = AB:Cfg("bar1")
c1.empty = false
AB:Changed("bar1")
check(empty.alpha == 0 and KUIBar1Button1.alpha == 1, "or only filled ones")
fire("ACTIONBAR_SHOWGRID")
check(empty.alpha == 1, "picking up a spell shows where it can go")
fire("ACTIONBAR_HIDEGRID")
check(empty.alpha == 0, "putting it down hides them")
inCombat = true
fire("ACTIONBAR_SHOWGRID")
check(empty.alpha == 1, "in combat too")
fire("ACTIONBAR_HIDEGRID")
inCombat = false
barActions[2] = true
fire("ACTIONBAR_SLOT_CHANGED", 2)
check(empty.alpha == 1, "filling a slot shows it")
barActions[2] = nil
empty:Update()
check(empty.alpha == 0, "emptying it hides it, when the game updates the button")
barActions[73], barActions[74] = true, true
page("7")
check(KUIBar1Button1.alpha == 1 and KUIBar1Button2.alpha == 1, "a new page repaints")
page("1")
check(KUIBar1Button2.alpha == 0, "and again on the way back")
c1.empty = true
AB:Changed("bar1")
equipped[2] = true
fire("PLAYER_EQUIPMENT_CHANGED")
check(empty.kEdges[1].ctex[2] == 0.85, "equipped items get a green border")
equipped[2] = nil
fire("PLAYER_EQUIPMENT_CHANGED")
check(empty.kEdges[1].ctex[2] == ns.Style.SOFT[2], "and lose it")

-- Text and border options
c1.keys, c1.macro, c1.stack, c1.border = false, true, false, false
c1.keySize, c1.macroSize, c1.stackSize, c1.cdText, c1.cdSize = 9, 13, 15, false, 22
AB:Changed("bar1")
check(b.kKey.alpha == 0 and b.Name.alpha == 1 and b.Count.alpha == 0, "each text can be off")
check(b.Name.font[2] == 13 and b.kKey.font[2] == 9 and b.Count.font[2] == 15, "and has its own size")
check(not b.kEdges[1].shown, "the border can be off")
check(b.icon.points[1][2] == 0, "and the icon fills the slot")
check(b.cooldown.hideNumbers == true and KUICooldownFontbar1.font[2] == 22, "cooldown number options")
AB:ResetBar("bar1")
check(b.kEdges[1].shown and b.icon.points[1][2] == 1, "border back")

-- Out of range
fire("ACTION_RANGE_CHECK_UPDATE", 1, false, true)
check(b.kOut and b.icon.vc[1] == 0.85, "out of range: red icon")
b:UpdateUsable()
check(b.icon.vc[1] == 0.85, "stays red when the game repaints it")
local usables = b.usables
fire("ACTION_RANGE_CHECK_UPDATE", 1, true, true)
check(not b.kOut and b.usables == usables + 1 and b.icon.vc[1] == 1, "back in range: the game's colour again")
fire("ACTION_RANGE_CHECK_UPDATE", 1, false, false)
check(not b.kOut, "spells without a range never go red")
KUIDB.barRange = false
fire("ACTION_RANGE_CHECK_UPDATE", 1, false, true)
check(not b.kOut, "the tint can be turned off")
KUIDB.barRange = true
local SM = {}
SM.__lt = function() error("a secret value was used in Lua", 2) end
SM.__eq = SM.__lt
local secret = setmetatable({}, SM)
issecretvalue = function(v) return getmetatable(v) == SM end
local ok, err = pcall(function() fire("ACTION_RANGE_CHECK_UPDATE", 1, secret, secret) end)
check(ok and not b.kOut, "a secret range is ignored: " .. tostring(err))
fire("ACTION_RANGE_CHECK_UPDATE", 1, false, secret)
check(not b.kOut, "whichever value is the secret one")
issecretvalue = nil

-- Procs
local mgr = ActionButtonSpellAlertManager
mgr:ShowAlert(b)
check(mgr.alerts[b], "the game's proc glow by default")
KUIDB.barProcs = false
mgr:ShowAlert(b)
check(not mgr.alerts[b], "can be turned off")
KUIDB.barProcs = true
local notOurs = {}
mgr:ShowAlert(notOurs)
KUIDB.barProcs = false
mgr:ShowAlert(notOurs)
check(mgr.alerts[notOurs], "leaves other buttons alone")
KUIDB.barProcs = true

-- Stance
check(not (KUIStanceButton1 and KUIStanceButton1.shown), "no forms, no stance buttons showing")
forms = { { icon = "bear", active = true, castable = true }, { icon = "cat", active = false, castable = false, cdStart = 5, cdDur = 10 } }
fire("UPDATE_SHAPESHIFT_FORMS")
local s1, s2 = KUIStanceButton1, KUIStanceButton2
check(s1 and s2 and s1.tmpl == "StanceButtonTemplate" and s2.id == 2, "a button per form")
check(s1.icon.tex == "bear" and s1.checked == true and s2.checked == false, "the active form is checked")
check(s1.icon.vc[1] == 1 and s2.icon.vc[1] == 0.4, "forms you can't use are dimmed")
check(s2.cooldown.cooldown and s2.cooldown.cooldown[2] == 10 and s1.cooldown.cleared, "form cooldowns")
check(KUIStancebar.w == 2 * 30 + 3, "the bar fits: " .. tostring(KUIStancebar.w))
barKeys.SHAPESHIFTBUTTON1 = { "F5" }
fire("UPDATE_BINDINGS")
check(s1.kKey.text == "F5", "stance keys show")
forms[3] = { icon = "tree", castable = true }
inCombat = true
fire("UPDATE_SHAPESHIFT_FORMS")
check(not KUIStanceButton3 and AB.applyPending, "a new form waits for combat to end")
inCombat = false
fire("PLAYER_REGEN_ENABLED")
check(KUIStanceButton3 and KUIStancebar.w == 3 * 30 + 6, "then gets a button")
forms[1].active, forms[2].active = false, true
fire("UPDATE_SHAPESHIFT_FORM")
check(s1.checked == false and s2.checked == true, "changing form moves the check")
local secretCd = setmetatable({}, SM)
issecretvalue = function(v) return getmetatable(v) == SM end
forms[2].cdStart, forms[2].cdDur = secretCd, secretCd
ok, err = pcall(function() fire("UPDATE_SHAPESHIFT_COOLDOWN") end)
check(ok, "a secret cooldown doesn't break the bar: " .. tostring(err))
issecretvalue = nil
forms[2].cdStart, forms[2].cdDur = 0, 0

-- Pet
local PB = KUIPetbar
local pb1 = PetActionButton1
check(PB and pb1.parent == PB and PB.buttons[10] == PetActionButton10, "the game's pet buttons move to our bar")
check(pb1.NormalTexture.parent == hidden and pb1.kKey, "dressed like the rest")
check(stateDrivers[PB].visibility:find("%[@pet,exists,nopossessbar%]show;hide$"), "shows with a pet")
AB:Cfg("pet").mode = "combat"
AB:Changed("pet")
check(stateDrivers[PB].visibility:find("%[@pet,exists,nopossessbar,combat%]show;hide$"), "and can also wait for combat")
AB:Cfg("pet").mode = "always"
AB:Cfg("pet").empty = false
AB:Changed("pet")
check(pb1.alpha == 0, "empty pet slots can hide")
petActions[1] = "Attack"
fire("PET_BAR_UPDATE")
check(pb1.alpha == 1, "a filled one shows")
AB:Cfg("pet").empty = true
AB:Changed("pet")
barKeys.BONUSACTIONBUTTON1 = { "CTRL-1" }
fire("UPDATE_BINDINGS")
check(pb1.kKey.text == "C1", "pet keys show")

-- Totems, for Shamans
local TB, T = KUITotembar, MultiCastActionBarFrame
check(TB and T.parent == TB and T.ignoreFramePositionManager, "the totem bar moves into a kUI frame")
check(T.scripts.OnUpdate == nil and T.points[#T.points][2] == TB, "and the game stops moving it")
-- The game's art goes, and the buttons get ours.
local tb1, summon, recall = MultiCastActionButton1, MultiCastSummonSpellButton, MultiCastRecallSpellButton
check(tb1.overlayTex.parent == hidden and tb1.NormalTexture.parent == hidden, "the totem art is gone")
check(MultiCastSlotButton1.background.parent == hidden and MultiCastSlotButton1.overlayTex.parent == hidden, "from the slots too")
check(MultiCastRecallSpellButtonHighlight.parent == hidden, "and the spell button's frame")
check(tb1.kEdges and summon.kEdges and recall.kEdges and tb1.kBack, "every button gets a slot and a border")
check(tb1.icon.texCoord and tb1.icon.texCoord[1] == 0.07, "and a cropped icon")
check(AB.mine[tb1] and AB.mine[summon], "and follows the proc and cooldown settings")
-- Each totem's own colour.
MultiCastActionButton_Update(tb1, 2, 1, 2)
local earth = tb1.kEdges[1].ctex
MultiCastActionButton_Update(tb1, 1, 1, 1)
check(earth[1] ~= tb1.kEdges[1].ctex[1], "each element has its own border colour")
-- Only the totems you have get a place.
T.numActiveSlots = 4
summon:Show()
recall:Show()
AB:Changed("totem")
check(TB.w == 6 * 30 + 5 * 4 and TB.h == 30 and T.w == TB.w, "summon, four totems and recall in a row")
check(summon.points[1][4] == 0 and tb1.points[1][4] == 34 and MultiCastSlotButton1.points[1][4] == 34, "each in its place, slot under its button")
check(MultiCastActionButton5.points[1][4] == 34 and MultiCastActionButton9.points[1][4] == 34, "and every page lines up")
check(MultiCastActionButton4.points[1][4] == 34 * 4, "up to the fourth")
check(recall.points[1][1] == "LEFT" and recall.points[1][4] == 34 * 5 and recall.w == 30, "recall last")
check(tb1.w == 30 and MultiCastSlotButton1.w == 30 and summon.w == 30, "all one size")
T.numActiveSlots = 2
recall:Hide()
summon:Hide()
AB:Changed("totem")
check(TB.w == 2 * 30 + 4, "fewer totems, a shorter bar")
check(MultiCastActionButton1.points[1][4] == 0, "and no gap for a spell you don't know")
T.numActiveSlots = 0
AB:Changed("totem")
check(TB.w > 1 and TB.h > 1, "something to grab with no totems yet")
-- The game's own moves don't stick, and wait for combat to end when they have to.
T.numActiveSlots = 4
summon:Show()
recall:Show()
AB:Changed("totem")
MultiCastActionBarFrame_Update(T)
check(#recall.points == 1 and recall.points[1][2] == T and MultiCastSlotButton1.points[1][4] == 34, "the game moving its buttons is put right")
inCombat = true
AB.applyPending = nil
MultiCastSlotButton1:SetPoint("BOTTOMLEFT", T, "BOTTOMLEFT", 41, 3)
local inFight = #MultiCastSlotButton1.points
MultiCastActionBarFrame_Update(T)
check(AB.applyPending and #MultiCastSlotButton1.points == inFight + 1, "in combat that waits")
inCombat = false
fire("PLAYER_REGEN_ENABLED")
check(not AB.applyPending and #MultiCastSlotButton1.points == 1 and MultiCastSlotButton1.points[1][4] == 34, "and happens when combat ends")
-- The flyout that picks totems.
local flyButton = new("Button", nil, MultiCastFlyoutFrame)
flyButton.icon, flyButton.spellId = flyButton:CreateTexture(), 100
local clearButton = new("Button", nil, MultiCastFlyoutFrame)
clearButton.icon, clearButton.spellId = clearButton:CreateTexture(), 0
MultiCastFlyoutFrame.buttons = { clearButton, flyButton }
MultiCastFlyoutFrame_ToggleFlyout()
check(MultiCastFlyoutFrame.top.ctex and MultiCastFlyoutFrame.middle.ctex, "the flyout goes flat")
check(flyButton.kEdges and flyButton.icon.texCoord[1] == 0.07, "and its buttons get ours as the game makes them")
check(clearButton.kEdges and clearButton.icon.texCoord == nil, "leaving the empty-slot art whole")
-- Settings
AB:Cfg("totem").scale = 1.2
AB:Cfg("totem").size = 40
AB:Cfg("totem").keys = false
AB:Cfg("totem").border = false
AB:Cfg("totem").perRow = 3
AB:Changed("totem")
check(TB.scale == 1.2 and tb1.w == 40 and tb1.kKey.alpha == 0, "scale, size and text work")
check(not tb1.kEdges[1].shown, "border too")
check(TB.w == 3 * 40 + 2 * 4 and TB.h == 2 * 40 + 4, "and rows")
AB:Cfg("totem").mode = "hover"
AB:Cfg("totem").fadeTo = 0
AB:Changed("totem")
MultiCastFlyoutFrame:Hide()
AB.ev.scripts.OnUpdate(AB.ev, 10)
check(TB.alpha == 0, "it fades")
MultiCastFlyoutFrame:Show()
AB.ev.scripts.OnUpdate(AB.ev, 10)
check(TB.alpha == 1, "but stays while you pick a totem")
barKeys.MULTICASTACTIONBUTTON1 = { "CTRL-5" }
AB:BindAll()
check(tb1.kKey.text == "C5", "the game's own keys show")
check(tb1.kBind == nil, "and stay the game's")
AB:ResetBar("totem")
local realClass = UnitClass
UnitClass = function() return "Rogue", "ROGUE" end
AB.list = {}
local noTotem = true
for _, it in ipairs(AB:List()) do if it.key == "totem" then noTotem = false end end
check(noTotem, "no totem bar for other classes")
UnitClass = realClass
AB.list = {}

-- Default spots above the bottom bars
local function petY() return PB.points[#PB.points][5] end
AB:Place(PB)
check(petY() == 138, "pet bar above bar 3")
AB:Cfg("bar3").on = false
AB:Changed("bar3")
AB:Place(PB)
check(petY() == 99 and not Bar3.shown, "or above bar 2 when bar 3 is off")
check(not stateDrivers[Bar3].visibility, "a bar that's off has no state driver")
AB:Cfg("bar2").on = false
AB:Changed("bar2")
check(petY() == 60, "and it moves when you turn one off")
AB:Cfg("bar2").on, AB:Cfg("bar3").on = true, true
AB:Changed("bar2")
AB:Changed("bar3")

-- A bar that's off gives its keys back
AB:Cfg("bar2").on = false
AB:Changed("bar2")
check(not boundKeys["SHIFT-Q"], "a bar that's off releases its keys")
AB:Cfg("bar2").on = true
AB:Changed("bar2")
check(boundKeys["SHIFT-Q"], "and takes them again")

-- Hover
local ch = AB:Cfg("bar2")
ch.mode, ch.alpha, ch.fadeTo = "hover", 0.9, 0.1
AB:Changed("bar2")
check(Bar2.alpha == 0.1 and AB.ev.scripts.OnUpdate, "hover: starts faded, and a timer runs")
local hovering = Bar2
local realOver = MouseIsOver
MouseIsOver = function(f) return f == hovering end
for _ = 1, 20 do AB.ev.scripts.OnUpdate(AB.ev, 0.05) end
check(math.abs(Bar2.alpha - 0.9) < 1e-6, "fades in under the mouse: " .. tostring(Bar2.alpha))
hovering = nil
AB.ev.scripts.OnUpdate(AB.ev, 0.05)
check(Bar2.alpha < 0.9 and Bar2.alpha > 0.1, "out again gradually")
for _ = 1, 20 do AB.ev.scripts.OnUpdate(AB.ev, 0.05) end
check(math.abs(Bar2.alpha - 0.1) < 1e-6, "back to faded")
inCombat = true
hovering = Bar2
for _ = 1, 20 do AB.ev.scripts.OnUpdate(AB.ev, 0.05) end
check(math.abs(Bar2.alpha - 0.9) < 1e-6, "fading works in combat")
inCombat = false
hovering = nil
fire("ACTIONBAR_SHOWGRID")
for _ = 1, 20 do AB.ev.scripts.OnUpdate(AB.ev, 0.05) end
check(math.abs(Bar2.alpha - 0.9) < 1e-6, "a held spell wakes faded bars")
fire("ACTIONBAR_HIDEGRID")
MouseIsOver = realOver
ch.mode, ch.alpha, ch.fadeTo = "always", 1, 0
AB:Changed("bar2")
check(Bar2.alpha == 1 and not AB.ev.scripts.OnUpdate, "no faders left: the timer stops")

-- Combat
inCombat = true
local pts = #Bar1.points
AB:Cfg("bar1").size = 50
AB:Changed("bar1")
AB:Apply(Bar1)
AB:ApplyAll()
check(Bar1.w == 465 and #Bar1.points == pts, "nothing secure moves in combat")
check(AB.applyPending, "the change waits")
AB:ResetBar("bar1")
AB:CopyLook("bar1")
AB:Slash("reset")
check(AB:Cfg("bar1").size == 50, "reset and copy wait too")
AB:Cfg("bar1").size = 36
AB:Cfg("bar4").on = true
AB:ApplyAll()
check(not KUIBar4, "no new secure frames in combat")
inCombat = false
fire("PLAYER_REGEN_ENABLED")
check(KUIBar4 and not AB.applyPending, "all done when combat ends")
Bar4 = KUIBar4
check(Bar4.w == 36 and Bar4.h == 12 * 36 + 11 * 3, "side bars run in a column")
check(KUIBar4Button1.attrs.action == 25, "bar 4: the game's right bar slots")
check(KUIBar4Button1.attrs.flyoutDirection == "LEFT", "column bars open flyouts sideways")
AB:Cfg("bar4").on = false
AB:Changed("bar4")

-- Edit mode
SlashCmdList.KUI("bars")
check(KUIEditMode.shown and E.tab == "bars" and E.barKey == "bar1", "/kui bars opens its tab")
check(Bar1.mover.shown and Bar2.mover.shown and PB.mover.shown, "every bar gets an overlay")
check(not stateDrivers[Bar1].visibility and Bar1.shown and PB.shown, "bars stay shown while you edit them, even the pet bar")
check(not E.hint.shown and E.copy.shown, "the copy button replaces the hint")
local function row(key)
  for _, r in ipairs(E.rows) do if r.def.key == key then return r end end
end
row("size"):Set(44)
check(KUIDB.barCfg.bar1.size == 44 and b.w == 44 and Bar1.h == 44, "changing a slider changes the bar")
check(row("size").value.text == "44", "and the row")
row("perRow"):Set(6)
check(Bar1.h == 2 * 44 + 3, "rows")
row("keys"):Set(false)
check(b.kKey.alpha == 0, "toggles")
row("growY"):Set("down")
check(KUIDB.barCfg.bar1.growY == "down", "choices")
check(row("fadeTo"):Refresh() == nil and row("fadeTo").alpha == 0.45, "opacity when faded is dimmed unless hovering")
row("mode"):Set("hover")
check(row("fadeTo").alpha == 1, "and wakes")
check(Bar1.alpha == 1, "bars stay solid while editing")
row("mode"):Set("always")
-- picking another bar
row("bar"):Step(1)
check(E.barKey == "bar2", "the picker moves to the next bar")
check(row("size").value.text == "36" and row("bar").value.text == "Bar 2", "rows show that bar's settings")
check(KUIDB.barCfg.bar2.size == 36 and KUIDB.barCfg.bar1.size == 44, "without changing either")
row("size"):Set(30)
check(KUIBar2Button1.w == 30 and b.w == 44, "changes go to the picked bar")
check(Bar2.mover.fill.ctex[4] == 0.45 and Bar1.mover.fill.ctex[4] == 0.2, "its overlay stands out")
Bar1.mover.scripts.OnMouseUp(Bar1.mover)
check(E.barKey == "bar1" and row("bar").value.text == "Bar 1", "clicking a bar picks it")
E:Select("player")
Bar2.mover.scripts.OnMouseUp(Bar2.mover)
check(E.tab == "bars" and E.barKey == "bar2", "from any tab")
check(E.hint and not E.hint.shown, "still the bars footer")
E:Select("player")
check(E.hint.shown and not E.copy.shown, "other tabs keep their hint")
E:Select("bars")
-- turning a new bar on from the panel
E.barKey = "bar5"
E:RefreshPage()
check(not KUIBar5, "bar 5 isn't made until it's wanted")
row("size"):Set(40)
check(not KUIBar5, "changing an off bar's settings doesn't make it either")
row("on"):Set(true)
check(KUIBar5 and KUIBar5.shown and KUIBar5.mover.shown and KUIBar5Button1.w == 40, "turning it on makes it, with its overlay")
row("on"):Set(false)
check(not KUIBar5.shown and not KUIBar5.mover.shown, "and off hides it")
-- moving a bar
E.barKey = "bar2"
E:RefreshPage()
Bar2.mover.scripts.OnDragStart(Bar2.mover)
Bar2.mover.scripts.OnDragStop(Bar2.mover)
check(KUIDB.barCfg.bar2.left == 300 and KUIDB.barCfg.bar2.top == 600, "dragging saves the spot")
-- copy
E.copy.scripts.OnClick(E.copy)
check(KUIDB.barCfg.bar3.size == 30 and KUIDB.barCfg.pet.size == 30, "copy look: other bars match")
check(KUIDB.barCfg.bar3.left == nil and KUIDB.barCfg.bar3.count == 12 and KUIDB.barCfg.bar3.on, "but stay where they are")
check(KUIDB.barCfg.pet.count == 10, "and keep their own number of buttons")
-- reset
E.reset.scripts.OnClick(E.reset)
check(KUIDB.barCfg.bar2.size == 36 and KUIDB.barCfg.bar2.left == nil and KUIDB.barCfg.bar2.on, "reset this bar")
-- all bars
b.kOut = true
row("barRange"):Set(false)
check(not b.kOut, "turning range off clears red icons now")
row("barRange"):Set(true)
-- totems have fixed buttons, and no slots to leave empty
E.barKey = "totem"
E:RefreshPage()
check(row("size").alpha == 1 and row("gapX").alpha == 1 and row("scale").alpha == 1 and row("on").alpha == 1 and row("mode").alpha == 1, "the totem bar has the layout rows")
check(row("keys").alpha == 1 and row("cdText").alpha == 1 and row("border").alpha == 1, "and text and border")
check(row("count").alpha == 0.45 and row("empty").alpha == 0.45 and row("macro").alpha == 0.45 and row("stack").alpha == 0.45, "but not what it doesn't have")
E.barKey = "bar1"
E:RefreshPage()
check(row("count").alpha == 1 and row("empty").alpha == 1, "and the others keep them")
-- Menu and bags have a tab of their own
E:Select("extras")
check(E.tab == "extras" and E.extraKey == "menu", "the tab opens on the menu")
check(not E.hint.shown and not E.copy.shown and E.keys.shown, "with quick keybinds but no copy button")
local function erow(key)
  for _, r in ipairs(E.pages.extras.rows) do
    if r.def.key == key then return r end
  end
end
check(erow("bar").value.text == "Menu bar", "it says which")
check(erow("CharacterMicroButton") and erow("QuestLogMicroButton") and erow("StoreMicroButton"), "a row for each menu button")
check(erow("HelpMicroButton") == nil, "not for help, which the game hides")
check(erow("slots").alpha == 0.45 and erow("mono").alpha == 1 and erow("CharacterMicroButton").alpha == 1, "bag rows wait for the bag bar")
local Menu = KUIMenubar
erow("size"):Set(30)
check(CharacterMicroButton.w == 30 and CharacterMicroButton.h == 30, "size works")
check(CharacterMicroButton.normalArt.w == 30 * 1.15, "and the art follows")
erow("perRow"):Set(2)
check(Menu.h == 3 * 30 + 2 * 2, "rows work")
erow("border"):Set(false)
check(not CharacterMicroButton.kEdges[1].shown, "border works")
erow("border"):Set(true)
erow("mono"):Set(false)
check(CharacterMicroButton.normalArt.desat == false, "colour icons")
erow("mono"):Set(true)
check(CharacterMicroButton.normalArt.desat == true, "and grey ones")
-- Typing a value
local sz = erow("size")
local function typed(r, text)
  r.value.scripts.OnEditFocusGained(r.value)
  r.value:SetText(text)
  r.value.scripts.OnEnterPressed(r.value)
end
typed(sz, "33")
check(KUIDB.barCfg.menu.size == 33 and sz.value.text == "33" and CharacterMicroButton.w == 33, "a typed value applies")
typed(sz, "999")
check(KUIDB.barCfg.menu.size == 64 and sz.value.text == "64", "held to the row's limit")
typed(sz, "-5")
check(KUIDB.barCfg.menu.size == 16, "both ways")
typed(sz, "27.6")
check(KUIDB.barCfg.menu.size == 28 and sz.value.text == "28", "whole-number rows stay whole")
typed(sz, "rat")
check(KUIDB.barCfg.menu.size == 28 and sz.value.text == "28", "nonsense is ignored and the box goes back")
typed(sz, "")
check(KUIDB.barCfg.menu.size == 28 and sz.value.text == "28", "and so is nothing")
local sc = erow("scale")
typed(sc, "1.23")
check(KUIDB.barCfg.menu.scale == 1.23 and sc.value.text == "1.23", "a typed value needn't land on a slider step")
check(Menu.scale == 1.23, "and it's used")
typed(sc, "1,5")
check(KUIDB.barCfg.menu.scale == 1.5 and sc.value.text == "1.50", "a comma works as a decimal point")
sc:Step(1)
check(math.abs(KUIDB.barCfg.menu.scale - 1.55) < 0.001, "the wheel carries on from there")
typed(sc, "1")
-- While you type
sz.value.scripts.OnEditFocusGained(sz.value)
sz.value:SetText("3")
sz:Refresh()
check(sz.value.text == "3" and KUIDB.barCfg.menu.size == 28, "a refresh doesn't type over you")
sz.value.scripts.OnEscapePressed(sz.value)
check(sz.value.text == "28" and KUIDB.barCfg.menu.size == 28, "Esc puts it back")
sz.value.scripts.OnEditFocusGained(sz.value)
sz.value:SetText("31")
sz.value.scripts.OnEditFocusLost(sz.value)
check(KUIDB.barCfg.menu.size == 31, "clicking away keeps it")
sz.value.scripts.OnEditFocusGained(sz.value)
sz.value:SetText("40")
sz.value.scripts.OnTabPressed(sz.value)
check(KUIDB.barCfg.menu.size == 40, "so does Tab")
inCombat = true
typed(sz, "20")
check(KUIDB.barCfg.menu.size == 40 and sz.value.text == "40", "not in combat")
inCombat = false
erow("size"):Set(30)
-- Taking a button off the bar
local widthWith = Menu.w
erow("perRow"):Set(14)
widthWith = Menu.w
erow("QuestLogMicroButton"):Set(false)
check(KUIDB.barCfg.menu.hide.QuestLogMicroButton == true and erow("QuestLogMicroButton"):Refresh() == nil, "a menu button can come off")
check(QuestLogMicroButton.parent == hidden and Menu.w == widthWith - 32, "and the bar closes up")
erow("QuestLogMicroButton"):Set(true)
check(QuestLogMicroButton.parent == Menu.tray and KUIDB.barCfg.menu.hide.QuestLogMicroButton == nil and Menu.w == widthWith, "and go back")
-- Overlay and mouse
check(Menu.mover.shown and not CharacterMicroButton.mouseOn, "the buttons don't take clicks while editing")
Menu.mover.scripts.OnMouseUp(Menu.mover)
check(E.tab == "extras" and E.extraKey == "menu", "clicking the overlay opens this tab")
local Bags = KUIBagbar
E:Select("player")
Bags.mover.scripts.OnMouseUp(Bags.mover)
check(E.tab == "extras" and E.extraKey == "bags", "from anywhere, on the right bar")
check(erow("bar").value.text == "Bag bar" and erow("slots").alpha == 1 and erow("mono").alpha == 0.45 and erow("CharacterMicroButton").alpha == 0.45, "which swaps the rows over")
erow("slots"):Set(false)
check(CharacterBag0Slot.parent == hidden and MainMenuBarBackpackButton.parent == Bags.tray, "backpack only")
erow("slots"):Set(true)
erow("keyring"):Set(false)
check(KeyRingButton.parent == hidden, "no key ring")
erow("keyring"):Set(true)
erow("reagent"):Set(false)
check(CharacterReagentBag0Slot.parent == hidden, "no reagent bag")
erow("reagent"):Set(true)
erow("stack"):Set(false)
check(MainMenuBarBackpackButton.countShown == false and MainMenuBarBackpackButton.FreeSlots.alpha == 0, "no free slot count")
erow("stack"):Set(true)
check(MainMenuBarBackpackButton.countShown == true, "and back")
erow("stackSize"):Set(15)
check(MainMenuBarBackpackButton.FreeSlots.font[2] == 15, "its size")
erow("on"):Set(false)
check(not Bags.shown and not Bags.mover.shown, "the bag bar can go")
erow("on"):Set(true)
check(Bags.shown and Bags.mover.shown, "and come back")
E.reset.scripts.OnClick(E.reset)
check(KUIDB.barCfg.bags.stackSize == 11 and KUIDB.barCfg.bags.on, "reset this bar")
E:Select("extras")
E.extraKey = "menu"
E.reset.scripts.OnClick(E.reset)
check(KUIDB.barCfg.menu.size == 24 and next(KUIDB.barCfg.menu.hide or {}) == nil, "reset the menu")
E:Select("bars")
-- blocked in combat, closes in combat
inCombat = true
local was = KUIDB.barCfg.bar1.size
row("size"):Set(20)
check(KUIDB.barCfg.bar1.size == was, "no changes in combat")
inCombat = false
U.unlocked = nil -- as if the unit frames were switched off, so only this module can close it
fire("PLAYER_REGEN_DISABLED")
check(not ns.FUI.unlocked and not KUIEditMode.shown and not Bar1.mover.shown, "combat closes it")
check(stateDrivers[Bar1].visibility, "and bars go back to their state drivers")
AB:Slash("reset")
check(not AB.applyPending and KUIDB.barCfg.bar1.size == 36 and KUIDB.barSeeded, "/kui bars reset")
check(Bar1.w == 465, "and applies it")

-- /kui bars debug, and turning the whole thing off
local before = #chat
AB:Slash("debug")
check(#chat > before and table.concat(chat, "\n", before + 1):find("Bar 1: on, slot 1, showing", 1, true), "debug lists the bars")
check(table.concat(chat, "\n", before + 1):find("Bar 8: not on this client", 1, true), "and says what's missing")
SlashCmdList.KUI("bars off")
check(KUIDB.bars == false, "/kui bars off")
AB.enabled = false
SlashCmdList.KUI("bars")
check(chat[#chat]:find("/kui bars on", 1, true), "a hint while it's off")
AB.enabled = true
SlashCmdList.KUI("bars on")
check(KUIDB.bars == true, "/kui bars on")

-- The font follows kUI's setting; the settings window doesn't.
local fontWas = KUIDB.font
KUIDB.font = "chakra"
ns.Style.ApplyFonts()
ns.FUI:Refresh()
check(b.kKey.font[1]:find("ChakraPetch") and b.Count.font[1]:find("ChakraPetch"), "button text follows the font")
check(KUICooldownFontbar1.font[1]:find("ChakraPetch"), "cooldown numbers too")
local typedBox
for _, r in ipairs(E.pages.bars.rows) do
  if r.def.key == "size" then typedBox = r.value end
end
check(typedBox.font[1]:find("Barlow") and not typedBox.font[1]:find("ChakraPetch"), "the boxes you type in stay in the settings font")
KUIDB.font = fontWas
ns.Style.ApplyFonts()
ns.FUI:Refresh()

-- The menu buttons
local Menu, BagBar = KUIMenubar, KUIBagbar
check(Menu and BagBar, "menu and bag bars are made")
check(MicroMenuContainer.parent == hidden and BagsBar.parent == hidden, "the game's holders are put away")
local cm = CharacterMicroButton
check(cm.parent == Menu.tray and StoreMicroButton.parent == Menu.tray, "the buttons move onto ours")
check(HelpMicroButton.parent == hidden, "help stays hidden while the shop is there")
check(cm.Background.parent == hidden and cm.PushedBackground.parent == hidden, "the game's button art goes")
check(cm.Shadow.parent == hidden and cm.PushedShadow.parent == hidden and cm.Portrait.maskRemoved == cm.PortraitMask, "and the portrait goes square")
check(cm.Portrait.points[1][1] == "TOPLEFT" and cm.Portrait.points[1][2] == 2, "filling the button")
check(cm.FlashBorder.ctex and cm.FlashBorder.ctex[4] == 0.35, "alerts go flat too")
check(MainMenuMicroButton.MainMenuBarPerformanceBar.h == 2, "the latency bar becomes a thin line")
check(Menu.w == 5 * 24 + 4 * 2 and Menu.h == 24, "a flat row of the buttons wanted")
check(Menu.points[1][1] == "BOTTOMRIGHT", "bottom right by default")
-- The game shows the shop every time it updates. A removed one has to stay away.
AB:Cfg("menu").hide = { StoreMicroButton = true }
AB:Changed("menu")
StoreMicroButton:Show()
check(StoreMicroButton.parent == hidden, "a removed button stays gone when the game shows it")
AB:Cfg("menu").hide = nil
AB:Changed("menu")
-- Game rules can take buttons away
microRules.ej = true
local listed = {}
for _, it in ipairs(AB:MenuList()) do listed[it.key] = it.name end
check(listed.EJMicroButton == nil and listed.CharacterMicroButton == "Character", "the rows follow the game's rules")
microRules.ej = nil
-- The art comes back whenever a button changes state
QuestLogMicroButton:SetPushed()
check(QuestLogMicroButton.state == "pushed" and QuestLogMicroButton.kBack.ctex[1] == ns.Style.ACCENT[1], "an open window shows on its button")
check(#QuestLogMicroButton.normalArt.points == 1 and QuestLogMicroButton.normalArt.points[1][1] == "CENTER", "the art stays centred")
QuestLogMicroButton:SetNormal()
check(QuestLogMicroButton.kBack.ctex[4] == 0.55 and QuestLogMicroButton.normalArt.points[1][1] == "CENTER", "and closes")
cm.scripts.OnEnter(cm)
check(cm.kEdges[1].ctex[1] == ns.Style.ACCENT[1], "hover lights the border")
cm.scripts.OnLeave(cm)
check(cm.kEdges[1].ctex[1] == ns.Style.SOFT[1], "and lets go")
-- The vehicle bar borrows the buttons, even in combat
inCombat = true
MicroMenu:SetParent(OverrideActionBar)
check(Menu.borrowed and cm.parent == MicroMenu and cm.w == 32 and cm.h == 40, "the vehicle bar can take them")
AB:Changed("menu")
check(cm.parent == MicroMenu, "nothing takes them back early")
MicroMenu:SetParent(MicroMenuContainer)
check(not Menu.borrowed and cm.parent == Menu.tray and cm.w == 24, "and they come back, in combat too")
inCombat = false
MicroMenu:SetParent(new("Frame"))
check(Menu.borrowed, "a pet battle borrows them")
AB:Changed("menu")
check(cm.parent == MicroMenu, "and a change to the bar's settings leaves them there")
fire("PET_BATTLE_CLOSE")
check(not Menu.borrowed and cm.parent == Menu.tray, "and the end of one hands them back")
MicroMenu.parent = MicroMenuContainer
HelpOpenWebTicketButton.points = {}
MicroMenu:UpdateHelpTicketButtonAnchor()
check(HelpOpenWebTicketButton.points[1][2] == cm, "the help ticket button still has somewhere to sit")

-- The bag buttons
local bp, ring = MainMenuBarBackpackButton, KeyRingButton
check(bp.parent == BagBar.tray and CharacterBag3Slot.parent == BagBar.tray and ring.parent == BagBar.tray, "the bag buttons move onto ours")
check(BagBar.w == 7 * 30 + 6 * 3 and BagBar.h == 30, "seven in a row")
check(ring.points[1][4] == 0 and CharacterReagentBag0Slot.points[1][4] == 33 and bp.points[1][4] == 33 * 6, "key ring first, backpack last")
check(bp.art.parent == hidden and bp.IconBorder.parent == hidden and bp.icon.maskRemoved == bp.SquareMask, "the game's art goes, with its mask")
check(bp.icon.points[1][2] == 1, "the icon sits inside the border")
check(ring.icon.tex and ring.icon.tex:find("keyring"), "the key ring gets a square icon")
check(bp.FreeSlots.parent == bp.kText or bp.FreeSlots.points[1][1] == "BOTTOM", "free slots along the bottom")
-- The game redraws these whenever a bag changes
local hi = bp:GetHighlightTexture()
bp:UpdateTextures()
check(hi.ctex and hi.ctex[4] == 0.16 and bp:GetPushedTexture().ctex[4] == 0.4, "bag art stays flat after the game redraws it")
check(bp.SlotHighlightTexture.ctex[4] == 0.3, "an open bag shows")
-- ...and lays them out when you pick up an item
check(unregistered["MainMenuBarManager.OnExpandChanged"] == BagsBar, "picking up an item doesn't lay them out")
bp:SetPoint("RIGHT", BagsBar, "RIGHT")
inCombat = true
BagsBar:Layout()
check(bp.points[1][2] == BagBar.tray and #bp.points == 1, "and when something else does, they go straight back, in combat too")
inCombat = false
-- Keys that aren't on this account
C_ActionBar.ShouldShowKeyring = function() return false end
AB:Changed("bags")
check(ring.parent == hidden and BagBar.w == 6 * 30 + 5 * 3, "no key ring on an account without one")
C_ActionBar.ShouldShowKeyring = function() return true end
AB:Changed("bags")
-- Nothing here is secure, so these can happen in combat: buttons don't need Apply.
check(BagBar.tray.parent == BagBar and Menu.tray.parent == Menu, "plain frames carry the buttons")
check(not stateDrivers[Menu.tray], "with no driver of their own")
-- Same visibility as any bar
AB:Cfg("menu").mode = "combat"
AB:Changed("menu")
check(stateDrivers[Menu].visibility:find("[combat]show;hide", 1, true), "the menu can show only in combat")
AB:ResetBar("menu")
-- Copying a bar's look leaves these alone
AB:Cfg("bar1").size = 50
AB:CopyLook("bar1")
check(AB:Cfg("menu").size == 24 and AB:Cfg("totem").size == 50, "copy look reaches the totem bar, not menu and bags")
AB:ResetBar("bar1")
AB:ResetBar("totem")
for _, def in ipairs({ "bar2", "bar3", "stance", "pet" }) do AB:ResetBar(def) end
-- A client without them
local realMenu = MicroMenu
MicroMenu = nil
check(#AB:MenuList() == 0, "no menu rows without the menu")
MicroMenu = realMenu
-- A problem with them doesn't take the bars down
local realDressed = AB.ApplyOne
local realFrames = AB.frames.menu
AB.frames.menu = nil
AB.SetupMenu, AB.oldSetup = function() error("boom") end, AB.SetupMenu
local chatBefore = #chat
ok = pcall(AB.ApplyAll, AB)
check(ok and AB.failed and AB.failed.menu, "a failed menu bar doesn't stop the others")
check(table.concat(chat, "\n", chatBefore + 1):find("Menu bar left as the game has it", 1, true), "and says so")
local holder = MicroMenuContainer.parent
MicroMenuContainer.parent = UIParent
AB:HideBlizzard()
check(MicroMenuContainer.parent == UIParent, "and the game's menu stays out")
MicroMenuContainer.parent = holder
AB.SetupMenu, AB.oldSetup = AB.oldSetup, nil
AB.failed = nil
AB.frames.menu = realFrames

-- Quick keybinds
check(KUIBar1Button1.commandName == "ACTIONBUTTON1" and KUIBar2Button3.commandName == "MULTIACTIONBAR1BUTTON3", "the game's mode can see our action buttons")
check(KUIBar3Button1.commandName == "MULTIACTIONBAR2BUTTON1", "on the right bars")
check(PetActionButton1.commandName == "BONUSACTIONBUTTON1" and MultiCastActionButton2.commandName == "MULTICASTACTIONBUTTON2", "pet and totem buttons too")
local qk, kb = QuickKeybindFrame, KUIBar1Button1
for _, btn in ipairs({ kb, cm, bp }) do btn.QuickKeybindHighlightTexture = btn:CreateTexture() end
bp.commandName, cm.commandName = "TOGGLEBACKPACK", "TOGGLECHARACTER0"
local glow = kb.QuickKeybindHighlightTexture
glow.shown = false
AB:Cfg("bar1").empty = false
AB:Cfg("bar2").mode = "combat"
AB:Changed("bar1")
AB:Changed("bar2")
check(KUIBar1Button5.alpha == 0 and stateDrivers[KUIBar2].visibility, "an empty slot and a combat-only bar, before")
SettingsPanel.shown = false
ns.FUI:SetUnlocked(true)
chat[#chat + 1] = ""
inCombat = true
AB:QuickKeys()
check(not qk.shown and chat[#chat]:find("in combat", 1, true), "it won't open in combat")
inCombat = false
AB:QuickKeys()
check(qk.shown and not ns.FUI.unlocked and not KUIEditMode.shown, "it opens the game's mode, closing the edit mode")
check(AB.quick and AB.quickOpened == "edit", "and remembers where it came from")
check(glow.shown and glow.ctex[1] == ns.Style.ACCENT[1], "our buttons light up, flat")
check(cm.QuickKeybindHighlightTexture.shown and bp.QuickKeybindHighlightTexture.shown, "menu and bag buttons too")
check(KUIBar1Button5.alpha == 1, "empty slots show, to be bound")
check(not stateDrivers[KUIBar2].visibility and KUIBar2.shown, "and every bar stays up")
check(not KUIBar2.mover.shown, "with no overlays in the way")
AB:Cfg("bar3").mode = "hover"
AB:Cfg("bar3").fadeTo = 0
AB:Changed("bar3")
AB.ev.scripts.OnUpdate(AB.ev, 10)
check(KUIBar3.alpha == 1, "and a faded bar wakes")
AB:ResetBar("bar3")
-- A new key shows at once
barKeys.ACTIONBUTTON1 = { "ALT-3" }
fire("UPDATE_BINDINGS")
check(kb.kKey.text == "A3" and boundKeys["ALT-3"] and boundKeys["ALT-3"].name == "KUIBar1Button1Key", "a new key shows and works straight away")
qk:Hide()
check(not AB.quick and not glow.shown, "closing it puts the lights out")
check(not SettingsPanel.shown, "the game's settings don't pop up")
check(ns.FUI.unlocked and KUIEditMode.shown, "and it's back in the edit mode")
ns.FUI:SetUnlocked(false)
check(KUIBar1Button5.alpha == 0 and stateDrivers[KUIBar2].visibility, "and the bars go back to how you set them")
AB:QuickKeys()
qk:Hide()
check(not ns.FUI.unlocked, "opened from the world, it goes back to the world")
SlashCmdList.KUI("keys")
check(qk.shown, "/kui keys")
-- Combat closes it
fire("PLAYER_REGEN_DISABLED")
check(qk.cancelled and not qk.shown and not AB.quick and chat[#chat]:find("in combat", 1, true), "entering combat closes it")
qk.cancelled = nil
-- Opened from the game's own settings, the game's way of closing stands
SettingsPanel.shown = false
qk:Show()
check(AB.quick and glow.shown and not AB.quickOpened, "opened from the game's settings, ours still light up")
qk:Hide()
check(SettingsPanel.shown, "and its settings come back")
SettingsPanel.shown = false
local realQk = QuickKeybindFrame
QuickKeybindFrame = nil
AB:QuickKeys()
check(chat[#chat]:find("aren't on this client", 1, true), "a client without it says so")
QuickKeybindFrame = realQk
AB:Cfg("bar1").empty = true
AB:Cfg("bar2").mode = "always"
AB:Changed("bar1")
AB:Changed("bar2")

-- If kUI's bars can't be built, the game's stay.
local mb = MultiBar6
local oldParent = new("Frame")
mb.parent = oldParent
local realApply, realEv = AB.ApplyAll, AB.ev
AB.ApplyAll = function() error("boom") end
ok = pcall(AB.Start, AB)
check(not ok and mb.parent == oldParent, "a failure leaves the game's bars in place")
AB.ApplyAll, AB.ev = realApply, realEv
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
