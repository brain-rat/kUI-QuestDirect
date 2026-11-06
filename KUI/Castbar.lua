-- kUI · Castbar
-- A flat cast bar in the shared style: spell icon, name, time left and a thin
-- spark. Casts are sky blue, channels green, spells you can't interrupt grey,
-- and a failed or interrupted cast flashes red.
--
-- Make() builds a bar for any unit. This module owns the player's bar, which
-- you can move, and UnitFrames.lua uses Make() for the bar on the target frame.
-- Sizes and parts come from the settings, so the edit mode can change them live.
--
-- Where the game gives plain start and end times, the bar runs on those. Where
-- they are secret it hands the game's own duration object to the bar instead.

local _, ns = ...
local FUI, S = ns.FUI, ns.Style

local C = { key = "castbar", name = "Castbar", bars = {} }
ns.Castbar = C

local CHANNEL = { 0.45, 0.85, 0.55 }
local LOCKED = { 0.55, 0.58, 0.63 } -- can't be interrupted
local FAILED = { 0.85, 0.25, 0.2 }
local DONE_FADE, FAIL_HOLD, FADE = 0.25, 0.5, 0.3
local floor = math.floor
local Present = S.Present

-- Colour by "can't be interrupted", which can itself be secret.
local function Paint(f, flag, base)
  if S.IsSecret(flag) then
    local pick = C_CurveUtil and C_CurveUtil.EvaluateColorValueFromBoolean
    if pick then
      S.BarColor(f.bar, pick(flag, LOCKED[1], base[1]), pick(flag, LOCKED[2], base[2]), pick(flag, LOCKED[3], base[3]))
      return
    end
    flag = false
  end
  local c = flag and LOCKED or base
  S.BarColor(f.bar, c[1], c[2], c[3])
end

-- Nothing left to show. A bar stays up while the edit mode is open.
local function Clear(f)
  f.mode, f.timed, f.dur, f.guid = nil, nil, nil, nil
  f:SetScript("OnUpdate", nil)
  f:SetAlpha(1)
  if f.preview then
    f.bar:SetMinMaxValues(0, 1)
    f.bar:SetValue(1)
    S.BarColor(f.bar, S.ACCENT[1], S.ACCENT[2], S.ACCENT[3])
    f.label:SetText("Cast bar")
    f.time:SetText("1.5")
    f.icon:SetTexture("Interface\\Icons\\Spell_Nature_Lightning")
    f:Show()
  else
    f:Hide()
  end
end

local function Fading(f, dt)
  f.hold = f.hold - dt
  if f.hold > 0 then return end
  f.fade = f.fade - dt
  if f.fade <= 0 then return Clear(f) end
  f:SetAlpha(f.fade / f.fadeTotal)
end

-- End the bar: full, then fade. `failText` makes it the red failed version.
local function Finish(f, failText, hold, fade)
  f.timed, f.dur, f.guid = nil, nil, nil
  f.mode = "fade"
  f.bar:SetMinMaxValues(0, 1)
  f.bar:SetValue(1)
  f.time:SetText("")
  if failText then
    S.BarColor(f.bar, FAILED[1], FAILED[2], FAILED[3])
    f.label:SetText(failText)
  end
  f.hold, f.fade, f.fadeTotal = hold, fade, fade
  f:SetAlpha(1)
  f:SetScript("OnUpdate", Fading)
  f:Show()
end

local function Running(f)
  if f.timed then
    local now = GetTime()
    local left = f.endT - now
    if left <= 0 then
      -- The game's stop event normally ends it. This covers the sample bar and a lost event.
      if f.sample or left < -1 then return Finish(f, nil, 0, DONE_FADE) end
      left = 0
    end
    if f.mode == "channel" then
      f.bar:SetValue(left)
    else
      f.bar:SetValue(f.total - left)
    end
    f.time:SetFormattedText("%.1f", left)
  elseif f.dur then
    local ok = pcall(function() f.time:SetFormattedText("%.1f", f.dur:GetRemainingDuration()) end)
    if not ok then f.dur = nil end
  end
end

local function HasText(v)
  if S.IsSecret(v) then return true end
  return v ~= nil and v ~= ""
end

-- Some spells carry a note from the game's designers in their name, like the
-- "Opening - No Text" you get from a water barrel. A secret can't be read, so it's
-- passed on as it is.
local function Clean(text)
  if S.IsSecret(text) then return text end
  local short = text:gsub("%s*%-%s*No Text$", "")
  return short ~= "" and short or text
end

-- What to show on the bar. The game's display name comes first, as on its own bar:
-- some casts, like opening a chest, may not have a usable plain name.
local function CastText(display, name, spellID, channel)
  if HasText(display) then return Clean(display) end
  if HasText(name) then return Clean(name) end
  local id = S.Safe(spellID)
  local spell = id and C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id)
  if HasText(spell) then return Clean(spell) end
  return channel and "Channelling" or "Casting"
end

