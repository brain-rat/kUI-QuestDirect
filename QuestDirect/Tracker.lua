-- QuestDirect · Tracker
-- The quest window: drag the title bar to move it, drag the corner to resize,
-- Ctrl + mouse wheel on the title bar to scale. Click a quest to navigate to it.

local _, ns = ...
local QP = ns.QP

local T = { rows = {}, used = 0 }
QP.Tracker = T

local floor, max, min = math.floor, math.max, math.min
local WHITE = "Interface\\Buttons\\WHITE8X8"
local HEADER_H, PAD = 24, 6
local TITLE_H, LINE_H, ZONE_H = 16, 13, 18

local function Text(parent, template, justify)
  local fs = parent:CreateFontString(nil, "OVERLAY", template)
  fs:SetJustifyH(justify or "LEFT")
  fs:SetWordWrap(false)
  return fs
end

local function FlatButton(parent, label, width, onClick, tip)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(width, 18)
  b.text = Text(b, "GameFontHighlightSmall", "CENTER")
  b.text:SetAllPoints()
  b.text:SetText(label)
  local hl = b:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints()
  hl:SetColorTexture(1, 1, 1, 0.12)
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

local function Yards(d)
  if not d then return "" end
  if d < 1000 then return floor(d + 0.5) .. " yd" end
  return ("%.1fk yd"):format(d / 1000)
end

local function Distance(q)
  if not q.distance then return "" end
  if q.onContinent == false then return "far" end
  return Yards(q.distance)
end

-- Yards from you to a spot on your map, or nil.
local function SpotDistance(m, x, y)
  local pm, px, py = QP.Quests:PlayerPos()
  if not pm or pm ~= m then return nil end
  return QP.Offers:Yards(m, x, y, px, py)
end

local GOLD = "|cffffd100"
local function LevelTag(level)
  if not level or level <= 0 then return "" end
  local r, g, b = QP.Quests:Color(level)
  return ("|cff%02x%02x%02x[%d]|r "):format(floor(r * 255), floor(g * 255), floor(b * 255), level)
end

------------------------------------------------------------------------
-- Window
------------------------------------------------------------------------

