-- kUI · Style
-- The shared look: QuestDirect's flat dark panels, thin blue-grey borders, faint
-- highlights, and the rarity outline + inner glow used on items. Every module
-- builds from these so the whole UI stays consistent.

local _, ns = ...
local S = {}
ns.Style = S

S.WHITE = "Interface\\Buttons\\WHITE8X8"
S.BG = { 0.04, 0.05, 0.07 }
S.EDGE = { 0.35, 0.4, 0.5 }
S.ACCENT = { 0.5, 0.78, 1 }
S.LABEL = { 0.75, 0.75, 0.75 }
S.HEADER_H = 24

local max, min, floor = math.max, math.min, math.floor

-- Secret values can be handed to widgets (bars, text, textures) but not compared,
-- added up or formatted in Lua. Safe() gives nil for a secret, so a check just fails.
function S.IsSecret(v) return issecretvalue ~= nil and issecretvalue(v) == true end
function S.Safe(v)
  if S.IsSecret(v) then return nil end
  return v
end
function S.Present(v)
  if S.IsSecret(v) then return true end -- a secret is always a real value
  return v ~= nil
end

-- A hidden parent for Blizzard frames that kUI replaces.
function S.HiddenParent()
  if not S.hidden then
    S.hidden = CreateFrame("Frame")
    S.hidden:Hide()
  end
  return S.hidden
end

function S.Tex(parent, layer, sub)
  local t = parent:CreateTexture(nil, layer, nil, sub)
  if t.SetSnapToPixelGrid then t:SetSnapToPixelGrid(false) end
  if t.SetTexelSnappingBias then t:SetTexelSnappingBias(0) end
  return t
end

------------------------------------------------------------------------
-- Fonts: four bundled (SIL Open Font Licence), the game's own, and any
-- LibSharedMedia fonts other add-ons register.
------------------------------------------------------------------------

local FONT_DIR = "Interface\\AddOns\\KUI\\Fonts\\"
S.FONTS = {
  { key = "barlow", name = "Barlow", path = FONT_DIR .. "Barlow-SemiBold.ttf" },
  { key = "barlowcondensed", name = "Barlow Condensed", path = FONT_DIR .. "BarlowCondensed-SemiBold.ttf" },
  { key = "rajdhani", name = "Rajdhani", path = FONT_DIR .. "Rajdhani-SemiBold.ttf" },
  { key = "chakra", name = "Chakra Petch", path = FONT_DIR .. "ChakraPetch-SemiBold.ttf" },
  { key = "friz", name = "Friz Quadrata (game)", path = "Fonts\\FRIZQT__.TTF" },
  { key = "arial", name = "Arial Narrow (game)", path = "Fonts\\ARIALN.TTF" },
  { key = "skurri", name = "Skurri (game)", path = "Fonts\\skurri.ttf" },
  { key = "morpheus", name = "Morpheus (game)", path = "Fonts\\MORPHEUS.TTF" },
}
S.OUTLINES = { { key = "", name = "None" }, { key = "OUTLINE", name = "Outline" }, { key = "THICKOUTLINE", name = "Thick" } }

function S.LoadSharedFonts()
  local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
  if not LSM then return end
  local have = {}
  for _, f in ipairs(S.FONTS) do have[f.key] = true end
  for _, name in ipairs(LSM:List("font") or {}) do
    local key = "lsm:" .. name
    if not have[key] then
      table.insert(S.FONTS, { key = key, name = name, path = LSM:Fetch("font", name) })
    end
  end
end

function S.Font(key)
  key = key or (ns.db and ns.db.font)
  for _, f in ipairs(S.FONTS) do
    if f.key == key then return f end
  end
  return S.FONTS[1]
end

local registered = {}
local fixed = {}
local FIXED_FONT = FONT_DIR .. "Barlow-SemiBold.ttf"

local function SetFixed(fs, size, flags)
  local ok = pcall(fs.SetFont, fs, FIXED_FONT, size, flags or "")
  if not ok or (fs.GetFont and not fs:GetFont()) then
    pcall(fs.SetFont, fs, "Fonts\\FRIZQT__.TTF", size, flags or "")
  end
end

-- Settings windows stay in one font, whatever font the rest of kUI is set to.
function S.FixFont(fs, size, flags)
  registered[fs] = nil
  fixed[fs] = true
  SetFixed(fs, size, flags)
end

-- Set a font string to the kUI font at this size (and outline flags).
function S.SetFont(fs, size, flags)
  if fixed[fs] then return SetFixed(fs, size, flags) end
  registered[fs] = { size, flags }
  local f = S.Font()
  local ok = pcall(fs.SetFont, fs, f.path, size, flags or "")
  if not ok or (fs.GetFont and not fs:GetFont()) then
    pcall(fs.SetFont, fs, "Fonts\\FRIZQT__.TTF", size, flags or "")
  end
end

