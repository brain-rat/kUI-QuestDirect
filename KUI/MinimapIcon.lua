-- kUI · Minimap icon
-- A small "k" on the minimap's edge. Click it for a menu: the edit mode, bag
-- settings, the rare list, samples of things to look at, and switches for each
-- part of kUI. Drag it to move it around the edge.

local _, ns = ...
local FUI, S = ns.FUI, ns.Style

local I = { key = "icon", name = "Minimap icon", rows = {} }
ns.MinimapIcon = I

local SIZE, WIDTH, ROW_H, HEAD_H, HEAD = 24, 220, 22, 22, 28
local A = S.ACCENT
local rad, deg, atan2, cos, sin, abs, max = math.rad, math.deg, math.atan2 or math.atan, math.cos, math.sin, math.abs, math.max

------------------------------------------------------------------------
-- Where it sits
------------------------------------------------------------------------

-- Inside the corners on the square map, centred on the edge of a round one.
function I:Place()
  local b, angle = self.button, rad(ns.db.iconAngle)
  local dx, dy = cos(angle), sin(angle)
  local w, h = Minimap:GetWidth() / 2, Minimap:GetHeight() / 2
  local x, y
  if ns.db.map ~= false then
    local m = max(abs(dx), abs(dy))
    x, y = dx / m * (w - SIZE / 2 - 3), dy / m * (h - SIZE / 2 - 3)
  else
    x, y = dx * w, dy * h
  end
  b:ClearAllPoints()
  b:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function Dragging(b)
  local cx, cy = Minimap:GetCenter()
  if not cx then return end
  local x, y = GetCursorPosition()
  local s = Minimap:GetEffectiveScale()
  ns.db.iconAngle = deg(atan2(y / s - cy, x / s - cx)) % 360
  I:Place()
end

------------------------------------------------------------------------
-- The menu
------------------------------------------------------------------------

-- Parts of kUI that need a /reload to match their switch.
local function ReloadPending()
  for _, m in ipairs(FUI.modules) do
    if m ~= I and (ns.db[m.key] ~= false) ~= (m.enabled == true) then return true end
  end
  return false
end