function T:Build()
  if self.frame then return end
  local db = QP.db
  local f = CreateFrame("Frame", "QuestDirectFrame", UIParent, "BackdropTemplate")
  f:SetFrameStrata("MEDIUM")
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:SetResizable(true)
  if f.SetResizeBounds then f:SetResizeBounds(200, 120, 700, 1100) elseif f.SetMinResize then f:SetMinResize(200, 120) end
  f:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })

  -- Title bar: drag to move, Ctrl + wheel to scale.
  local header = CreateFrame("Frame", nil, f)
  header:SetPoint("TOPLEFT", 1, -1)
  header:SetPoint("TOPRIGHT", -1, -1)
  header:SetHeight(HEADER_H)
  header:EnableMouse(true)
  header:RegisterForDrag("LeftButton")
  header:SetScript("OnDragStart", function() if not db.locked then f:StartMoving() end end)
  header:SetScript("OnDragStop", function() f:StopMovingOrSizing(); T:SavePosition() end)
  header:EnableMouseWheel(true)
  header:SetScript("OnMouseWheel", function(_, delta)
    if IsControlKeyDown() then T:SetScale(db.scale + delta * 0.05) end
  end)
  local hbg = header:CreateTexture(nil, "BACKGROUND")
  hbg:SetAllPoints()
  hbg:SetColorTexture(1, 1, 1, 0.06)
  f.title = Text(header, "GameFontNormal")
  f.title:SetPoint("LEFT", 8, 0)

  f.lockBtn = FlatButton(header, "", 46, function() QP:Slash(db.locked and "unlock" or "lock") end,
    "Lock or unlock moving and resizing.\nCtrl + mouse wheel here changes the size.")
  f.lockBtn:SetPoint("RIGHT", -4, 0)
  f.zoneBtn = FlatButton(header, "Zone", 40, function() QP:Slash("zone") end, "Show only quests in the zone you're in.")
  f.zoneBtn:SetPoint("RIGHT", f.lockBtn, "LEFT", -2, 0)
  f.routeBtn = FlatButton(header, "Plan", 40, function() QP.Nav:ToggleRoute() end,
    "Plan this zone: which quest givers to visit, what to hand in and pick up at each,\nwhich objectives to do, in the shortest order. Then where to head next.")
  f.routeBtn:SetPoint("RIGHT", f.zoneBtn, "LEFT", -2, 0)
  f.collapseBtn = FlatButton(header, "-", 20, function()
    db.collapsed = not db.collapsed
    T:ApplyLayout()
  end, "Collapse or expand the list.")
  f.collapseBtn:SetPoint("RIGHT", f.routeBtn, "LEFT", -2, 0)
  f.title:SetPoint("RIGHT", f.collapseBtn, "LEFT", -4, 0)

  -- Quest list
  local scroll = CreateFrame("ScrollFrame", nil, f)
  scroll:SetPoint("TOPLEFT", 1, -HEADER_H - 2)
  scroll:SetPoint("BOTTOMRIGHT", -1, 1)
  scroll:EnableMouseWheel(true)
  scroll:SetScript("OnMouseWheel", function(self, delta)
    local maxScroll = max(0, T.content:GetHeight() - self:GetHeight())
    self:SetVerticalScroll(min(maxScroll, max(0, self:GetVerticalScroll() - delta * 40)))
  end)
  local content = CreateFrame("Frame", nil, scroll)
  content:SetSize(10, 10)
  scroll:SetScrollChild(content)
  f.scroll, self.content = scroll, content

  f.empty = Text(content, "GameFontDisableSmall")
  f.empty:SetPoint("TOPLEFT", PAD + 4, -PAD)
  f.empty:SetWordWrap(true)
  f.empty:SetText("No quests to show. Pick some up, or type /qd unhide or /qd zone.")

  -- Resize corner
  local grip = CreateFrame("Button", nil, f)
  grip:SetSize(16, 16)
  grip:SetPoint("BOTTOMRIGHT", -1, 1)
  grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
  grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
  grip:SetScript("OnMouseDown", function() if not db.locked then f:StartSizing("BOTTOMRIGHT") end end)
  grip:SetScript("OnMouseUp", function()
    f:StopMovingOrSizing()
    db.width, db.height = floor(f:GetWidth() + 0.5), floor(f:GetHeight() + 0.5)
    T:SavePosition()
    T:Refresh()
  end)
  f.grip = grip
  f:SetScript("OnSizeChanged", function() if T.frame then T:Refresh() end end)

  -- Distances update while you move.
  local elapsed = 0
  f:SetScript("OnUpdate", function(_, dt)
    elapsed = elapsed + dt
    if elapsed < 1 then return end
    elapsed = 0
    QP.Quests:Refresh()
    T:Refresh()
  end)

  self.frame = f
  self:ApplyLayout()
  self:ApplyLook()
  self:ApplyLock()
  if db.hidden then f:Hide() end
end

function T:ApplyLook()
  local f = self.frame
  if not f then return end
  f:SetBackdropColor(0.04, 0.05, 0.07, QP.db.alpha)
  f:SetBackdropBorderColor(0.35, 0.4, 0.5, min(1, QP.db.alpha + 0.2))
end

function T:ApplyLock()
  local f = self.frame
  if not f then return end
  f.lockBtn.text:SetText(QP.db.locked and "Locked" or "Lock")
  f.grip:SetShown(not QP.db.locked and not QP.db.collapsed)
end

function T:ApplyLayout()
  local f, db = self.frame, QP.db
  if not f then return end
  f:SetScale(db.scale)
  f:SetWidth(db.width)
  f:SetHeight(db.collapsed and (HEADER_H + 2) or db.height)
  f:ClearAllPoints()
  if db.left and db.top then
    f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", db.left, db.top)
  else
    f:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -90, -250)
  end
  f.scroll:SetShown(not db.collapsed)
  f.collapseBtn.text:SetText(db.collapsed and "+" or "-")
  self:ApplyLock()
  self:Refresh()