-- Read the unit's cast or channel from the game. False if there isn't one.
function C:Read(f)
  local u = f.unit
  local name, display, tex, st, en, _, guid, locked, spellID = UnitCastingInfo(u)
  local channel = false
  if not (Present(name) or Present(display)) then
    name, display, tex, st, en, _, locked, spellID = UnitChannelInfo(u)
    guid, channel = nil, true
    if not (Present(name) or Present(display)) then return false end
  end
  f.sample = nil
  f.mode = channel and "channel" or "cast"
  f.guid = S.Safe(guid)
  f.label:SetText(CastText(display, name, spellID, channel))
  f.icon:SetTexture(tex)
  Paint(f, locked, channel and CHANNEL or S.ACCENT)
  local s, e = S.Safe(st), S.Safe(en)
  if s and e then
    f.timed, f.dur = true, nil
    f.endT = e / 1000
    f.total = math.max((e - s) / 1000, 0.001)
    f.bar:SetMinMaxValues(0, f.total)
  else
    f.timed = nil
    local d
    if channel then
      d = UnitChannelDuration and UnitChannelDuration(u)
    else
      d = UnitCastingDuration and UnitCastingDuration(u)
    end
    f.dur = d
    if d and f.bar.SetTimerDuration then
      local dirs = Enum and Enum.StatusBarTimerDirection
      f.bar:SetTimerDuration(d, nil, dirs and (channel and dirs.RemainingTime or dirs.ElapsedTime))
    end
    f.time:SetText("")
  end
  f:SetAlpha(1)
  f:SetScript("OnUpdate", Running)
  f:Show()
  Running(f)
  return true
end

local function SameCast(f, guid)
  local g = S.Safe(guid)
  return not (f.guid and g and g ~= f.guid)
end

local function OnEvent(f, event, unit, guid)
  if f.off then return end
  if event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
    if not C:Read(f) then Clear(f) end
    return
  end
  if unit ~= f.unit then return end
  if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START"
    or event == "UNIT_SPELLCAST_DELAYED" or event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
    C:Read(f)
  elseif event == "UNIT_SPELLCAST_STOP" then
    if f.mode == "cast" and SameCast(f, guid) then Finish(f, nil, 0, DONE_FADE) end
  elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
    if f.mode == "channel" then Finish(f, nil, 0, DONE_FADE) end
  elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
    if (f.mode == "cast" or f.mode == "channel") and SameCast(f, guid) then
      Finish(f, "Interrupted", FAIL_HOLD, FADE)
    end
  elseif event == "UNIT_SPELLCAST_FAILED" then
    -- Pressing a spell mid-cast or mid-channel fails too; that doesn't end this one.
    if f.mode == "cast" and SameCast(f, guid) then Finish(f, "Failed", FAIL_HOLD, FADE) end
  end
end

local EVENTS = {
  "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED",
  "UNIT_SPELLCAST_DELAYED", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_UPDATE",
  "UNIT_SPELLCAST_CHANNEL_STOP", "PLAYER_ENTERING_WORLD",
}

function C:Make(name, unit, parent)
  local f = CreateFrame("Frame", name, parent)
  f.unit = unit
  f:Hide()
  S.Panel(f)
  f.icon = f:CreateTexture(nil, "ARTWORK")
  f.icon:SetPoint("TOPLEFT", 1, -1)
  f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  f.bar = S.Bar(f)
  local fill = f.bar:GetStatusBarTexture()
  f.spark = S.Tex(f.bar, "OVERLAY", 1)
  f.spark:SetWidth(2)
  f.spark:SetColorTexture(1, 1, 1, 0.8)
  f.spark:SetPoint("TOP", fill, "TOPRIGHT")
  f.spark:SetPoint("BOTTOM", fill, "BOTTOMRIGHT")
  f.time = S.Text(f.bar, "GameFontHighlightSmall", "RIGHT", "OVERLAY", 12, "OUTLINE")
  f.time:SetDrawLayer("OVERLAY", 2)
  f.time:SetPoint("RIGHT", -4, 0)
  f.label = S.Text(f.bar, "GameFontHighlightSmall", nil, "OVERLAY", 12, "OUTLINE")
  f.label:SetDrawLayer("OVERLAY", 2)
  for _, e in ipairs(EVENTS) do f:RegisterEvent(e) end
  if unit == "target" then f:RegisterEvent("PLAYER_TARGET_CHANGED") end
  f:SetScript("OnEvent", OnEvent)
  table.insert(self.bars, f)
  return f
end

-- Size and parts of one bar. width nil: something else sets it (the target frame).
function C:Apply(f, width, height, size)
  local db = ns.db
  f:SetHeight(height)
  if width then f:SetWidth(width) end
  local icon = height - 2
  f.icon:SetSize(icon, icon)
  f.icon:SetShown(db.castIcon)
  f.bar:ClearAllPoints()
  if db.castIcon then
    f.bar:SetPoint("TOPLEFT", f.icon, "TOPRIGHT", 1, 0)
  else
    f.bar:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
  end
  f.bar:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
  f.spark:SetShown(db.castSpark)
  f.time:SetShown(db.castTime)
  S.SetFont(f.time, size, "OUTLINE")
  S.SetFont(f.label, size, "OUTLINE")
  f.label:ClearAllPoints()
  f.label:SetPoint("LEFT", f.bar, "LEFT", 4, 0)
  if db.castTime then
    f.label:SetPoint("RIGHT", f.time, "LEFT", -4, 0)
  else
    f.label:SetPoint("RIGHT", f.bar, "RIGHT", -4, 0)
  end
