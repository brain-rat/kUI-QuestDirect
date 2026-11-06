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

-- Set a font string to the kUI font at this size (and outline flags).
function S.SetFont(fs, size, flags)
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
      if t and t ~= "" then
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

function S.PaintGlow(g, q)
  local r, gg, b = S.QualityRGB(q)
  if r then
    S.ColorEdges(g.edges, r, gg, b, 1)
    local a = ns.db.glow * (q == 0 and 0.6 or 1)
    Gradient(g.glow[1], "VERTICAL", r, gg, b, 0, a)
    Gradient(g.glow[2], "VERTICAL", r, gg, b, a, 0)
    Gradient(g.glow[3], "HORIZONTAL", r, gg, b, a, 0)
    Gradient(g.glow[4], "HORIZONTAL", r, gg, b, 0, a)
    for i = 1, 4 do g.glow[i]:SetShown(a > 0) end
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
