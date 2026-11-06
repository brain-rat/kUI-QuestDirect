-- kUI · Controls
-- The settings controls every kUI panel builds from: flat sliders, switches,
-- segmented choices and steppers, grouped into cards. Same dark panels, thin
-- borders and sky-blue accent as the rest of the UI.
--
-- A row is made from a definition and an `io` table:
--   def = { kind = "step" | "cycle" | "toggle", label, key, ... }
--     step:   min, max, step, fmt            a slider (the mouse wheel steps it)
--     cycle:  list = { { key, name } }       segmented buttons
--             stepper = true                 < value > for long lists; list may be a function
--     toggle:                                a switch
--     when:   function() -> bool             dims the row when it has no effect
--   io = { get(def), set(def, v), changed(def), blocked() }

local _, ns = ...
local S = ns.Style

S.SOFT = { 0.24, 0.28, 0.36 } -- quieter borders inside a panel
local ROW_H, CARD_HEAD = 22, 21
local floor, max, min = math.floor, math.max, math.min
local A = S.ACCENT

S.ROW_H, S.CARD_HEAD = ROW_H, CARD_HEAD

local function List(def)
  return type(def.list) == "function" and def.list() or def.list
end

local function NameOf(def, v)
  for _, it in ipairs(List(def)) do
    if it.key == v then return it.name end
  end
  return tostring(v)
end

------------------------------------------------------------------------
-- Painting each kind
------------------------------------------------------------------------

local function RefreshSlider(r, v)
  r.slider:SetValue(v)
  r.value:SetText(r.def.fmt and r.def.fmt:format(v) or tostring(v))
end

local function RefreshSwitch(r, v)
  local sw = r.switch
  if v then
    sw.track:SetColorTexture(A[1], A[2], A[3], 0.9)
    sw.knob:SetColorTexture(1, 1, 1, 1)
  else
    sw.track:SetColorTexture(1, 1, 1, 0.14)
    sw.knob:SetColorTexture(0.62, 0.65, 0.7, 1)
  end
  sw.knob:ClearAllPoints()
  sw.knob:SetPoint(v and "RIGHT" or "LEFT", sw.track, v and "RIGHT" or "LEFT", v and -1 or 1, 0)
  r.current = v
end

local function RefreshSegments(r, v)
  for _, b in ipairs(r.segments) do
    local on = b.choice == v
    if on then
      b.bg:SetColorTexture(A[1], A[2], A[3], 0.28)
      b.text:SetTextColor(A[1], A[2], A[3])
    else
      b.bg:SetColorTexture(1, 1, 1, 0.04)
      b.text:SetTextColor(0.72, 0.74, 0.78)
    end
  end
  r.current = NameOf(r.def, v)
end

local function RefreshStepper(r, v)
  r.current = NameOf(r.def, v)
  r.value:SetText(r.current)
end

------------------------------------------------------------------------
-- Building each kind
------------------------------------------------------------------------

local function BuildSlider(r, def)
  r.value = S.Text(r, nil, "RIGHT", nil, 12)
  r.value:SetPoint("RIGHT", -8, 0)
  r.value:SetWidth(36)
  local sl = CreateFrame("Slider", nil, r)
  sl:SetOrientation("HORIZONTAL")
  sl:SetSize(100, 16)
  sl:SetPoint("RIGHT", r.value, "LEFT", -6, 0)
  sl:SetMinMaxValues(def.min, def.max)
  sl:SetValueStep(def.step)
  if sl.SetObeyStepOnDrag then sl:SetObeyStepOnDrag(true) end
  sl:EnableMouseWheel(true)
  local track = S.Tex(sl, "BACKGROUND")
  track:SetPoint("LEFT")
  track:SetPoint("RIGHT")
  track:SetHeight(4)
  track:SetColorTexture(1, 1, 1, 0.12)
  sl:SetThumbTexture(S.WHITE)
  local thumb = sl:GetThumbTexture()
  thumb:SetSize(6, 14)
  thumb:SetVertexColor(A[1], A[2], A[3], 1)
  local fill = S.Tex(sl, "ARTWORK")
  fill:SetPoint("LEFT", track, "LEFT")
  fill:SetPoint("RIGHT", thumb, "CENTER")
  fill:SetHeight(4)
  fill:SetColorTexture(A[1], A[2], A[3], 0.65)
  sl:SetScript("OnValueChanged", function(_, v)
    if r.filling then return end
    r:Set(r:Snap(v))
  end)
  sl:SetScript("OnMouseWheel", function(_, delta) r:Step(delta > 0 and 1 or -1) end)
  r.slider = sl
