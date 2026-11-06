-- kUI · Edit mode
-- /kui edit, or the minimap icon: every unit frame and the castbar get a drag
-- overlay, and a settings window opens with a tab for each. Click a frame to jump
-- to its tab. Changes apply as you make them and are saved straight away. Done, Esc
-- or entering combat closes it, because secure frames can't be resized in combat.

local _, ns = ...
local FUI, S = ns.FUI, ns.Style

local E = { pages = {}, tabs = {}, rows = {} }
ns.EditMode = E

local COL_W, GAP, HEAD, TAB_H, FOOT = 272, 8, 28, 26, 38
local WIDTH = COL_W * 2 + GAP * 3
local floor, max = math.floor, math.max
local A = S.ACCENT

local NAME_MODES = { { key = "full", name = "Full" }, { key = "first", name = "First" }, { key = "off", name = "Hidden" } }
local PORTRAITS = { { key = "off", name = "Off" }, { key = "2d", name = "Flat" }, { key = "3d", name = "3D" } }
local SIDES = { { key = "left", name = "Left" }, { key = "right", name = "Right" } }
local ELITE = { { key = "off", name = "Off" }, { key = "border", name = "Border" }, { key = "glow", name = "Glow" } }
local PREVIEW = {
  { key = false, name = "Normal" }, { key = "elite", name = "Elite" }, { key = "rare", name = "Rare" },
  { key = "rareelite", name = "R. Elite" }, { key = "worldboss", name = "Boss" },
}

-- store: "db" for a kUI-wide setting, "preview" for the elite preview, otherwise
-- it belongs to the frame on this tab.
local function Global()
  return {
    title = "All of kUI",
    { kind = "cycle", stepper = true, label = "Font", key = "font", store = "db", list = function() return S.FONTS end },
    { kind = "step", label = "Panel opacity", key = "alpha", store = "db", min = 0, max = 1, step = 0.05, fmt = "%.2f" },
  }
end