local function Items()
  local list = {}
  local function section(t) list[#list + 1] = { kind = "section", text = t } end
  local function action(t, fn, opts)
    local it = { kind = "action", text = t, fn = fn }
    for k, v in pairs(opts or {}) do it[k] = v end
    list[#list + 1] = it
  end

  section("Customise")
  if ns.UnitFrames.enabled or ns.Castbar.enabled or ns.ActionBars.enabled then
    action("Edit mode", function() FUI:SetUnlocked(not FUI.unlocked) end, {
      on = FUI.unlocked, off = InCombatLockdown(), note = FUI.unlocked and "open" or nil,
    })
  end
  if ns.ActionBars.enabled then
    action("Quick keybinds", function() ns.ActionBars:QuickKeys() end, { off = InCombatLockdown() })
  end
  if ns.Bags.enabled then
    action("Bag settings", function() ns.Bags:Open(); ns.Bags:ToggleSettings() end)
  end

  if ns.Rares.enabled then
    section("Windows")
    action("Rares and treasures", function() ns.Rares:ToggleList() end)
  end

  local samples = {}
  if ns.Castbar.enabled then samples[#samples + 1] = { "Sample cast", function() ns.Castbar:Slash("test") end } end
  if ns.Loot.enabled then samples[#samples + 1] = { "Sample loot window", function() ns.Loot:Test() end } end
  if ns.Rares.enabled then samples[#samples + 1] = { "Sample rare alert", function() ns.Rares:Test() end } end
  if #samples > 0 then
    section("Try it out")
    for _, s in ipairs(samples) do action(s[1], s[2]) end
  end

  section("Parts of kUI")
  for _, m in ipairs(FUI.modules) do
    if m ~= I then
      list[#list + 1] = { kind = "switch", text = m.name, key = m.key }
    end
  end
  if ReloadPending() then
    action("Reload to apply", function() ReloadUI() end, { primary = true })
  end

  section("This icon")
  action("Hide this icon", function()
    ns.db.icon = false
    I.button:Hide()
    FUI:Print("Icon hidden. /kui icon on brings it back after a /reload.")
  end)
  return list
end

function I:Row(i)
  local r = self.rows[i]
  if r then return r end
  r = CreateFrame("Button", nil, self.menu)
  r:SetPoint("TOPLEFT", self.menu, "TOPLEFT", 1, 0)
  r.hl = S.Highlight(r, 0.08)
  r.bg = S.Tex(r, "BACKGROUND")
  r.bg:SetAllPoints()
  r.text = S.UIText(r, nil, "LEFT", "OVERLAY", 13)
  r.note = S.UIText(r, nil, "RIGHT", "OVERLAY", 11)
  r.note:SetPoint("RIGHT", -9, 0)
  r.note:SetTextColor(A[1], A[2], A[3])
  r.track = S.Tex(r, "ARTWORK")
  r.track:SetSize(24, 12)
  r.track:SetPoint("RIGHT", -9, 0)
  r.knob = S.Tex(r, "OVERLAY")
  r.knob:SetSize(10, 10)
  r:SetScript("OnClick", function(self)
    local it = self.item
    if not it or it.kind == "section" or it.off then return end
    if it.kind == "switch" then
      ns.db[it.key] = not (ns.db[it.key] ~= false)
      I:Fill() -- stays open, so several can be switched
    else
      I:CloseMenu()
      it.fn()
    end
  end)
  self.rows[i] = r
  return r
end

function I:Paint(r, it)
  r.item = it
  r.track:Hide()
  r.knob:Hide()
  r.note:SetText("")
  r.bg:SetColorTexture(0, 0, 0, 0)
  r.text:ClearAllPoints()
  r.text:SetPoint("LEFT", 9, 0)
  r.text:SetText(it.text)
  if it.kind == "section" then
    S.SetFont(r.text, 12)
    r.text:SetTextColor(A[1], A[2], A[3])
    r.hl:Hide()
    r:EnableMouse(false)
    return
  end
  S.SetFont(r.text, 13)
  r.hl:Show()
  r:EnableMouse(true)
  if it.kind == "switch" then
    local on = ns.db[it.key] ~= false
    r.text:SetTextColor(0.88, 0.89, 0.91)
    r.track:Show()
    r.knob:Show()
    if on then
      r.track:SetColorTexture(A[1], A[2], A[3], 0.9)
      r.knob:SetColorTexture(1, 1, 1, 1)
    else
      r.track:SetColorTexture(1, 1, 1, 0.14)
      r.knob:SetColorTexture(0.62, 0.65, 0.7, 1)
    end
    r.knob:ClearAllPoints()
    r.knob:SetPoint(on and "RIGHT" or "LEFT", r.track, on and "RIGHT" or "LEFT", on and -1 or 1, 0)
  elseif it.primary then
    r.bg:SetColorTexture(A[1], A[2], A[3], 0.9)
    r.text:SetTextColor(0.03, 0.05, 0.08)
  elseif it.off then
    r.text:SetTextColor(0.45, 0.47, 0.5)
    r.note:SetText("not in combat")
  else
    r.text:SetTextColor(0.92, 0.93, 0.95)
    if it.note then r.note:SetText(it.note) end
  end
end

function I:Fill()
  local items = Items()
  local y = HEAD + 3
  for i, it in ipairs(items) do
    local r = self:Row(i)
    local h = it.kind == "section" and HEAD_H or ROW_H
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", self.menu, "TOPLEFT", 1, -y)
    r:SetPoint("TOPRIGHT", self.menu, "TOPRIGHT", -1, -y)
    r:SetHeight(h)
    self:Paint(r, it)
    r:Show()
    y = y + h
  end
  for i = #items + 1, #self.rows do
    self.rows[i].item = nil
    self.rows[i]:Hide()
  end
  self.menu:SetHeight(y + 5)
end

function I:BuildMenu()
  if self.menu then return end
  local m = CreateFrame("Frame", "KUIMenu", UIParent)
  m:SetFrameStrata("DIALOG")
  m:SetToplevel(true)
  m:SetClampedToScreen(true)
  m:EnableMouse(true)
  m:SetWidth(WIDTH)
  m:Hide()
  S.Panel(m, math.max(ns.db.alpha, 0.94))
  S.TitleBar(m, "Options", HEAD)
  self.menu = m
  table.insert(UISpecialFrames, "KUIMenu") -- Esc closes it
  -- A click anywhere else closes it. Only listening while it's open.
  m:SetScript("OnShow", function(self) pcall(self.RegisterEvent, self, "GLOBAL_MOUSE_DOWN") end)
  m:SetScript("OnHide", function(self) pcall(self.UnregisterEvent, self, "GLOBAL_MOUSE_DOWN") end)
  m:SetScript("OnEvent", function(self)
    if MouseIsOver and not MouseIsOver(self) and not MouseIsOver(I.button) then self:Hide() end
  end)
end

function I:OpenMenu()
  self:BuildMenu()
  local m = self.menu
  S.Panel(m, math.max(ns.db.alpha, 0.94))
  self:Fill()
  m:ClearAllPoints()
  m:SetPoint("TOPRIGHT", self.button, "BOTTOMLEFT", -2, -2)
  m:Show()
  GameTooltip:Hide()
end

function I:CloseMenu()
  if self.menu then self.menu:Hide() end
end

function I:ToggleMenu()
  if self.menu and self.menu:IsShown() then self:CloseMenu() else self:OpenMenu() end
end

------------------------------------------------------------------------
-- The icon
------------------------------------------------------------------------

function I:Refresh()
  if self.button then S.Panel(self.button, math.max(ns.db.alpha, 0.9)) end
end

function I:Enable()
  if not Minimap then return end
  self.enabled = true
  local b = CreateFrame("Button", "KUIMinimapButton", Minimap)
  b:SetSize(SIZE, SIZE)
  b:SetFrameStrata("MEDIUM")
  b:SetFrameLevel(Minimap:GetFrameLevel() + 8)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b:RegisterForDrag("LeftButton")
  S.Panel(b, math.max(ns.db.alpha, 0.9))
  b.hover = S.Tex(b, "HIGHLIGHT")
  b.hover:SetAllPoints()
  b.hover:SetColorTexture(A[1], A[2], A[3], 0.25)
  b.glyph = S.UIText(b, nil, "CENTER", "OVERLAY", 16)
  b.glyph:SetPoint("CENTER", 0, 1)
  b.glyph:SetText("k")
  b.glyph:SetTextColor(A[1], A[2], A[3])
  b:SetScript("OnClick", function() I:ToggleMenu() end)
  b:SetScript("OnDragStart", function(self)
    I:CloseMenu()
    self:SetScript("OnUpdate", Dragging)
  end)
  b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
  b:SetScript("OnEnter", function(self)
    if I.menu and I.menu:IsShown() then return end
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("kUI", A[1], A[2], A[3])
    GameTooltip:AddLine("Click: options", 1, 1, 1)
    GameTooltip:AddLine("Drag: move around the map", 0.7, 0.72, 0.76)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  self.button = b
  self:Place()
end

FUI:Register(I)