end

function C:LayoutAll()
  local db = ns.db
  if self.player then self:Apply(self.player, db.castWidth, db.castHeight, db.castSize) end
  if self.target then
    self:Apply(self.target, nil, db.targetCastH, math.max(8, math.min(db.castSize, db.targetCastH - 6)))
  end
  if self.player then self:Place() end
end

-- The bar on the target frame can be switched off and on while playing.
function C:SetTargetBar(on)
  local f = self.target
  if not f then return end
  f.off = not on or nil
  f.preview = (on and FUI.unlocked) and true or nil
  if f.off then
    Clear(f)
  elseif not self:Read(f) then
    Clear(f)
  end
end

-- A sample cast, to see the look without casting anything.
function C:Sample(f)
  if f.off then return end
  f.sample, f.timed, f.dur, f.guid = true, true, nil, nil
  f.mode = "cast"
  f.total = 3
  f.endT = GetTime() + 3
  f.bar:SetMinMaxValues(0, 3)
  f.bar:SetValue(0)
  f.label:SetText("Sample cast")
  f.icon:SetTexture("Interface\\Icons\\Spell_Nature_Lightning")
  S.BarColor(f.bar, S.ACCENT[1], S.ACCENT[2], S.ACCENT[3])
  f:SetAlpha(1)
  f:SetScript("OnUpdate", Running)
  f:Show()
end

function C:Place()
  local f = self.player
  f:ClearAllPoints()
  f:SetScale(ns.db.castScale)
  if ns.db.castLeft then
    f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", ns.db.castLeft, ns.db.castTop)
  else
    f:SetPoint("CENTER", UIParent, "BOTTOM", 0, floor(UIParent:GetHeight() * 0.258))
  end
end

-- Blizzard's own player bar stops listening and goes out of sight.
function C:HideBlizzard()
  if InCombatLockdown() then
    self.hidePending = true
    return
  end
  self.hidePending = nil
  for _, b in ipairs({ _G.PlayerCastingBarFrame, _G.CastingBarFrame }) do
    if type(b) == "table" then
      pcall(b.SetUnit, b, nil)
      pcall(b.UnregisterAllEvents, b)
      pcall(b.Hide, b)
      pcall(b.SetParent, b, S.HiddenParent())
    end
  end
end

function C:SetUnlocked(on)
  for _, f in ipairs(self.bars) do
    f.preview = (on and not f.off) and true or nil
    if f.mover then f.mover:SetShown(on) end
    if not f.mode then Clear(f) end
  end
end

-- The settings the edit mode's Castbar tab changes, back to their defaults.
function C:Reset()
  local db, d = ns.db, FUI.defaults
  for _, k in ipairs({ "castWidth", "castHeight", "castSize", "castIcon", "castTime", "castSpark", "castScale" }) do
    db[k] = d[k]
  end
  db.castLeft, db.castTop = nil, nil
  self:LayoutAll()
end

function C:Refresh()
  for _, f in ipairs(self.bars) do S.Panel(f) end
end

function C:Slash(arg)
  local cmd, rest = (arg or ""):match("^(%S*)%s*(.-)$")
  local n = tonumber(rest)
  local db = ns.db
  if cmd == "test" then
    if self.player then self:Sample(self.player) end
    if self.target then self:Sample(self.target) end
  elseif cmd == "unlock" or cmd == "lock" then
    FUI:SetUnlocked(cmd == "unlock")
  elseif cmd == "scale" and n then
    db.castScale = math.max(0.5, math.min(2, n))
    if self.player then self:Place() end
    FUI:Print("castbar scale %.2f", db.castScale)
  elseif cmd == "target" then
    db.targetCast = not db.targetCast
    self:SetTargetBar(db.targetCast)
    FUI:Print("cast bar on the target frame: %s", db.targetCast and "on" or "off")
  elseif cmd == "reset" then
    self:Reset()
    FUI:Print("castbar back in its default spot and size.")
  else
    FUI:Print("/kui castbar test · scale 0.5-2 · target · reset · on|off. /kui edit for everything else.")
  end
end

function C:Enable()
  self.enabled = true
  local f = self:Make("KUICastbar", "player", UIParent)
  f:SetClampedToScreen(true)
  f.mover = S.Mover(f, "Castbar", function(left, top)
    ns.db.castLeft, ns.db.castTop = left, top
  end)
  self.player = f
  self:LayoutAll()
  self:HideBlizzard()
  local ev = CreateFrame("Frame")
  ev:RegisterEvent("PLAYER_REGEN_ENABLED")
  ev:SetScript("OnEvent", function()
    if C.hidePending then C:HideBlizzard() end
  end)
end

FUI:Register(C)