-- Re-apply after the font setting changes. WoW doesn't always redraw text that
-- isn't set again after its font changes, so each text is set again too.
function S.ApplyFonts()
  for fs, v in pairs(registered) do
    S.SetFont(fs, v[1], v[2])
    if fs.GetObjectType and fs:GetObjectType() == "FontString" and fs.GetText then
      local t = fs:GetText()
      if S.IsSecret(t) then
        fs:SetText(t) -- a secret can't be compared, only passed back
      elseif t and t ~= "" then
        fs:SetText(" ")
        fs:SetText(t)
      end
    end
  end
end

-- size: use the kUI font at this size; otherwise the template's font.
function S.Text(parent, template, justify, layer, size, flags)
  local fs = parent:CreateFontString(nil, layer or "OVERLAY", template or "GameFontHighlightSmall")
  fs:SetJustifyH(justify or "LEFT")
  fs:SetWordWrap(false)
  if size then S.SetFont(fs, size, flags) end
  return fs
end

-- Text for settings windows: never follows the font setting.
function S.UIText(parent, template, justify, layer, size, flags)
  local fs = S.Text(parent, template, justify, layer)
  S.FixFont(fs, size or 12, flags)
  return fs
end

-- 1px border of four lines around `anchor` (outset pushes it outside).
function S.Edges(parent, layer, sub, anchor, outset)
  anchor, outset = anchor or parent, outset or 0
  local o = outset
  local e = {}
  for i = 1, 4 do e[i] = S.Tex(parent, layer, sub) end
  e[1]:SetPoint("TOPLEFT", anchor, "TOPLEFT", -o, o); e[1]:SetPoint("TOPRIGHT", anchor, "TOPRIGHT", o, o); e[1]:SetHeight(1)
  e[2]:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", -o, -o); e[2]:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", o, -o); e[2]:SetHeight(1)
  e[3]:SetPoint("TOPLEFT", anchor, "TOPLEFT", -o, o); e[3]:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", -o, -o); e[3]:SetWidth(1)
  e[4]:SetPoint("TOPRIGHT", anchor, "TOPRIGHT", o, o); e[4]:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", o, -o); e[4]:SetWidth(1)
  return e
end

function S.ColorEdges(e, r, g, b, a)
  for i = 1, 4 do
    e[i]:SetColorTexture(r, g, b, a)
    e[i]:Show()
  end
end

-- QuestDirect's window: flat fill + border. Returns the panel parts.
function S.Panel(f, alpha)
  local p = f.fuiPanel
  if not p then
    p = { fill = S.Tex(f, "BACKGROUND", -8) }
    p.fill:SetAllPoints()
    p.edges = S.Edges(f, "BACKGROUND", -7)
    f.fuiPanel = p
  end
  alpha = alpha or ns.db.alpha
  p.fill:SetColorTexture(S.BG[1], S.BG[2], S.BG[3], alpha)
  S.ColorEdges(p.edges, S.EDGE[1], S.EDGE[2], S.EDGE[3], min(1, alpha + 0.2))
  return p
end

-- Faint title strip across the top.
function S.Header(f, h)
  local t = S.Tex(f, "BACKGROUND", -6)
  t:SetPoint("TOPLEFT", 1, -1)
  t:SetPoint("TOPRIGHT", -1, -1)
  t:SetHeight((h or S.HEADER_H) - 1)
  t:SetColorTexture(1, 1, 1, 0.06)
  return t
end

function S.Highlight(f, a)
  local hl = S.Tex(f, "HIGHLIGHT")
  hl:SetAllPoints()
  hl:SetColorTexture(1, 1, 1, a or 0.12)
  return hl
end

-- QuestDirect's flat text button.
function S.Button(parent, label, width, onClick, tip)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(width, 18)
  b.text = S.Text(b, "GameFontHighlightSmall", "CENTER", nil, 12)
  b.text:SetAllPoints()
  b.text:SetText(label)
  S.Highlight(b)
  b:SetScript("OnClick", onClick)
  if tip then
    b:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
      GameTooltip:SetText(tip, 1, 1, 1, 1, true)
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  end
  return b
end

-- The same button for settings windows.
function S.UIButton(parent, label, width, onClick, tip)
  local b = S.Button(parent, label, width, onClick, tip)
  S.FixFont(b.text, 12)
  return b
end

-- Flat status bar with a faint track behind it.
function S.Bar(parent)
  local b = CreateFrame("StatusBar", nil, parent)
  b:SetStatusBarTexture(S.WHITE)
  b:SetMinMaxValues(0, 1)
  b:SetValue(0)
  b.bg = S.Tex(b, "BACKGROUND", -8)
  b.bg:SetAllPoints()
  b.bg:SetColorTexture(1, 1, 1, 0.07)
  return b
end

-- Colours the fill directly, because these numbers can be secret.
function S.BarColor(bar, r, g, b)
  bar:GetStatusBarTexture():SetVertexColor(r, g, b)
end