end

function T:SavePosition()
  local f = self.frame
  local left, top = f:GetLeft(), f:GetTop()
  if left and top then QP.db.left, QP.db.top = floor(left + 0.5), floor(top + 0.5) end
end

-- Scale around the top-left corner, so the window doesn't jump.
function T:SetScale(n)
  local f, db = self.frame, QP.db
  n = max(0.5, min(2, floor(n * 100 + 0.5) / 100))
  local old = f:GetScale()
  local left, top = f:GetLeft(), f:GetTop()
  db.scale = n
  f:SetScale(n)
  if left and top then
    db.left, db.top = floor(left * old / n + 0.5), floor(top * old / n + 0.5)
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", db.left, db.top)
  end
end

function T:Toggle()
  self:Build()
  local show = not self.frame:IsShown()
  self.frame:SetShown(show)
  QP.db.hidden = not show
  if show then self:Refresh() end
end

------------------------------------------------------------------------
-- Rows
------------------------------------------------------------------------

local SOURCE = {
  game = "From the game's own map data",
  learned = "You've seen this quest offered here",
  classic = "From Classic quest data (may differ in Forever)",
}

local function OfferTooltip(row, o)
  GameTooltip:SetOwner(row, "ANCHOR_LEFT")
  local cr, cg, cb = 1, 0.82, 0
  if o.level then cr, cg, cb = QP.Quests:Color(o.level) end
  GameTooltip:SetText(o.title, cr, cg, cb)
  local bits = {}
  if o.level and o.level > 0 then bits[#bits + 1] = "Level " .. o.level end
  if o.min and o.min > 1 then bits[#bits + 1] = "needs " .. o.min end
  if o.elite then bits[#bits + 1] = "group" end
  if #bits > 0 then GameTooltip:AddLine(table.concat(bits, " · "), 0.8, 0.8, 0.8) end
  GameTooltip:AddLine("From " .. o.giver.name, 1, 1, 1)
  if o.unlockQuest then
    local q = QP.Quests:Get(o.unlockQuest)
    GameTooltip:AddLine("After you hand in " .. (q and q.title or "its earlier quest"), 1, 0.82, 0, true)
  end
  GameTooltip:AddLine(SOURCE[o.source] or "", 0.6, 0.6, 0.6)
  GameTooltip:AddLine(" ")
  GameTooltip:AddLine("Click: navigate to the quest giver\nRight-click: more", 0.6, 0.75, 1)
  GameTooltip:Show()
end

local function StopTooltip(row, s)
  GameTooltip:SetOwner(row, "ANCHOR_LEFT")
  if s.kind == "obj" then
    local first = true
    for _, id in ipairs(s.quests or { s.quest }) do
      local q = QP.Quests:Get(id)
      if q then
        if first then GameTooltip:SetText(q.title, 1, 1, 1) else GameTooltip:AddLine(q.title, 1, 1, 1) end
        first = false
        for _, o in ipairs(q.objectives or {}) do
          local c = o.finished and 0.5 or 1
          GameTooltip:AddLine("- " .. (o.text or ""), c, c, c, true)
        end
      end
    end
  else
    GameTooltip:SetText(s.name, 1, 1, 1)
    for _, id in ipairs(s.turnins) do
      local q = QP.Quests:Get(id)
      if q then GameTooltip:AddLine("Hand in: " .. q.title .. (q.complete and "" or " (once it's done)"), 1, 0.82, 0) end
    end
    for _, o in ipairs(s.pickups) do
      GameTooltip:AddLine("Pick up: " .. o.title, 1, 1, 1)
    end
  end
  GameTooltip:AddLine(" ")
  GameTooltip:AddLine("Click: go here now\nRight-click: skip", 0.6, 0.75, 1)
  GameTooltip:Show()
end

local function RowTooltip(row)
  if row.offer then return OfferTooltip(row, row.offer) end
  if row.stop then return StopTooltip(row, row.stop) end
  if row.hub then
    local h = row.hub
    GameTooltip:SetOwner(row, "ANCHOR_LEFT")
    GameTooltip:SetText("Next: " .. h.zone, 1, 1, 1)
    GameTooltip:AddLine(("%d quests for your level near %s%s"):format(h.count, h.npc,
      h.minL and (" (level " .. h.minL .. (h.maxL ~= h.minL and ("-" .. h.maxL) or "") .. ")") or ""), 0.8, 0.8, 0.8, true)
    if h.turnins > 0 then GameTooltip:AddLine(h.turnins .. " of your finished quests hand in around there", 1, 0.82, 0, true) end
    GameTooltip:AddLine("Click: navigate there", 0.6, 0.75, 1)
    GameTooltip:Show()
    return
  end
  if row.away then
    local a = row.away
    GameTooltip:SetOwner(row, "ANCHOR_LEFT")
    GameTooltip:SetText(a.title, 1, 0.82, 0)
    GameTooltip:AddLine("Hand in " .. (a.npc and ("to " .. a.npc .. ", ") or "") .. (a.zone or "elsewhere"), 1, 1, 1)
    if a.m then GameTooltip:AddLine("Click: navigate there", 0.6, 0.75, 1) end
    GameTooltip:Show()
    return
  end
  local q = row.quest
  if not q then return end
  GameTooltip:SetOwner(row, "ANCHOR_LEFT")
  GameTooltip:SetText(q.title, QP.Quests:Color(q.level))
  GameTooltip:AddLine(("Level %d · %s%s"):format(q.level, q.zone, q.distance and (" · " .. Distance(q)) or ""), 0.8, 0.8, 0.8)
  for _, o in ipairs(q.objectives) do
    local c = o.finished and 0.5 or 1
    GameTooltip:AddLine("- " .. (o.text or ""), c, c, c, true)
  end
  if q.complete then GameTooltip:AddLine("Ready to turn in", 1, 0.82, 0) end
  GameTooltip:AddLine(" ")
  GameTooltip:AddLine("Click: navigate here (again to stop)\nShift-click: link in chat\nRight-click: more", 0.6, 0.75, 1)
  GameTooltip:Show()
end

local function OpenMenu(row)
  local q = row.quest
  if not q then return end
  local id = q.id
  if not (MenuUtil and MenuUtil.CreateContextMenu) then
    if QuestMapFrame_OpenToQuestDetails then QuestMapFrame_OpenToQuestDetails(id) end
    return
  end
  MenuUtil.CreateContextMenu(row, function(_, root)
    root:CreateTitle(q.title)
    root:CreateButton(QP.char.focus == id and "Stop navigating" or "Navigate here", function() QP.Nav:Toggle(id) end)
    root:CreateButton("Open in quest log", function()
      if QuestMapFrame_OpenToQuestDetails then QuestMapFrame_OpenToQuestDetails(id) end
    end)
    if C_QuestLog.IsPushableQuest and C_QuestLog.IsPushableQuest(id) and IsInGroup() then
      root:CreateButton("Share with party", function()
        C_QuestLog.SetSelectedQuest(id)
        if QuestLogPushQuest then QuestLogPushQuest() end
      end)
    end
    root:CreateButton("Hide from tracker", function()
      QP.char.hidden[id] = true
      if QP.char.focus == id then QP.Nav:Clear() end
      QP:Emit("QUESTS_CHANGED")
    end)
  end)
end

local function PointToggle(m, x, y, title)
  local N = QP.Nav
  if N:IsPoint(m, x, y) then N:Clear(true) else N:FocusPoint({ m = m, x = x, y = y, title = title }) end
end

local function OfferMenu(row, o)
  if not (MenuUtil and MenuUtil.CreateContextMenu) then return end
  MenuUtil.CreateContextMenu(row, function(_, root)
    root:CreateTitle(o.title)
    root:CreateButton("Navigate to " .. o.giver.name, function() QP.Nav:FocusPoint({ m = o.giver.m, x = o.giver.x, y = o.giver.y, title = o.title .. " (" .. o.giver.name .. ")" }) end)
    root:CreateButton("Don't suggest this quest", function()
      QP.char.ignored[o.title:lower()] = true
      QP.Offers:Invalidate()
      QP:Emit("QUESTS_CHANGED")
    end)
  end)
end

local function StopMenu(row, i)
  if not (MenuUtil and MenuUtil.CreateContextMenu) then return QP.Plan:Skip(i) end
  MenuUtil.CreateContextMenu(row, function(_, root)
    root:CreateTitle(QP.Plan:StopTitle(row.stop))
    root:CreateButton("Go here now", function() QP.Plan:FocusStop(i) end)
    root:CreateButton("Skip this stop", function() QP.Plan:Skip(i) end)
    root:CreateButton("Re-plan from scratch", function() QP.Plan:Build(true, true) end)
    root:CreateButton("Stop the plan", function() QP.Plan:Stop(true) end)
  end)
end

local function RowClick(row, button)
  if row.section then
    QP.char.collapsed[row.section] = not QP.char.collapsed[row.section] or nil
    T:Refresh()
    return
  end
  if row.offer then
    local o = row.offer
    if button == "RightButton" then return OfferMenu(row, o) end
    return PointToggle(o.giver.m, o.giver.x, o.giver.y, o.title .. " (" .. o.giver.name .. ")")
  end
  if row.stop then
    if button == "RightButton" then return StopMenu(row, row.stopIndex) end
    return QP.Plan:FocusStop(row.stopIndex)
  end
  if row.hub then
    local h = row.hub
    return PointToggle(h.m, h.x, h.y, "Next: " .. h.zone .. " (" .. h.npc .. ")")
  end
  if row.away then
    local a = row.away
    if a.m then PointToggle(a.m, a.x, a.y, a.title .. " (turn in)") end
    return
  end
  if row.zone then
    QP.char.collapsed[row.zone] = not QP.char.collapsed[row.zone] or nil
    T:Refresh()
    return
  end
  local q = row.quest
  if not q then return end
  if button == "RightButton" then
    OpenMenu(row)
  elseif IsShiftKeyDown() then
    local link = GetQuestLink and GetQuestLink(q.id)
    if link and ChatEdit_InsertLink then ChatEdit_InsertLink(link) end
  else
    QP.Nav:Toggle(q.id)
  end
end

local function NewRow(content)
  local r = CreateFrame("Button", nil, content)
  r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  r:SetScript("OnClick", RowClick)
  r:SetScript("OnEnter", RowTooltip)
  r:SetScript("OnLeave", function() GameTooltip:Hide() end)
  local hl = r:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints()
  hl:SetColorTexture(1, 1, 1, 0.07)
  r.focusBg = r:CreateTexture(nil, "BACKGROUND")
  r.focusBg:SetAllPoints()
  r.focusBg:SetColorTexture(0.5, 0.78, 1, 0.12)
  r.bar = r:CreateTexture(nil, "ARTWORK")
  r.bar:SetPoint("TOPLEFT", 0, -1)
  r.bar:SetPoint("BOTTOMLEFT", 0, 1)
  r.bar:SetWidth(3)
  r.bar:SetColorTexture(0.5, 0.78, 1, 1)
  r.num = Text(r, "GameFontHighlightSmall", "RIGHT")
  r.num:SetPoint("TOPLEFT", 4, -3)
  r.num:SetWidth(14)
  r.title = Text(r, "GameFontNormal")
  r.title:SetPoint("TOPLEFT", 21, -2)
  r.dist = Text(r, "GameFontHighlightSmall", "RIGHT")
  r.dist:SetPoint("TOPRIGHT", -PAD, -3)
  r.title:SetPoint("RIGHT", r.dist, "LEFT", -4, 0)
  r.lines = {}
  return r
end

local function Line(r, i)
  local fs = r.lines[i]
  if not fs then
    fs = Text(r, "GameFontHighlightSmall")
    fs:SetPoint("TOPLEFT", 28, -(TITLE_H + 2 + (i - 1) * LINE_H))
    fs:SetPoint("RIGHT", -PAD, 0)
    r.lines[i] = fs
  end
  fs:Show()
  return fs
end

function T:Acquire()
  self.used = self.used + 1
  local r = self.rows[self.used]
  if not r then
    r = NewRow(self.content)
    self.rows[self.used] = r
  end
  r:Show()
  r.quest, r.zone, r.section, r.offer, r.stop, r.stopIndex, r.hub, r.away = nil, nil, nil, nil, nil, nil, nil, nil
  for _, fs in ipairs(r.lines) do fs:Hide() end
  r.bar:Hide()
  r.focusBg:Hide()
  r.num:SetText("")
  r.dist:SetText("")
  return r
end

-- Fill a row: title, right-hand text, optional number, and lines {text, r, g, b}.
function T:Fill(r, y, width, title, dist, lines, num, color)
  for i, l in ipairs(lines or {}) do
    local fs = Line(r, i)
    fs:SetText(l[1])
    fs:SetTextColor(l[2] or 0.92, l[3] or 0.92, l[4] or 0.92)
  end
  local h = TITLE_H + 4 + #(lines or {}) * LINE_H
  r:SetPoint("TOPLEFT", 0, -y)
  r:SetSize(width, h)
  r.title:SetText(title)
  r.title:SetTextColor(color and color[1] or 1, color and color[2] or 1, color and color[3] or 1)
  r.dist:SetText(dist or "")
  if num then r.num:SetText(num) end
  return y + h + 2
end

function T:Section(key, label, count, y, width)
  local r = self:Acquire()
  r.section = key
  r:SetPoint("TOPLEFT", 0, -y)
  r:SetSize(width, ZONE_H)
  r.title:SetText((QP.char.collapsed[key] and "+ " or "- ") .. label)
  r.title:SetTextColor(0.5, 0.78, 1)
  r.dist:SetText(count or "")
  return y + ZONE_H, not QP.char.collapsed[key]
end

function T:HubRow(h, y, width)
  local r = self:Acquire()
  r.hub = h
  local levels = h.minL and (" · level " .. h.minL .. (h.maxL ~= h.minL and ("-" .. h.maxL) or "")) or ""
  local lines = { { ("Near %s · %d quests%s"):format(h.npc, h.count, levels), 0.8, 0.8, 0.8 } }
  if h.turnins > 0 then lines[2] = { h.turnins .. " to hand in there too", 1, 0.82, 0 } end
  local focused = QP.Nav:IsPoint(h.m, h.x, h.y)
  r.bar:SetShown(focused)
  r.focusBg:SetShown(focused)
  return self:Fill(r, y, width, "Then head to " .. h.zone, Yards(h.distance), lines, ">", { 0.5, 0.78, 1 })
end

function T:RenderPlan(y, width)
  local P = QP.Plan
  local stops = P.stops
  local open
  local left = 0
  for _, s in ipairs(stops) do if not P.doneState[s] then left = left + 1 end end
  y, open = self:Section("plan", "Plan", left .. " stops", y, width)
  if not open then return y end
  local shown = 0
  for i, s in ipairs(stops) do
    if not P.doneState[s] then
      shown = shown + 1
      local r = self:Acquire()
      r.stop, r.stopIndex = s, i
      local lines, title, color = {}, nil, nil
      if s.kind == "obj" then
        local todo = {}
        for _, id in ipairs(s.quests or { s.quest }) do
          local q = QP.Quests:Get(id)
          if q and not q.complete then todo[#todo + 1] = q end
        end
        local q = todo[1]
        title = "Do: " .. (q and q.title or "objective") .. (#todo > 1 and ("  |cff999999+" .. (#todo - 1) .. "|r") or "")
        color = q and { QP.Quests:Color(q.level) }
        for qi, tq in ipairs(todo) do
          if qi > 1 then lines[#lines + 1] = { LevelTag(tq.level) .. tq.title, 0.85, 0.85, 0.85 } end
          local n = 0
          for _, o in ipairs(tq.objectives or {}) do
            if not o.finished and n < (#todo > 1 and 1 or 2) then
              n = n + 1
              lines[#lines + 1] = { (qi > 1 and "  " or "") .. (o.text or ""), 0.92, 0.92, 0.92 }
            end
          end
        end
      else
        title = s.name
        for _, id in ipairs(s.turnins) do
          local q = QP.Quests:Get(id)
          if q then
            lines[#lines + 1] = { GOLD .. "Hand in|r  " .. q.title .. (q.complete and "" or "  |cff999999(when done)|r"), 0.92, 0.92, 0.92 }
          end
        end
        for _, o in ipairs(s.pickups) do
          local taken = QP.Quests:Get(o.id) or (QP.Offers.logTitles and QP.Offers.logTitles[o.title:lower()])
          if not taken then
            lines[#lines + 1] = { GOLD .. "Pick up|r  " .. LevelTag(o.level) .. o.title, 0.92, 0.92, 0.92 }
          end
        end
      end
      local current = P.current == i
      r.bar:SetShown(current)
      r.focusBg:SetShown(current)
      y = self:Fill(r, y, width, title, Yards(SpotDistance(s.m, s.x, s.y)), lines, shown, color)
    end
  end
  for _, a in ipairs(P.elsewhere or {}) do
    if QP.Quests:Get(a.quest) then
      local r = self:Acquire()
      r.away = a
      y = self:Fill(r, y, width, a.title, "", { { GOLD .. "Hand in|r  " .. (a.npc and (a.npc .. ", ") or "") .. (a.zone or "another zone"), 0.8, 0.8, 0.8 } }, "", { 1, 0.82, 0 })
    end
  end
  if P.hub then y = self:HubRow(P.hub, y, width) end
  if shown == 0 and not P.hub then
    local r = self:Acquire()
    y = self:Fill(r, y, width, "Nothing left to do here", "", nil, nil, { 0.6, 0.6, 0.6 })
  end
  return y + 4
end

function T:RenderNearby(y, width)
  local O = QP.Offers
  if not O.ready then return y end
  local list = O:Nearby()
  local hub = #list < 3 and O:NextHub() or nil
  if #list == 0 and not hub then return y end
  local open
  y, open = self:Section("nearby", "Pick up nearby", #list, y, width)
  if not open then return y end
  for i = 1, math.min(#list, QP.db.nearbyMax) do
    local o = list[i]
    local r = self:Acquire()
    r.offer = o
    local focused = QP.Nav:IsPoint(o.giver.m, o.giver.x, o.giver.y)
    r.bar:SetShown(focused)
    r.focusBg:SetShown(focused)
    local lines = { { o.giver.name .. (o.unlockQuest and "  |cffffd100after a hand-in|r" or "") .. (o.elite and "  |cffff8040group|r" or ""), 0.7, 0.7, 0.7 } }
    local color = o.level and { QP.Quests:Color(o.level) } or { 1, 0.82, 0 }
    y = self:Fill(r, y, width, LevelTag(o.level) .. o.title, Yards(o.distance), lines, "!", color)
  end
  if #list > QP.db.nearbyMax then
    local r = self:Acquire()
    y = self:Fill(r, y, width, ("+%d more. Press Plan to fit them in."):format(#list - QP.db.nearbyMax), "", nil, nil, { 0.6, 0.6, 0.6 })
  end
  if hub then y = self:HubRow(hub, y, width) end
  return y + 4
end

function T:Refresh()
  local f = self.frame
  if not f or not f:IsShown() then return end
  local Q, char = QP.Quests, QP.char
  local order, groups, here = Q:Sorted()
  local width = f:GetWidth() - 2
  self.content:SetWidth(width)
  self.used = 0
  local y, total = 0, 0
  if QP.Plan:Active() then
    y = self:RenderPlan(y, width)
  elseif QP.db.nearby then
    y = self:RenderNearby(y, width)
  end
  local extra = y > 0
  local routeRank = {}
  for i, id in ipairs(char.route or {}) do routeRank[id] = i end
  local nav = QP.Nav

  for _, zone in ipairs(order) do
    local quests = groups[zone]
    total = total + #quests
    local zr = self:Acquire()
    zr.zone = zone
    zr:SetPoint("TOPLEFT", 0, -y)
    zr:SetSize(width, ZONE_H)
    zr.title:SetText((char.collapsed[zone] and "+ " or "- ") .. zone .. (zone == here and "  |cff7fc8ff(here)|r" or ""))
    zr.title:SetTextColor(0.75, 0.75, 0.75)
    zr.dist:SetText(#quests)
    y = y + ZONE_H
    if not char.collapsed[zone] then
      for _, q in ipairs(quests) do
        local r = self:Acquire()
        r.quest = q
        local focused = char.focus == q.id
        local lines = {}
        if q.failed then
          lines[#lines + 1] = { "Failed", 1, 0.3, 0.3 }
        elseif q.complete then
          lines[#lines + 1] = { "Ready to turn in", 1, 0.82, 0 }
        else
          for _, o in ipairs(q.objectives) do
            local c = o.finished and 0.5 or 0.92
            lines[#lines + 1] = { o.text or "", c, c, c }
          end
        end
        if focused and nav.target and nav.target.hop and nav.status then
          lines[#lines + 1] = { "> " .. nav.status, 0.5, 0.78, 1 }
        elseif focused and not nav.target then
          lines[#lines + 1] = { "No map location for this quest", 0.6, 0.6, 0.6 }
        end
        for i, l in ipairs(lines) do
          local fs = Line(r, i)
          fs:SetText(l[1])
          fs:SetTextColor(l[2], l[3], l[4])
        end
        local h = TITLE_H + 4 + #lines * LINE_H
        r:SetPoint("TOPLEFT", 0, -y)
        r:SetSize(width, h)
        r.title:SetText(("[%d] %s"):format(q.level, q.title))
        r.title:SetTextColor(Q:Color(q.level))
        r.dist:SetText(Distance(q))
        r.bar:SetShown(focused)
        r.focusBg:SetShown(focused)
        if routeRank[q.id] then r.num:SetText(routeRank[q.id]) end
        y = y + h + 2
      end
    end
  end
  for i = self.used + 1, #self.rows do self.rows[i]:Hide() end
  self.content:SetHeight(max(10, y))
  f.empty:SetShown(total == 0 and not extra)
  f.empty:SetWidth(width - 2 * PAD)

  local all = #Q.list
  local maxQuests = C_QuestLog.GetMaxNumQuestsCanAccept and C_QuestLog.GetMaxNumQuestsCanAccept() or 25
  f.title:SetText(("Quests  |cffffffff%d/%d|r"):format(all, maxQuests))
  local planOn = QP.Plan:Active()
  f.routeBtn.text:SetTextColor(planOn and 0.5 or 1, planOn and 0.85 or 1, 1)
  f.zoneBtn.text:SetTextColor(QP.db.zoneOnly and 0.5 or 1, QP.db.zoneOnly and 0.85 or 1, 1)
end

------------------------------------------------------------------------
-- Blizzard's tracker
------------------------------------------------------------------------

local blizzPending = false

function T:ApplyBlizzard()
  local ot = ObjectiveTrackerFrame
  if not ot then return end
  if InCombatLockdown() then
    blizzPending = true
    return
  end
  if QP.db.hideBlizzard then ot:Hide() else ot:Show() end
  if not self.blizzHooked then
    self.blizzHooked = true
    hooksecurefunc(ot, "Show", function()
      if QP.db.hideBlizzard then
        if InCombatLockdown() then blizzPending = true else ot:Hide() end
      end
    end)
  end
end

QP:On("PLAYER_REGEN_ENABLED", function()
  if blizzPending then
    blizzPending = false
    T:ApplyBlizzard()
  end
end)

QP:Listen("LOGIN", function()
  T:Build()
  T:ApplyBlizzard()
  C_Timer.After(2.5, function() T:Refresh() end)
end)
QP:On("PLAYER_ENTERING_WORLD", function() if QP.db and T.frame then T:ApplyBlizzard() end end)
QP:Listen("QUESTS_CHANGED", function() T:Refresh() end)
QP:Listen("NAV_CHANGED", function() T:Refresh() end)
QP:Listen("PLAN_CHANGED", function() T:Refresh() end)