end

local function BuildSwitch(r)
  local sw = CreateFrame("Button", nil, r)
  sw:SetAllPoints(r)
  S.Highlight(sw, 0.04)
  sw.track = S.Tex(sw, "ARTWORK")
  sw.track:SetSize(28, 14)
  sw.track:SetPoint("RIGHT", -8, 0)
  sw.knob = S.Tex(sw, "OVERLAY")
  sw.knob:SetSize(12, 12)
  sw:SetScript("OnClick", function() r:Step(1) end)
  r.switch = sw
end

local function BuildSegments(r, def, width)
  local list = List(def)
  local total = min(def.segWidth or 164, width - 16)
  local w = total / #list
  r.segments = {}
  for i, it in ipairs(list) do
    local b = S.Button(r, it.name, w, function() r:Set(it.key) end)
    b:SetHeight(18)
    b:SetPoint("RIGHT", r, "RIGHT", -8 - (#list - i) * w, 0)
    S.SetFont(b.text, 11)
    b.choice = it.key
    b.bg = S.Tex(b, "BACKGROUND")
    b.bg:SetAllPoints()
    r.segments[i] = b
  end
  local box = CreateFrame("Frame", nil, r)
  box:SetPoint("TOPRIGHT", r, "RIGHT", -8, 9)
  box:SetSize(total, 18)
  S.ColorEdges(S.Edges(box, "OVERLAY", 3), S.SOFT[1], S.SOFT[2], S.SOFT[3], 1)
end

local function BuildStepper(r)
  r.plus = S.Button(r, ">", 20, function() r:Step(1) end)
  r.plus:SetPoint("RIGHT", -6, 0)
  r.value = S.Text(r, nil, "CENTER", nil, 12)
  r.value:SetPoint("RIGHT", r.plus, "LEFT", 0, 0)
  r.value:SetWidth(112)
  r.minus = S.Button(r, "<", 20, function() r:Step(-1) end)
  r.minus:SetPoint("RIGHT", r.value, "LEFT", 0, 0)
end

------------------------------------------------------------------------
-- A row
------------------------------------------------------------------------

local Row = {}

function Row:Snap(v)
  local def = self.def
  return max(def.min, min(def.max, floor(v / def.step + 0.5) * def.step))
end

-- Set a value from the controls. Nothing changes while the panel says it's blocked.
function Row:Set(v)
  local io = self.io
  if io.blocked and io.blocked() then return self:Refresh() end
  if v == io.get(self.def) then return self:Refresh() end
  io.set(self.def, v)
  if io.changed then io.changed(self.def) end
  self:Refresh()
end

-- One notch: up or down a step, next or previous choice, or flip a switch.
function Row:Step(dir)
  local def, v = self.def, self.io.get(self.def)
  if def.kind == "step" then
    self:Set(self:Snap(v + dir * def.step))
  elseif def.kind == "toggle" then
    self:Set(not v)
  else
    local list, idx = List(def), 1
    for i, it in ipairs(list) do if it.key == v then idx = i end end
    self:Set(list[(idx - 1 + dir) % #list + 1].key)
  end
end

function Row:Refresh()
  local def, v = self.def, self.io.get(self.def)
  self.filling = true
  if self.slider then
    RefreshSlider(self, v)
  elseif self.switch then
    RefreshSwitch(self, v)
  elseif self.segments then
    RefreshSegments(self, v)
  else
    RefreshStepper(self, v)
  end
  self.filling = false
  self:SetAlpha((def.when and not def.when()) and 0.45 or 1)
end

function S.Row(parent, def, width, io)
  local r = CreateFrame("Frame", nil, parent)
  r:SetSize(width, ROW_H)
  r.def, r.io = def, io
  for k, fn in pairs(Row) do r[k] = fn end
  r.label = S.Text(r, nil, "LEFT", nil, 12)
  r.label:SetPoint("LEFT", 9, 0)
  r.label:SetText(def.label)
  r.label:SetTextColor(0.85, 0.86, 0.88)
  if def.kind == "step" then
    BuildSlider(r, def)
  elseif def.kind == "toggle" then
    BuildSwitch(r)
  elseif def.stepper then
    BuildStepper(r)
  else
    BuildSegments(r, def, width)
  end
  r:Refresh()
  return r
end

------------------------------------------------------------------------
-- Cards and buttons
------------------------------------------------------------------------

-- A titled group of rows. card:Add(def, io) adds one and grows the card.
function S.Card(parent, title, width)
  local c = CreateFrame("Frame", nil, parent)
  c:SetWidth(width)
  c:SetHeight(CARD_HEAD + 4)
  local fill = S.Tex(c, "BACKGROUND", -5)
  fill:SetAllPoints()
  fill:SetColorTexture(1, 1, 1, 0.025)
  S.ColorEdges(S.Edges(c, "BACKGROUND", -4), S.SOFT[1], S.SOFT[2], S.SOFT[3], 0.8)
  c.title = S.Text(c, nil, "LEFT", nil, 12)
  c.title:SetPoint("TOPLEFT", 9, -5)
  c.title:SetText(title)
  c.title:SetTextColor(A[1], A[2], A[3])
  c.rows = {}
  function c:Add(def, io)
    local r = S.Row(self, def, width - 2, io)
    r:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -(CARD_HEAD + #self.rows * ROW_H))
    self.rows[#self.rows + 1] = r
    self:SetHeight(CARD_HEAD + #self.rows * ROW_H + 4)
    return r
  end
  return c
end

-- A bordered button. primary: filled with the accent colour.
function S.PillButton(parent, label, width, onClick, primary, tip)
  local b = S.Button(parent, label, width, onClick, tip)
  b:SetHeight(22)
  b.bg = S.Tex(b, "BACKGROUND")
  b.bg:SetAllPoints()
  if primary then
    b.bg:SetColorTexture(A[1], A[2], A[3], 0.9)
    b.text:SetTextColor(0.03, 0.05, 0.08)
  else
    b.bg:SetColorTexture(1, 1, 1, 0.05)
    S.ColorEdges(S.Edges(b, "BORDER"), S.SOFT[1], S.SOFT[2], S.SOFT[3], 1)
  end
  return b
end

-- Window title strip: the accent "kUI", then what this window is.
function S.TitleBar(parent, subtitle, height)
  local bar = S.Header(parent, height)
  local line = S.Tex(parent, "BORDER")
  line:SetPoint("TOPLEFT", parent, "TOPLEFT", 1, -height)
  line:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -1, -height)
  line:SetHeight(1)
  line:SetColorTexture(A[1], A[2], A[3], 0.55)
  local brand = S.Text(parent, nil, "LEFT", "OVERLAY", 15)
  brand:SetPoint("TOPLEFT", 9, -(height - 15) / 2)
  brand:SetText("kUI")
  brand:SetTextColor(A[1], A[2], A[3])
  local sub = S.Text(parent, nil, "LEFT", "OVERLAY", 13)
  sub:SetPoint("LEFT", brand, "RIGHT", 7, 0)
  sub:SetText(subtitle)
  sub:SetTextColor(0.78, 0.8, 0.84)
  return bar, brand, sub
end
