-- kUI · Unit frames
-- Flat player, target, target-of-target and pet frames in the shared style,
-- replacing Blizzard's. Each frame is laid out from its own settings, so the edit
-- mode (/kui edit) can change any of them while you watch: size, fonts, name,
-- level, numbers, class colours, portrait and the elite and rare style.
--
--   Left-click   target        Right-click   the game's unit menu
--
-- Blizzard's totem frame is moved out first and sits above the player frame.
-- Combo points are a row of pips under the player frame (Rogue and Druid).
--
-- Numbers can be secret on this client, so they go straight to the widgets:
-- nothing here adds up or compares a health or power value unless Safe() let it through.

local _, ns = ...
local FUI, S = ns.FUI, ns.Style

local U = { key = "frames", name = "Unit frames", frames = {}, byUnit = {}, auras = {} }
ns.UnitFrames = U

local Safe, Present = S.Safe, S.Present
local floor, max = math.floor, math.max

local ICON_GAP, MAX_AURAS = 3, 16
local FRAME_KEYS = { "player", "target", "tot", "pet" }

local DEFAULTS = {
  player = {
    width = 230, hpHeight = 20, power = true, pwHeight = 12,
    name = "full", nameSize = 13, level = true, tags = true,
    hpText = true, hpPct = true, barSize = 12, pwText = true, pwSize = 10,
    classColor = true, portrait = "off", portraitSide = "left", elite = "off", scale = 1,
  },
  target = {
    width = 230, hpHeight = 20, power = true, pwHeight = 12,
    name = "full", nameSize = 13, level = true, tags = true,
    hpText = true, hpPct = true, barSize = 12, pwText = true, pwSize = 10,
    classColor = true, portrait = "off", portraitSide = "right", elite = "glow", scale = 1,
    auras = true, auraSize = 22,
  },
  tot = {
    width = 120, hpHeight = 10, power = false, pwHeight = 5,
    name = "full", nameSize = 11, level = false, tags = false,
    hpText = false, hpPct = false, barSize = 10, pwText = false, pwSize = 9,
    classColor = true, portrait = "off", portraitSide = "right", elite = "off", scale = 1,
  },
  pet = {
    width = 120, hpHeight = 10, power = true, pwHeight = 5,
    name = "full", nameSize = 11, level = false, tags = false,
    hpText = false, hpPct = false, barSize = 10, pwText = false, pwSize = 9,
    classColor = true, portrait = "off", portraitSide = "left", elite = "off", scale = 1,
  },
}
U.DEFAULTS = DEFAULTS

local HOSTILE, NEUTRAL, FRIENDLY = { 0.8, 0.25, 0.2 }, { 0.9, 0.75, 0.25 }, { 0.3, 0.7, 0.35 }
local GREY = { 0.5, 0.5, 0.5 }
local POWER = {
  MANA = { 0.25, 0.5, 0.95 }, RAGE = { 0.85, 0.25, 0.25 }, ENERGY = { 0.95, 0.8, 0.25 },
  FOCUS = { 0.95, 0.55, 0.25 }, RUNIC_POWER = { 0, 0.82, 1 },
}
local CLASSIFICATION = {
  worldboss = "|cffff5555Boss|r", rareelite = "|cffc8c8ffRare Elite|r",
  elite = "|cffffd100Elite|r", rare = "|cffc8c8ffRare|r",
}
local ELITE_RGB = {
  worldboss = { 1, 0.33, 0.33 }, rareelite = { 0.78, 0.78, 1 },
  elite = { 1, 0.82, 0 }, rare = { 0.78, 0.78, 1 },
}

-- One frame's settings. Anything missing comes from the defaults, and the older
-- all-frames settings carry over the first time a frame is seen.
function U:Cfg(key)
  local db = ns.db
  db.frameCfg = db.frameCfg or {}
  local c = db.frameCfg[key]
  if not c then
    c = { classColor = db.classColor, scale = db.frameScale }
    db.frameCfg[key] = c
  end
  for k, v in pairs(DEFAULTS[key]) do
    if c[k] == nil then c[k] = v end
  end
  return c
end

------------------------------------------------------------------------
-- Values
------------------------------------------------------------------------

local function Num(v)
  if BreakUpLargeNumbers then return BreakUpLargeNumbers(v) end
  if AbbreviateNumbers then return AbbreviateNumbers(v) end
  return Safe(v) and tostring(v) or "?"
end

local function Percent(u, cur, maxv)
  local c, m = Safe(cur), Safe(maxv)
  if c and m then return m > 0 and floor(c / m * 100 + 0.5) or 0 end
  if UnitHealthPercent and CurveConstants then
    local p = UnitHealthPercent(u, nil, CurveConstants.ScaleTo100)
    if C_StringUtil and C_StringUtil.RoundToNearestString then return C_StringUtil.RoundToNearestString(p) end
    if AbbreviateNumbers then return AbbreviateNumbers(p) end
  end
  return "?"
end