-- Drag overlay shown while frames are unlocked. onStop(left, top) saves the spot.
function S.Mover(f, label, onStop)
  local m = CreateFrame("Frame", nil, f)
  m:SetAllPoints(f)
  m:SetFrameLevel(f:GetFrameLevel() + 20)
  m:EnableMouse(true)
  m:RegisterForDrag("LeftButton")
  local fill = S.Tex(m, "OVERLAY", 5)
  fill:SetAllPoints()
  fill:SetColorTexture(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.25)
  m.fill = fill
  S.ColorEdges(S.Edges(m, "OVERLAY", 6), S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 1)
  m.label = S.UIText(m, "GameFontHighlightSmall", "CENTER", "OVERLAY", 12, "OUTLINE")
  m.label:SetDrawLayer("OVERLAY", 7)
  m.label:SetPoint("CENTER")
  m.label:SetText(label)
  m:SetScript("OnDragStart", function()
    if InCombatLockdown() then return end
    f:SetMovable(true)
    f:StartMoving()
  end)
  m:SetScript("OnDragStop", function()
    f:StopMovingOrSizing()
    if f.SetUserPlaced then f:SetUserPlaced(false) end
    onStop(floor(f:GetLeft() + 0.5), floor(f:GetTop() + 0.5))
  end)
  m:Hide()
  return m
end

------------------------------------------------------------------------
-- Rarity outline + inner glow
------------------------------------------------------------------------

function S.QualityRGB(q)
  if type(q) ~= "number" or (issecretvalue and issecretvalue(q)) then return nil end
  if q == 1 and not ns.db.common then return nil end
  local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
  if c then return c.r, c.g, c.b end
  if C_Item and C_Item.GetItemQualityColor then return C_Item.GetItemQualityColor(q) end
end

local function Gradient(t, orientation, r, g, b, a1, a2)
  if t.SetGradient and CreateColor then
    t:SetGradient(orientation, CreateColor(r, g, b, a1), CreateColor(r, g, b, a2))
  elseif t.SetGradientAlpha then
    t:SetGradientAlpha(orientation, r, g, b, a1, r, g, b, a2)
  end
end

-- Adds the outline and glow textures over `icon` on frame `f`. Returns a glow object.
function S.Glow(f, icon, size)
  local g = { edges = S.Edges(f, "OVERLAY", 6, icon), glow = {} }
  for i = 1, 4 do
    local t = S.Tex(f, "OVERLAY", 5)
    t:SetTexture(S.WHITE)
    t:SetBlendMode("ADD")
    g.glow[i] = t
  end
  local w = g.glow
  w[1]:SetPoint("TOPLEFT", icon); w[1]:SetPoint("TOPRIGHT", icon)
  w[2]:SetPoint("BOTTOMLEFT", icon); w[2]:SetPoint("BOTTOMRIGHT", icon)
  w[3]:SetPoint("TOPLEFT", icon); w[3]:SetPoint("BOTTOMLEFT", icon)
  w[4]:SetPoint("TOPRIGHT", icon); w[4]:SetPoint("BOTTOMRIGHT", icon)
  S.GlowSize(g, size)
  return g
end

function S.GlowSize(g, size)
  local w = g.glow
  local d = max(4, floor((size or 30) * 0.34 + 0.5))
  w[1]:SetHeight(d); w[2]:SetHeight(d); w[3]:SetWidth(d); w[4]:SetWidth(d)
end

-- Outline and glow in any colour. a = 0 leaves just the outline.
function S.GlowRGB(g, r, gg, b, a)
  S.ColorEdges(g.edges, r, gg, b, 1)
  Gradient(g.glow[1], "VERTICAL", r, gg, b, 0, a)
  Gradient(g.glow[2], "VERTICAL", r, gg, b, a, 0)
  Gradient(g.glow[3], "HORIZONTAL", r, gg, b, a, 0)
  Gradient(g.glow[4], "HORIZONTAL", r, gg, b, 0, a)
  for i = 1, 4 do g.glow[i]:SetShown(a > 0) end
end

function S.GlowOff(g)
  for i = 1, 4 do
    g.edges[i]:Hide()
    g.glow[i]:Hide()
  end
end

function S.PaintGlow(g, q)
  local r, gg, b = S.QualityRGB(q)
  if r then
    S.GlowRGB(g, r, gg, b, ns.db.glow * (q == 0 and 0.6 or 1))
  else
    S.ColorEdges(g.edges, S.EDGE[1], S.EDGE[2], S.EDGE[3], 0.5)
    for i = 1, 4 do g.glow[i]:Hide() end
  end
end

-- Hide something for good, even if the game shows it again (not for protected frames).
function S.Kill(obj)
  if type(obj) ~= "table" then return end
  if obj.Hide then obj:Hide() end
  if obj.SetAlpha then obj:SetAlpha(0) end
  if obj.fuiKilled or not obj.Show then return end
  obj.fuiKilled = true
  hooksecurefunc(obj, "Show", function(self) if ns.db and ns.killing then self:Hide() end end)
end