local function FrameSections(tab)
  local function on(key) return function() return ns.UnitFrames:Cfg(tab)[key] end end
  local function portraitOn() return ns.UnitFrames:Cfg(tab).portrait ~= "off" end
  local function nameOn() return ns.UnitFrames:Cfg(tab).name ~= "off" end
  local sections = {
    {
      title = "Size",
      { kind = "step", label = "Width", key = "width", min = 80, max = 500, step = 5 },
      { kind = "step", label = "Health bar height", key = "hpHeight", min = 4, max = 60, step = 1 },
      { kind = "step", label = "Scale", key = "scale", min = 0.5, max = 2, step = 0.05, fmt = "%.2f" },
    },
    {
      title = "Name and header",
      { kind = "cycle", label = "Name", key = "name", list = NAME_MODES },
      { kind = "step", label = "Name font size", key = "nameSize", min = 8, max = 28, step = 1, when = nameOn },
      { kind = "toggle", label = "Level", key = "level" },
      { kind = "toggle", label = "Status tags and raid marker", key = "tags" },
    },
    {
      title = "Health",
      { kind = "toggle", label = "Numbers", key = "hpText" },
      { kind = "toggle", label = "Percent", key = "hpPct" },
      { kind = "step", label = "Font size", key = "barSize", min = 8, max = 28, step = 1 },
      { kind = "toggle", label = "Class colours", key = "classColor" },
    },
    {
      title = "Power",
      { kind = "toggle", label = "Power bar", key = "power" },
      { kind = "step", label = "Height", key = "pwHeight", min = 2, max = 40, step = 1, when = on("power") },
      { kind = "toggle", label = "Numbers", key = "pwText", when = on("power") },
      { kind = "step", label = "Font size", key = "pwSize", min = 8, max = 28, step = 1, when = on("power") },
    },
    {
      title = "Portrait",
      { kind = "cycle", label = "Portrait", key = "portrait", list = PORTRAITS },
      { kind = "cycle", label = "Side", key = "portraitSide", list = SIDES, when = portraitOn },
    },
  }
  if tab == "target" or tab == "tot" then
    local elite = {
      title = "Elite and rare",
      { kind = "cycle", label = "Style", key = "elite", list = ELITE },
    }
    if tab == "target" then
      elite[2] = { kind = "cycle", label = "Preview", key = "previewClass", store = "preview", list = PREVIEW, segWidth = 208 }
    end
    sections[#sections + 1] = elite
  end
  if tab == "target" then
    sections[#sections + 1] = {
      title = "Buffs and debuffs",
      { kind = "toggle", label = "Show", key = "auras" },
      { kind = "step", label = "Icon size", key = "auraSize", min = 14, max = 48, step = 1, when = on("auras") },
    }
    sections[#sections + 1] = {
      title = "Cast bar",
      { kind = "toggle", label = "Show", key = "targetCast", store = "db" },
      { kind = "step", label = "Height", key = "targetCastH", store = "db", min = 10, max = 50, step = 1,
        when = function() return ns.db.targetCast end },
    }
  end
  sections[#sections + 1] = Global()
  return sections
end

local function CastSections()
  return {
    {
      title = "Size",
      { kind = "step", label = "Width", key = "castWidth", store = "db", min = 80, max = 600, step = 5 },
      { kind = "step", label = "Height", key = "castHeight", store = "db", min = 10, max = 60, step = 1 },
      { kind = "step", label = "Scale", key = "castScale", store = "db", min = 0.5, max = 2, step = 0.05, fmt = "%.2f" },
    },
    {
      title = "Parts",
      { kind = "step", label = "Font size", key = "castSize", store = "db", min = 8, max = 28, step = 1 },
      { kind = "toggle", label = "Spell icon", key = "castIcon", store = "db" },
      { kind = "toggle", label = "Time left", key = "castTime", store = "db" },
      { kind = "toggle", label = "Spark", key = "castSpark", store = "db" },
    },
    Global(),
  }
end

local TABS = {
  { key = "player", label = "Player", needs = "UnitFrames" },
  { key = "target", label = "Target", needs = "UnitFrames" },
  { key = "tot", label = "Target of target", needs = "UnitFrames", wide = true },
  { key = "pet", label = "Pet", needs = "UnitFrames" },
  { key = "cast", label = "Castbar", needs = "Castbar" },
}

------------------------------------------------------------------------
-- Reading, writing and showing a change
------------------------------------------------------------------------

local function IO(tab)
  local io = {}
  function io.blocked() return InCombatLockdown() end
  function io.get(def)
    if def.store == "db" then return ns.db[def.key] end
    if def.store == "preview" then return ns.UnitFrames.previewClass or false end
    return ns.UnitFrames:Cfg(tab)[def.key]
  end
  function io.set(def, v)
    if def.store == "db" then
      ns.db[def.key] = v
    elseif def.store == "preview" then
      ns.UnitFrames.previewClass = v or nil
    else
      ns.UnitFrames:Cfg(tab)[def.key] = v
    end
  end
  function io.changed(def)
    local U, C = ns.UnitFrames, ns.Castbar
    if def.key == "font" then
      S.ApplyFonts()
      FUI:Refresh()
    elseif def.key == "alpha" then
      FUI:Refresh()
    elseif def.key == "targetCast" then
      C:SetTargetBar(ns.db.targetCast)
    elseif def.key == "targetCastH" or tab == "cast" then
      C:LayoutAll()
    else
      local f = U.frames[tab]
      U:Layout(f)
      U:Update(f)
      if def.key == "scale" then U:Place() end
    end
    E:RefreshPage() -- a change can dim or wake other rows
  end
  return io
end

------------------------------------------------------------------------
-- A page of cards, in two columns
------------------------------------------------------------------------

function E:Page(tab)
  local page = self.pages[tab]
  if page then return page end
  local p = self.panel
  page = { frame = CreateFrame("Frame", nil, p), rows = {} }
  page.frame:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -(HEAD + TAB_H + GAP))
  page.frame:SetPoint("TOPRIGHT", p, "TOPRIGHT", 0, -(HEAD + TAB_H + GAP))
  local io = IO(tab)
  local heights = { 0, 0 }
  local sections = tab == "cast" and CastSections() or FrameSections(tab)
  for _, sec in ipairs(sections) do
    local col = heights[2] < heights[1] and 2 or 1 -- the shorter column
    local card = S.Card(page.frame, sec.title, COL_W)
    for _, def in ipairs(sec) do
      page.rows[#page.rows + 1] = card:Add(def, io)
    end
    local h = S.CARD_HEAD + #sec * S.ROW_H + 4
    card:SetPoint("TOPLEFT", page.frame, "TOPLEFT", GAP + (col - 1) * (COL_W + GAP), -heights[col])
    heights[col] = heights[col] + h + GAP
  end
  page.height = max(heights[1], heights[2])
  page.frame:SetHeight(page.height)
  page.frame:Hide()
  self.pages[tab] = page
  return page
end

function E:RefreshPage()
  for _, r in ipairs(self.rows) do r:Refresh() end
end

-- The chosen frame's overlay stands out.
function E:Mark()
  local U, C = ns.UnitFrames, ns.Castbar
  local function paint(f, on)
    if f and f.mover then f.mover.fill:SetColorTexture(A[1], A[2], A[3], on and 0.45 or 0.2) end
  end
  for key, f in pairs(U.frames) do paint(f, key == self.tab) end
  paint(C.player, self.tab == "cast")
end

function E:Select(tab)
  self.tab = tab
  for key, page in pairs(self.pages) do
    if key ~= tab then page.frame:Hide() end
  end
  local page = self:Page(tab)
  page.frame:Show()
  self.rows = page.rows
  self:RefreshPage()
  self.panel:SetHeight(HEAD + TAB_H + GAP + page.height + FOOT)
  for _, b in ipairs(self.tabs) do
    local on = b.tab == tab
    if on then
      b.text:SetTextColor(A[1], A[2], A[3])
    else
      b.text:SetTextColor(0.66, 0.68, 0.72)
    end
    b.line:SetShown(on)
    b.fillTex:SetShown(on)
  end
  self:Mark()
end

function E:Reset()
  if InCombatLockdown() then return end
  if self.tab == "cast" then
    ns.Castbar:Reset()
  else
    ns.UnitFrames:ResetFrame(self.tab)
  end
  self:RefreshPage()
end

------------------------------------------------------------------------
-- The window
------------------------------------------------------------------------

function E:Build()
  if self.panel then return end
  local p = CreateFrame("Frame", "KUIEditMode", UIParent)
  p:SetFrameStrata("DIALOG")
  p:SetToplevel(true)
  p:SetClampedToScreen(true)
  p:SetMovable(true)
  p:EnableMouse(true)
  p:SetWidth(WIDTH)
  p:Hide()
  S.Panel(p, math.max(ns.db.alpha, 0.94)) -- stays readable over the world, whatever the opacity
  S.TitleBar(p, "Edit mode", HEAD)
  self.panel = p

  local header = CreateFrame("Frame", nil, p)
  header:SetPoint("TOPLEFT", 1, -1)
  header:SetPoint("TOPRIGHT", -1, -1)
  header:SetHeight(HEAD - 1)
  header:EnableMouse(true)
  header:RegisterForDrag("LeftButton")
  header:SetScript("OnDragStart", function() p:StartMoving() end)
  header:SetScript("OnDragStop", function()
    p:StopMovingOrSizing()
    ns.db.editLeft, ns.db.editTop = floor(p:GetLeft() + 0.5), floor(p:GetTop() + 0.5)
  end)
  local x = S.UIButton(header, "x", 22, function() FUI:SetUnlocked(false) end, "Close the edit mode")
  x:SetPoint("RIGHT", -3, 0)

  -- Tabs for the parts that are switched on. A long name gets more room.
  local shown, shares = {}, 0
  for _, t in ipairs(TABS) do
    if ns[t.needs].enabled then
      shown[#shown + 1] = t
      shares = shares + (t.wide and 1.7 or 1)
    end
  end
  local unit = (WIDTH - 2) / max(shares, 1)
  local left = 1
  for i, t in ipairs(shown) do
    local w = unit * (t.wide and 1.7 or 1)
    local b = S.UIButton(p, t.label, w, function() E:Select(t.key) end)
    b:SetHeight(TAB_H - 1)
    b:SetPoint("TOPLEFT", p, "TOPLEFT", left, -(HEAD + 1))
    b.tab = t.key
    b.fillTex = S.Tex(b, "BACKGROUND")
    b.fillTex:SetAllPoints()
    b.fillTex:SetColorTexture(A[1], A[2], A[3], 0.09)
    b.line = S.Tex(b, "OVERLAY")
    b.line:SetPoint("BOTTOMLEFT")
    b.line:SetPoint("BOTTOMRIGHT")
    b.line:SetHeight(2)
    b.line:SetColorTexture(A[1], A[2], A[3], 1)
    self.tabs[i] = b
    left = left + w
  end
  local base = S.Tex(p, "BORDER")
  base:SetPoint("TOPLEFT", p, "TOPLEFT", 1, -(HEAD + TAB_H))
  base:SetPoint("TOPRIGHT", p, "TOPRIGHT", -1, -(HEAD + TAB_H))
  base:SetHeight(1)
  base:SetColorTexture(S.SOFT[1], S.SOFT[2], S.SOFT[3], 1)

  local reset = S.PillButton(p, "Reset this frame", 120, function() E:Reset() end, false, "Back to its default settings and spot")
  reset:SetPoint("BOTTOMLEFT", GAP, GAP)
  local done = S.PillButton(p, "Done", 80, function() FUI:SetUnlocked(false) end, true)
  done:SetPoint("BOTTOMRIGHT", -GAP, GAP)
  local hint = S.UIText(p, nil, "CENTER", nil, 12)
  hint:SetPoint("LEFT", reset, "RIGHT", 6, 0)
  hint:SetPoint("RIGHT", done, "LEFT", -6, 0)
  hint:SetText("Drag a frame to move it. Click one to change it.")
  hint:SetTextColor(0.6, 0.63, 0.68)
  self.done, self.reset = done, reset

  p:SetScript("OnHide", function()
    if FUI.unlocked then FUI:SetUnlocked(false) end
  end)
  table.insert(UISpecialFrames, "KUIEditMode") -- Esc closes it

  -- Clicking a frame's overlay jumps to its tab.
  local function pick(f, tab)
    if f and f.mover then
      f.mover:SetScript("OnMouseUp", function() E:Select(tab) end)
    end
  end
  for key, f in pairs(ns.UnitFrames.frames) do pick(f, key) end
  pick(ns.Castbar.player, "cast")
  self.first = shown[1] and shown[1].key
end

function E:SetShown(on)
  if on then
    if not (ns.UnitFrames.enabled or ns.Castbar.enabled) then return end
    self:Build()
    local p = self.panel
    p:ClearAllPoints()
    if ns.db.editLeft then
      p:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", ns.db.editLeft, ns.db.editTop)
    else
      p:SetPoint("TOP", UIParent, "TOP", 0, -50) -- clear of the frames by default
    end
    S.Panel(p, math.max(ns.db.alpha, 0.94))
    self:Select(self.tab or self.first)
    p:Show()
  elseif self.panel then
    self.panel:Hide()
  end
end