local function ClassColor(u)
  local _, class = UnitClass(u)
  if C_ClassColor and C_ClassColor.GetClassColor then
    local c = C_ClassColor.GetClassColor(class)
    if c then return c.r, c.g, c.b end
  end
  local key = Safe(class)
  local c = key and RAID_CLASS_COLORS and RAID_CLASS_COLORS[key]
  if c then return c.r, c.g, c.b end
end

local function ReactionColor(u)
  local n = Safe(UnitReaction(u, "player"))
  local c = FRIENDLY
  if n then
    if n <= 3 then c = HOSTILE elseif n == 4 then c = NEUTRAL end
  end
  return c[1], c[2], c[3]
end

local function HealthColor(u, useClass)
  if Safe(UnitIsPlayer(u)) then
    if useClass then
      local r, g, b = ClassColor(u)
      if r then return r, g, b end
    end
    return FRIENDLY[1], FRIENDLY[2], FRIENDLY[3]
  end
  if Safe(UnitIsTapDenied(u)) then return GREY[1], GREY[2], GREY[3] end
  return ReactionColor(u)
end

-- This client's player names come in two parts: "Da" and "Rat".
local function SetName(fs, u, mode)
  local first, second = UnitName(u)
  if mode ~= "first" and Present(second) and Safe(second) ~= ""
    and RegionalUniqueNamesEnabled and RegionalUniqueNamesEnabled() then
    local names = Constants and Constants.CharacterNameSeparatorConsts
    fs:SetFormattedText("%s%s%s", first, names and names.CHARACTERNAME_SURNAME_SEPARATOR or " ", second)
  else
    fs:SetText(first)
  end
end

-- While placing the frames, the target frame can pretend to be an elite or rare.
local function Classification(f)
  if f.key == "target" and U.unlocked then return U.previewClass end
  return Safe(UnitClassification(f.unit))
end

------------------------------------------------------------------------
-- Painting a frame
------------------------------------------------------------------------

function U:UpdateHealth(f)
  local u, c = f.unit, self:Cfg(f.key)
  local cur, maxv = UnitHealth(u), UnitHealthMax(u)
  f.hp:SetMinMaxValues(0, maxv)
  f.hp:SetValue(cur)
  local status
  if Safe(UnitIsConnected(u)) == false then
    status = "Offline"
  elseif Safe(UnitIsGhost(u)) then
    status = "Ghost"
  elseif Safe(UnitIsDead(u)) then
    status = "Dead"
  end
  if status then
    f.hpText:SetText(status)
    f.hpPct:SetText("")
    f.hpText:SetShown(c.hpText or c.hpPct)
  else
    f.hpText:SetFormattedText("%s / %s", Num(cur), Num(maxv))
    f.hpPct:SetFormattedText("%s%%", Percent(u, cur, maxv))
    f.hpText:SetShown(c.hpText)
  end
end

function U:UpdatePower(f)
  if not self:Cfg(f.key).power then return end
  local u = f.unit
  local kind, token = UnitPowerType(u)
  local c = POWER[Safe(token)] or (PowerBarColor and PowerBarColor[Safe(token)]) or GREY
  S.BarColor(f.pw, c[1] or c.r, c[2] or c.g, c[3] or c.b)
  local cur, maxv = UnitPower(u, kind), UnitPowerMax(u, kind)
  f.pw:SetMinMaxValues(0, maxv)
  f.pw:SetValue(cur)
  if Safe(maxv) == 0 then
    f.pwText:SetText("")
  else
    f.pwText:SetFormattedText("%s / %s", Num(cur), Num(maxv))
  end
end

function U:UpdateLevel(f)
  local lvl = Safe(UnitLevel(f.unit))
  if not lvl then
    f.level:SetText("")
  elseif lvl <= 0 then
    f.level:SetText("??")
    f.level:SetTextColor(1, 0.3, 0.3)
  else
    f.level:SetText(lvl)
    local r, g, b = S.LABEL[1], S.LABEL[2], S.LABEL[3]
    if f.unit ~= "player" and GetCreatureDifficultyColor then
      local ok, c = pcall(GetCreatureDifficultyColor, lvl)
      if ok and type(c) == "table" and c.r then r, g, b = c.r, c.g, c.b end
    end
    f.level:SetTextColor(r, g, b)
  end
end

function U:UpdateTag(f)
  local u = f.unit
  local parts = {}
  if f.key == "player" then
    if Safe(UnitAffectingCombat(u)) then
      parts[#parts + 1] = "|cffff5555Combat|r"
    elseif IsResting and IsResting() then
      parts[#parts + 1] = "|cff7fc8ffRested|r"
    end
    if Safe(UnitIsGroupLeader(u)) then parts[#parts + 1] = "|cffffd100Lead|r" end
  else
    local c = CLASSIFICATION[Classification(f)]
    if c then parts[#parts + 1] = c end
  end
  if Safe(UnitIsPVP(u)) then parts[#parts + 1] = "|cffff8040PvP|r" end
  f.tag:SetText(table.concat(parts, " "))
end

function U:UpdateRaidIcon(f)
  local i = Safe(GetRaidTargetIndex(f.unit))
  if i and SetRaidTargetIconTexture and self:Cfg(f.key).tags then
    SetRaidTargetIconTexture(f.raid, i)
    f.raid:Show()
  else
    f.raid:Hide()
  end
end

function U:UpdateName(f)
  local u, mode = f.unit, self:Cfg(f.key).name
  SetName(f.name, u, mode)
  if f.key == "player" then
    f.name:SetTextColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3])
  elseif Safe(UnitIsPlayer(u)) then
    f.name:SetTextColor(1, 1, 1)
  elseif Safe(UnitIsTapDenied(u)) then
    f.name:SetTextColor(GREY[1], GREY[2], GREY[3])
  else
    f.name:SetTextColor(ReactionColor(u))
  end
end

function U:UpdateColor(f)
  S.BarColor(f.hp, HealthColor(f.unit, self:Cfg(f.key).classColor))
end

-- Coloured outline, and a soft glow if chosen, for elites, rares and bosses.
function U:UpdateElite(f)
  local style = self:Cfg(f.key).elite
  local rgb = style ~= "off" and ELITE_RGB[Classification(f)]
  if rgb then
    S.GlowRGB(f.eliteGlow, rgb[1], rgb[2], rgb[3], style == "glow" and 0.35 or 0)
  else
    S.GlowOff(f.eliteGlow)
  end
end

-- force: paint it even if the unit looks the same. Without it, a model isn't reloaded for nothing.
function U:UpdatePortrait(f, force)
  local mode = self:Cfg(f.key).portrait
  if mode == "off" then return end
  local u = f.unit
  local guid = Safe(UnitGUID(u))
  if not force and (guid == nil or guid == f.portraitGUID) then return end
  f.portraitGUID = guid
  if mode == "2d" then
    if SetPortraitTexture then SetPortraitTexture(f.portrait2d, u) end
  elseif f.portrait3d then
    local m = f.portrait3d
    if Safe(UnitIsVisible(u)) == false then
      if m.ClearModel then m:ClearModel() end
    else
      pcall(m.SetUnit, m, u)
      if m.SetPortraitZoom then pcall(m.SetPortraitZoom, m, 1) end
    end
  end
end

function U:Update(f, light)
  if not f then return end
  if Safe(UnitExists(f.unit)) == false then return end
  self:UpdateName(f)
  self:UpdateLevel(f)
  self:UpdateTag(f)
  self:UpdateRaidIcon(f)
  self:UpdateColor(f)
  self:UpdateHealth(f)
  self:UpdatePower(f)
  self:UpdateElite(f)
  self:UpdatePortrait(f, not light)
end

function U:UpdateAll()
  for _, f in pairs(self.frames) do self:Update(f) end
  self:UpdateAuras()
  self:UpdatePips()
end

------------------------------------------------------------------------
-- Target buffs and debuffs
------------------------------------------------------------------------

local function AuraEnter(b)
  if not b.aura then return end
  GameTooltip:SetOwner(b, "ANCHOR_BOTTOMRIGHT")
  local id = b.aura.auraInstanceID
  if id and GameTooltip.SetUnitAuraByAuraInstanceID then
    GameTooltip:SetUnitAuraByAuraInstanceID("target", id)
  elseif GameTooltip.SetUnitAura then
    GameTooltip:SetUnitAura("target", b.index, b.filter)
  end
  GameTooltip:Show()
end

function U:AuraButton(i)
  local b = self.auras[i]
  if b then return b end
  b = CreateFrame("Frame", nil, self.auraRow)
  b:EnableMouse(true)
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetAllPoints()
  b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  b.edges = S.Edges(b, "OVERLAY", 6)
  b.cd = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
  b.cd:SetAllPoints()
  b.cd:SetDrawEdge(false)
  b.cd:SetReverse(true)
  b.count = S.Text(b, "NumberFontNormal", "RIGHT", "OVERLAY", 11, "OUTLINE")
  b.count:SetDrawLayer("OVERLAY", 7)
  b.count:SetPoint("BOTTOMRIGHT", 1, 0)
  b:SetScript("OnEnter", AuraEnter)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  self.auras[i] = b
  return b
end

-- As many icons in a row as fit the frame's width, then the next row up.
function U:PlaceAura(b, i)
  local c = self:Cfg("target")
  local size = c.auraSize
  local step = size + ICON_GAP
  local perRow = max(1, floor((c.width + ICON_GAP) / step))
  local row, col = floor((i - 1) / perRow), (i - 1) % perRow
  b:SetSize(size, size)
  b:ClearAllPoints()
  b:SetPoint("BOTTOMLEFT", self.auraRow, "BOTTOMLEFT", col * step, row * step)
end

function U:PaintAura(b, a, index, filter)
  b.aura, b.index, b.filter = a, index, filter
  b.icon:SetTexture(a.icon)

  local n = Safe(a.applications)
  if n then
    b.count:SetText(n > 1 and n or "")
  elseif C_UnitAuras.GetAuraApplicationDisplayCount then
    local ok, text = pcall(C_UnitAuras.GetAuraApplicationDisplayCount, "target", a.auraInstanceID, 2, 99)
    b.count:SetText(ok and text or "")
  else
    b.count:SetText("")
  end

  local d, e = Safe(a.duration), Safe(a.expirationTime)
  if d and e then
    if d > 0 then
      b.cd:SetCooldown(e - d, d)
      b.cd:Show()
    else
      b.cd:Hide()
    end
  elseif C_UnitAuras.GetAuraDuration and b.cd.SetCooldownFromDurationObject then
    local ok, obj = pcall(C_UnitAuras.GetAuraDuration, "target", a.auraInstanceID)
    if ok and obj then
      b.cd:SetCooldownFromDurationObject(obj)
      b.cd:Show()
    else
      b.cd:Hide()
    end
  else
    b.cd:Hide()
  end

  local r, g, bl, alpha = S.EDGE[1], S.EDGE[2], S.EDGE[3], 0.8
  local kind = Safe(a.dispelName)
  local c = filter == "HARMFUL" and kind and DebuffTypeColor and DebuffTypeColor[kind]
  if c then
    r, g, bl, alpha = c.r, c.g, c.b, 1
  elseif Safe(a.isFromPlayerOrPlayerPet) then
    r, g, bl, alpha = S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 1
  end
  S.ColorEdges(b.edges, r, g, bl, alpha)
  b:Show()
end

function U:UpdateAuras()
  if not self.auraRow then return end
  local shown = 0
  local on = self:Cfg("target").auras
  if on and not self.unlocked and Safe(UnitExists("target")) ~= false and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
    for _, filter in ipairs({ "HARMFUL", "HELPFUL" }) do
      local i = 1
      while shown < MAX_AURAS do
        local a = C_UnitAuras.GetAuraDataByIndex("target", i, filter)
        if not a then break end
        shown = shown + 1
        local b = self:AuraButton(shown)
        self:PlaceAura(b, shown)
        self:PaintAura(b, a, i, filter)
        i = i + 1
      end
    end
  end
  for i = shown + 1, #self.auras do
    self.auras[i].aura = nil
    self.auras[i]:Hide()
  end
end

-- The auras sit above the target's cast bar when it's up, otherwise above the frame.
function U:AnchorAuras()
  local bar = self.targetBar
  local c = self:Cfg("target")
  local over = (bar and bar:IsShown()) and bar or self.frames.target
  self.auraRow:ClearAllPoints()
  self.auraRow:SetPoint("BOTTOMLEFT", over, "TOPLEFT", 0, 4)
  self.auraRow:SetSize(c.width, c.auraSize)
end

------------------------------------------------------------------------
-- Combo points
------------------------------------------------------------------------

function U:BuildPips()
  local _, class = UnitClass("player")
  class = Safe(class)
  if class ~= "ROGUE" and class ~= "DRUID" then return end
  local p = self.frames.player
  local kind = Enum.PowerType and Enum.PowerType.ComboPoints
  local n = (kind and Safe(UnitPowerMax("player", kind))) or 5
  if n <= 0 then n = 5 end
  local row = CreateFrame("Frame", nil, p)
  row:SetPoint("TOPLEFT", p, "BOTTOMLEFT", 0, -2)
  row:SetPoint("TOPRIGHT", p, "BOTTOMRIGHT", 0, -2)
  row:SetHeight(6)
  row.pips = {}
  for i = 1, n do
    local b = S.Bar(row)
    b:SetMinMaxValues(i - 1, i) -- fills when the count reaches i, even if the count is secret
    S.BarColor(b, 1, 0.82, 0)
    row.pips[i] = b
  end
  row.druid = class == "DRUID"
  self.pips = row
  self:LayoutPips()
end

function U:LayoutPips()
  local row = self.pips
  if not row then return end
  local n = #row.pips
  local w = (self:Cfg("player").width - (n - 1) * 2) / n
  for i, b in ipairs(row.pips) do
    b:SetSize(w, 6)
    b:ClearAllPoints()
    b:SetPoint("LEFT", row, "LEFT", (i - 1) * (w + 2), 0)
  end
end

function U:UpdatePips()
  local row = self.pips
  if not row then return end
  local cur = 0
  if GetComboPoints then
    cur = GetComboPoints("player", "target")
  elseif Enum.PowerType then
    cur = UnitPower("player", Enum.PowerType.ComboPoints)
  end
  for _, b in ipairs(row.pips) do b:SetValue(cur) end
  -- A Druid only needs them while they have some. A secret count stays shown.
  row:SetShown(not row.druid or Safe(cur) ~= 0)
end

------------------------------------------------------------------------
-- Building
------------------------------------------------------------------------

function U:Make(key, unit, name)
  local f = self.frames[key]
  if f then return f end
  f = CreateFrame("Button", name, UIParent, "SecureUnitButtonTemplate")
  f.key, f.unit, f.realUnit = key, unit, unit
  f:SetFrameStrata("LOW")
  f:SetClampedToScreen(true)
  f:SetAttribute("unit", unit)
  f:SetAttribute("type1", "target")
  f:SetAttribute("type2", "togglemenu")
  f:RegisterForClicks("AnyUp")
  f:HookScript("OnEnter", function(self)
    if GameTooltip_SetDefaultAnchor then GameTooltip_SetDefaultAnchor(GameTooltip, self) end
    GameTooltip:SetUnit(self.unit)
    GameTooltip:Show()
  end)
  f:HookScript("OnLeave", function() GameTooltip:Hide() end)
  f:HookScript("OnShow", function(self) U:Update(self) end)
  S.Panel(f)
  f.strip = S.Header(f)

  f.name = S.Text(f, "GameFontNormalSmall", nil, "OVERLAY", 13)
  f.level = S.Text(f, "GameFontHighlightSmall", "RIGHT", "OVERLAY", 12)
  f.tag = S.Text(f, "GameFontHighlightSmall", "RIGHT", "OVERLAY", 11)
  f.raid = S.Tex(f, "OVERLAY", 1)
  f.raid:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
  f.raid:SetSize(14, 14)
  f.raid:Hide()

  f.hp = S.Bar(f)
  f.hpText = S.Text(f.hp, "GameFontHighlightSmall", "RIGHT", "OVERLAY", 12, "OUTLINE")
  f.hpText:SetPoint("RIGHT", -5, 0)
  f.hpPct = S.Text(f.hp, "GameFontHighlightSmall", nil, "OVERLAY", 12, "OUTLINE")
  f.hpPct:SetPoint("LEFT", 5, 0)
  f.pw = S.Bar(f)
  f.pwText = S.Text(f.pw, "GameFontHighlightSmall", "RIGHT", "OVERLAY", 10, "OUTLINE")
  f.pwText:SetPoint("RIGHT", -5, 0)

  f.portrait2d = S.Tex(f, "ARTWORK")
  f.portrait2d:SetTexCoord(0.15, 0.85, 0.15, 0.85)
  f.portrait2d:Hide()

  -- Above the bars, or the elite outline and glow would be hidden behind them.
  f.over = CreateFrame("Frame", nil, f)
  f.over:SetAllPoints(f)
  f.over:SetFrameLevel(f:GetFrameLevel() + 5)
  f.eliteGlow = S.Glow(f.over, f.over, 20)
  S.GlowOff(f.eliteGlow)

  f.mover = S.Mover(f, name:gsub("^KUI", ""):gsub("Frame$", ""), function(left, top)
    ns.db[key .. "Left"], ns.db[key .. "Top"] = left, top
  end)

  _G.ClickCastFrames = _G.ClickCastFrames or {}
  _G.ClickCastFrames[f] = true
  self.frames[key] = f
  self.byUnit[unit] = f
  return f
end

-- Sizes and anchors everything from the frame's settings. Out of combat only.
function U:Layout(f)
  local c = self:Cfg(f.key)
  local nameOn = c.name ~= "off"
  local header = nameOn or c.level or c.tags
  local head = header and max(c.nameSize, 8) + 5 or 1
  local pwTotal = c.power and c.pwHeight + 1 or 0
  local height = head + c.hpHeight + pwTotal + 1
  f:SetSize(c.width, height)
  f:SetScale(c.scale)

  -- Portrait: a square on one side, the full height of the frame.
  local left, right = 1, 1
  local showPortrait = c.portrait ~= "off"
  local size = height - 2
  if showPortrait then
    if c.portraitSide == "left" then left = size + 2 else right = size + 2 end
  end
  local tex = f.portrait2d
  tex:ClearAllPoints()
  tex:SetSize(size, size)
  local point = c.portraitSide == "left" and "TOPLEFT" or "TOPRIGHT"
  local px = c.portraitSide == "left" and 1 or -1
  tex:SetPoint(point, f, point, px, -1)
  tex:SetShown(c.portrait == "2d")
  if c.portrait == "3d" and not f.portrait3d then
    f.portrait3d = CreateFrame("PlayerModel", nil, f)
  end
  if f.portrait3d then
    f.portrait3d:ClearAllPoints()
    f.portrait3d:SetSize(size, size)
    f.portrait3d:SetPoint(point, f, point, px, -1)
    f.portrait3d:SetShown(c.portrait == "3d")
  end
  f.portraitGUID = nil

  -- Header strip: name on the left, then level and tags from the right.
  local strip = f.strip
  strip:ClearAllPoints()
  strip:SetPoint("TOPLEFT", f, "TOPLEFT", left, -1)
  strip:SetPoint("TOPRIGHT", f, "TOPRIGHT", -right, -1)
  strip:SetHeight(max(head - 1, 1))
  strip:SetShown(header)
  local mid = -(head / 2)
  S.SetFont(f.name, max(c.nameSize, 8))
  S.SetFont(f.level, max(c.nameSize - 1, 8))
  S.SetFont(f.tag, max(c.nameSize - 2, 8))
  f.name:SetShown(nameOn)
  f.level:SetShown(c.level)
  f.tag:SetShown(c.tags)
  f.level:ClearAllPoints()
  f.level:SetPoint("RIGHT", f, "TOPRIGHT", -right - 5, mid)
  f.tag:ClearAllPoints()
  if c.level then
    f.tag:SetPoint("RIGHT", f.level, "LEFT", -5, 0)
  else
    f.tag:SetPoint("RIGHT", f, "TOPRIGHT", -right - 5, mid)
  end
  f.raid:ClearAllPoints()
  f.raid:SetPoint("RIGHT", c.tags and f.tag or f.level, "LEFT", -4, 0)
  f.name:ClearAllPoints()
  f.name:SetPoint("LEFT", f, "TOPLEFT", left + 5, mid)
  if c.tags then
    f.name:SetPoint("RIGHT", f.raid, "LEFT", -4, 0)
  elseif c.level then
    f.name:SetPoint("RIGHT", f.level, "LEFT", -4, 0)
  else
    f.name:SetPoint("RIGHT", f, "TOPRIGHT", -right - 4, mid)
  end

  -- Bars.
  f.hp:ClearAllPoints()
  f.hp:SetPoint("TOPLEFT", f, "TOPLEFT", left, -head)
  f.hp:SetPoint("TOPRIGHT", f, "TOPRIGHT", -right, -head)
  f.hp:SetHeight(c.hpHeight)
  S.SetFont(f.hpText, c.barSize, "OUTLINE")
  S.SetFont(f.hpPct, c.barSize, "OUTLINE")
  f.hpText:SetShown(c.hpText)
  f.hpPct:SetShown(c.hpPct)
  f.pw:SetShown(c.power)
  f.pw:ClearAllPoints()
  f.pw:SetPoint("TOPLEFT", f.hp, "BOTTOMLEFT", 0, -1)
  f.pw:SetPoint("TOPRIGHT", f.hp, "BOTTOMRIGHT", 0, -1)
  f.pw:SetHeight(c.pwHeight)
  S.SetFont(f.pwText, c.pwSize, "OUTLINE")
  f.pwText:SetShown(c.pwText)

  if f.key == "player" then self:LayoutPips() end
  if f.key == "target" and self.auraRow then
    self:AnchorAuras()
    self:UpdateAuras()
  end
end

function U:LayoutAll()
  for _, f in pairs(self.frames) do self:Layout(f) end
  self:Place()
end

function U:Build()
  if self.frames.player then return end
  local p = self:Make("player", "player", "KUIPlayerFrame")
  local t = self:Make("target", "target", "KUITargetFrame")
  local tot = self:Make("tot", "targettarget", "KUIToTFrame")
  local pet = self:Make("pet", "pet", "KUIPetFrame")
  for _, f in ipairs({ t, tot, pet }) do RegisterUnitWatch(f) end

  -- There's no event when your target's target changes, so that frame checks.
  local elapsed = 0
  tot:SetScript("OnUpdate", function(self, dt)
    elapsed = elapsed + dt
    if elapsed < 0.25 then return end
    elapsed = 0
    U:Update(self, true)
  end)

  self.auraRow = CreateFrame("Frame", nil, t)
  local bar = ns.Castbar:Make("KUITargetCastbar", "target", t)
  bar:SetPoint("BOTTOMLEFT", t, "TOPLEFT", 0, 3)
  bar:SetPoint("BOTTOMRIGHT", t, "TOPRIGHT", 0, 3)
  bar.off = not ns.db.targetCast or nil
  bar:HookScript("OnShow", function() U:AnchorAuras() end)
  bar:HookScript("OnHide", function() U:AnchorAuras() end)
  self.targetBar = bar
  ns.Castbar.target = bar
  ns.Castbar:LayoutAll()
  self:BuildPips()
  self:LayoutAll()
end

-- Default spots sit either side of the middle, just above the action bars.
function U:Place()
  local w, h = UIParent:GetWidth(), UIParent:GetHeight()
  local db, fr = ns.db, self.frames
  local x, y = floor(w * 0.115), floor(h * 0.29)
  local spots = {
    player = { "CENTER", UIParent, "BOTTOM", -x, y },
    target = { "CENTER", UIParent, "BOTTOM", x, y },
    tot = { "TOPLEFT", fr.target, "TOPRIGHT", 6, 0 },
    pet = { "TOPRIGHT", fr.player, "TOPLEFT", -6, 0 },
  }
  for _, key in ipairs(FRAME_KEYS) do
    local f = fr[key]
    f:ClearAllPoints()
    if db[key .. "Left"] then
      f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", db[key .. "Left"], db[key .. "Top"])
    else
      local s = spots[key]
      f:SetPoint(s[1], s[2], s[3], s[4], s[5])
    end
  end
end

-- One frame back to its defaults, spot included.
function U:ResetFrame(key)
  local db = ns.db
  db.frameCfg = db.frameCfg or {}
  db.frameCfg[key] = { classColor = DEFAULTS[key].classColor, scale = DEFAULTS[key].scale }
  db[key .. "Left"], db[key .. "Top"] = nil, nil
  local f = self.frames[key]
  self:Layout(f)
  self:Place()
  self:Update(f)
  if key == "target" then
    db.targetCast, db.targetCastH = FUI.defaults.targetCast, FUI.defaults.targetCastH
    ns.Castbar:SetTargetBar(db.targetCast)
    ns.Castbar:LayoutAll()
  end
end

------------------------------------------------------------------------
-- Blizzard's frames
------------------------------------------------------------------------

local function Gone(fr)
  if type(fr) ~= "table" then return end
  if UnregisterUnitWatch then pcall(UnregisterUnitWatch, fr) end
  pcall(fr.UnregisterAllEvents, fr)
  pcall(fr.Hide, fr)
  pcall(fr.SetParent, fr, S.HiddenParent())
  for _, k in ipairs({ "healthbar", "healthBar", "HealthBar", "manabar", "ManaBar", "spellbar" }) do
    local part = fr[k]
    if type(part) == "table" then pcall(part.UnregisterAllEvents, part) end
  end
end

-- Totems live inside Blizzard's player frame, so they move out before it goes.
function U:AnchorTotems()
  local tf = self.totems
  if not tf or self.anchoring then return end
  if InCombatLockdown() and tf.IsProtected and tf:IsProtected() then
    self.totemsPending = true
    return
  end
  self.anchoring = true
  tf:ClearAllPoints()
  tf:SetPoint("BOTTOMLEFT", self.frames.player, "TOPLEFT", 0, 4)
  self.anchoring = false
  self.totemsPending = nil
end

function U:HideBlizzard()
  local tf = _G.TotemFrame
  if type(tf) == "table" then
    self.totems = tf
    pcall(tf.SetParent, tf, UIParent)
    self:AnchorTotems()
    hooksecurefunc(tf, "SetPoint", function() U:AnchorTotems() end)
  end
  for _, name in ipairs({ "PlayerFrame", "PetFrame", "TargetFrame", "TargetFrameToT", "TargetFrameSpellBar", "ComboFrame" }) do
    Gone(_G[name])
  end
end

------------------------------------------------------------------------
-- Events
------------------------------------------------------------------------

local function TargetChanged()
  U:Update(U.frames.target)
  U:Update(U.frames.tot)
  U:UpdateAuras()
  U:UpdatePips()
  if not (PlaySound and SOUNDKIT) then return end
  if Safe(UnitExists("target")) == false then
    if SOUNDKIT.INTERFACE_SOUND_LOST_TARGET_UNIT then PlaySound(SOUNDKIT.INTERFACE_SOUND_LOST_TARGET_UNIT) end
  elseif Safe(UnitIsEnemy("target", "player")) then
    if SOUNDKIT.IG_CREATURE_AGGRO_SELECT then PlaySound(SOUNDKIT.IG_CREATURE_AGGRO_SELECT) end
  elseif Safe(UnitIsFriend("target", "player")) then
    if SOUNDKIT.IG_CHARACTER_NPC_SELECT then PlaySound(SOUNDKIT.IG_CHARACTER_NPC_SELECT) end
  elseif SOUNDKIT.IG_CREATURE_NEUTRAL_SELECT then
    PlaySound(SOUNDKIT.IG_CREATURE_NEUTRAL_SELECT)
  end
end

local HANDLERS = {
  UNIT_HEALTH = "UpdateHealth", UNIT_MAXHEALTH = "UpdateHealth",
  UNIT_POWER_UPDATE = "UpdatePower", UNIT_POWER_FREQUENT = "UpdatePower", UNIT_MAXPOWER = "UpdatePower",
  UNIT_DISPLAYPOWER = "UpdatePower", UNIT_NAME_UPDATE = "UpdateName", UNIT_LEVEL = "UpdateLevel",
  UNIT_FACTION = "UpdateColor", UNIT_CLASSIFICATION_CHANGED = "UpdateTag", UNIT_FLAGS = "UpdateTag",
}

local function OnEvent(_, event, unit)
  local method = HANDLERS[event]
  if method then
    local f = U.byUnit[unit]
    if f then
      U[method](U, f)
      if event == "UNIT_FACTION" then
        U:UpdateName(f)
        U:UpdateTag(f)
      elseif event == "UNIT_CLASSIFICATION_CHANGED" then
        U:UpdateElite(f)
      end
    end
    if unit == "player" and (event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER") then U:UpdatePips() end
  elseif event == "UNIT_PORTRAIT_UPDATE" or event == "UNIT_MODEL_CHANGED" then
    local f = U.byUnit[unit]
    if f then U:UpdatePortrait(f, true) end
  elseif event == "PLAYER_TARGET_CHANGED" then
    TargetChanged()
  elseif event == "UNIT_TARGET" then
    if unit == "target" then U:Update(U.frames.tot) end
  elseif event == "UNIT_AURA" then
    if unit == "target" then U:UpdateAuras() end
  elseif event == "UNIT_PET" then
    if unit == "player" then U:Update(U.frames.pet) end
  elseif event == "RAID_TARGET_UPDATE" then
    U:UpdateRaidIcon(U.frames.player)
    U:UpdateRaidIcon(U.frames.target)
  elseif event == "PLAYER_REGEN_DISABLED" then
    if U.unlocked then
      FUI:SetUnlocked(false)
      FUI:Print("edit mode closed: you're in combat.")
    end
    U:UpdateTag(U.frames.player)
  elseif event == "PLAYER_REGEN_ENABLED" then
    if U.totemsPending then U:AnchorTotems() end
    U:UpdateTag(U.frames.player)
  elseif event == "PLAYER_UPDATE_RESTING" or event == "PLAYER_FLAGS_CHANGED"
    or event == "PARTY_LEADER_CHANGED" or event == "GROUP_ROSTER_UPDATE" then
    U:UpdateTag(U.frames.player)
    U:UpdateTag(U.frames.target)
  elseif event == "PLAYER_ENTERING_WORLD" then
    U:UpdateAll()
  end
end

function U:Events()
  local ev = CreateFrame("Frame")
  for e in pairs(HANDLERS) do ev:RegisterEvent(e) end
  for _, e in ipairs({
    "PLAYER_TARGET_CHANGED", "UNIT_TARGET", "UNIT_AURA", "UNIT_PET", "RAID_TARGET_UPDATE",
    "UNIT_PORTRAIT_UPDATE", "UNIT_MODEL_CHANGED",
    "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_UPDATE_RESTING", "PLAYER_FLAGS_CHANGED",
    "PARTY_LEADER_CHANGED", "GROUP_ROSTER_UPDATE", "PLAYER_ENTERING_WORLD",
  }) do
    ev:RegisterEvent(e)
  end
  ev:SetScript("OnEvent", OnEvent)
end

------------------------------------------------------------------------
-- Edit mode and settings
------------------------------------------------------------------------

-- In edit mode the target, target-of-target and pet frames stay up, showing you, so they can be placed.
function U:SetUnlocked(on)
  on = on or nil
  if not self.started or self.unlocked == on then return end
  self.unlocked = on
  if not on then self.previewClass = nil end
  local previews = { self.frames.target, self.frames.tot, self.frames.pet }
  for _, f in ipairs(previews) do
    if on then
      UnregisterUnitWatch(f)
      f.unit = "player"
      f:Show()
      self:Update(f)
    else
      f.unit = f.realUnit
      RegisterUnitWatch(f)
      self:Update(f)
    end
  end
  for _, f in pairs(self.frames) do f.mover:SetShown(on) end
  self:UpdateAuras()
end

function U:Refresh()
  if not self.started then return end
  for _, f in pairs(self.frames) do S.Panel(f) end
  if self.targetBar then S.Panel(self.targetBar) end
  self:UpdateAll()
end

function U:Slash(arg)
  local cmd, rest = (arg or ""):match("^(%S*)%s*(.-)$")
  local n = tonumber(rest)
  local db = ns.db
  if not self.started then
    FUI:Print("The unit frames are off. /kui frames on, then /reload.")
  elseif cmd == "unlock" or cmd == "lock" then
    FUI:SetUnlocked(cmd == "unlock")
  elseif InCombatLockdown() and (cmd == "scale" or cmd == "reset") then
    FUI:Print("That can't change in combat.")
  elseif cmd == "scale" and n then
    db.frameScale = math.max(0.5, math.min(2, n))
    for _, key in ipairs(FRAME_KEYS) do self:Cfg(key).scale = db.frameScale end
    self:LayoutAll()
    FUI:Print("unit frame scale %.2f", db.frameScale)
  elseif cmd == "class" then
    db.classColor = not db.classColor
    for _, key in ipairs(FRAME_KEYS) do self:Cfg(key).classColor = db.classColor end
    self:UpdateAll()
    FUI:Print("class colours on player health: %s", db.classColor and "on" or "off")
  elseif cmd == "reset" then
    db.classColor, db.frameScale = FUI.defaults.classColor, FUI.defaults.frameScale
    for _, key in ipairs(FRAME_KEYS) do self:ResetFrame(key) end
    FUI:Print("unit frames back to their default spots and settings.")
  else
    FUI:Print("/kui edit opens the edit mode. Also /kui frames scale 0.5-2 · class · reset · on|off")
  end
end

function U:Start()
  if self.started then return end
  self.started = true
  self:Build()
  self:HideBlizzard()
  self:Events()
  self:UpdateAll()
end

-- Secure frames can't be made or moved in combat. A /reload in combat waits until it ends.
function U:Enable()
  self.enabled = true
  if not InCombatLockdown() then return self:Start() end
  local wait = CreateFrame("Frame")
  wait:RegisterEvent("PLAYER_REGEN_ENABLED")
  wait:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    U:Start()
  end)
end

FUI:Register(U)
