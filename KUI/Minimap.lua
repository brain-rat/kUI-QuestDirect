-- kUI · Minimap
-- Square, flat minimap: Blizzard's round border, compass, zoom buttons, world-map
-- button, zone banner and clock are gone. A thin strip underneath shows the zone
-- (in its PvP colour) and your coordinates.
--
--   Mouse wheel   zoom          Right-click   tracking menu
--   Click strip   world map     Middle-click  calendar (if the game has one)
--
-- Mail, queue and battleground icons and the tracking icon stay, moved to the corners.

local _, ns = ...
local FUI, S = ns.FUI, ns.Style

local M = { key = "map", name = "Square minimap" }
ns.Minimap = M

local STRIP_H = 20

-- Blizzard parts to hide (Classic and modern names; missing ones are skipped).
local HIDE = {
  "MinimapBorder", "MinimapBorderTop", "MinimapCompassTexture", "MinimapNorthTag",
  "MinimapZoomIn", "MinimapZoomOut", "MiniMapWorldMapButton", "MinimapToggleButton",
  "MinimapZoneTextButton", "GameTimeFrame", "TimeManagerClockButton",
  "MiniMapMeetingStoneFrame", "MinimapBackdropBorder",
}
local function Modern(path)
  local t = _G
  for k in path:gmatch("[^%.]+") do
    t = type(t) == "table" and rawget(t, k) or (type(t) == "table" and t == _G and _G[k]) or nil
  end
  return type(t) == "table" and t or nil
end
local HIDE_MODERN = {
  "MinimapCluster.BorderTop", "MinimapCluster.ZoneTextButton", "MinimapCluster.Tracking.Background",
  "Minimap.ZoomIn", "Minimap.ZoomOut", "Minimap.ZoomHitArea", "ExpansionLandingPageMinimapButton",
}
-- Kept, moved to a corner: { name, corner, x, y }
local KEEP = {
  { "MiniMapMailFrame", "TOPRIGHT", -2, -2 },
  { "MiniMapTracking", "TOPLEFT", 2, -2 },
  { "MiniMapTrackingFrame", "TOPLEFT", 2, -2 },
  { "MinimapCluster.Tracking", "TOPLEFT", 2, -2 },
  { "MiniMapBattlefieldFrame", "BOTTOMLEFT", 2, 2 },
  { "MiniMapLFGFrame", "BOTTOMLEFT", 2, 2 },
}

-- Other add-ons place their minimap buttons around a square now.
function GetMinimapShape() return "SQUARE" end

local function PvPColor()
  local pvp = GetZonePVPInfo and GetZonePVPInfo()
  if pvp == "sanctuary" then return 0.41, 0.8, 0.94 end
  if pvp == "friendly" then return 0.1, 1, 0.1 end
  if pvp == "hostile" then return 1, 0.1, 0.1 end
  if pvp == "contested" then return 1, 0.7, 0 end
  if pvp == "arena" or pvp == "combat" then return 1, 0.1, 0.1 end
  return 1, 0.82, 0
end

function M:Square()
  Minimap:SetMaskTexture(S.WHITE)
  if Minimap.SetArchBlobRingScalar then Minimap:SetArchBlobRingScalar(0) end
  if Minimap.SetArchBlobRingAlpha then Minimap:SetArchBlobRingAlpha(0) end
  if Minimap.SetQuestBlobRingScalar then Minimap:SetQuestBlobRingScalar(0) end
  if Minimap.SetQuestBlobRingAlpha then Minimap:SetQuestBlobRingAlpha(0) end
  if Minimap.SetTaskBlobRingScalar then Minimap:SetTaskBlobRingScalar(0) end
end

function M:Strip()
  ns.killing = true
  for _, name in ipairs(HIDE) do S.Kill(_G[name]) end
  for _, path in ipairs(HIDE_MODERN) do S.Kill(Modern(path)) end
  -- MinimapBackdrop holds the round art in Classic, but also some buttons: hide only its textures.
  local bd = _G.MinimapBackdrop
  if bd and bd.GetRegions then
    for _, r in ipairs({ bd:GetRegions() }) do
      if r.IsObjectType and r:IsObjectType("Texture") then r:SetAlpha(0) end
    end
  end
  for _, k in ipairs(KEEP) do
    local f = _G[k[1]] or Modern(k[1])
    if f and f.ClearAllPoints and not (f.IsProtected and f:IsProtected()) then
      pcall(function()
        f:ClearAllPoints()
        f:SetPoint(k[2], Minimap, k[2], k[3], k[4])
      end)
    end
  end
end

function M:Build()
  if self.border then return end
  -- 1px border just outside the map, and the info strip below it.
  local b = CreateFrame("Frame", nil, Minimap)
  b:SetAllPoints(Minimap)
  b:SetFrameLevel(Minimap:GetFrameLevel() + 2)
  self.edges = S.Edges(b, "OVERLAY", 7, Minimap, 1)
  self.border = b

  local strip = CreateFrame("Button", "KUIMinimapStrip", Minimap)
  strip:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", -1, -1)
  strip:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 1, -1)
  strip:SetHeight(STRIP_H)
  S.Panel(strip)
  S.Header(strip, STRIP_H)
  S.Highlight(strip, 0.06)
  strip.zone = S.Text(strip, "GameFontNormalSmall", nil, nil, 12)
  strip.zone:SetPoint("LEFT", 6, 0)
  strip.coords = S.Text(strip, "GameFontHighlightSmall", "RIGHT", nil, 12)
  strip.coords:SetPoint("RIGHT", -6, 0)
  strip.zone:SetPoint("RIGHT", strip.coords, "LEFT", -6, 0)
  strip:RegisterForClicks("LeftButtonUp")
  strip:SetScript("OnClick", function()
    if ToggleWorldMap then ToggleWorldMap() elseif ToggleFrame and WorldMapFrame then ToggleFrame(WorldMapFrame) end
  end)
  strip:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText(GetZoneText and GetZoneText() or "", PvPColor())
    local sub = GetSubZoneText and GetSubZoneText()
    if sub and sub ~= "" then GameTooltip:AddLine(sub, 1, 1, 1) end
    GameTooltip:AddLine("Click: world map", 0.6, 0.75, 1)
    GameTooltip:AddLine("On the map: wheel to zoom, right-click for tracking", 0.6, 0.75, 1)
    GameTooltip:Show()
  end)
  strip:SetScript("OnLeave", function() GameTooltip:Hide() end)
  self.strip = strip

  local elapsed = 0
  strip:SetScript("OnUpdate", function(_, dt)
    elapsed = elapsed + dt
    if elapsed < 0.2 then return end
    elapsed = 0
    M:UpdateText()
  end)

  -- Mouse: wheel zooms, right-click tracking, middle-click calendar.
  Minimap:EnableMouseWheel(true)
  Minimap:SetScript("OnMouseWheel", function(self, delta)
    local z = self:GetZoom() + (delta > 0 and 1 or -1)
    local maxZ = (self.GetZoomLevels and self:GetZoomLevels() or 6) - 1
    if z >= 0 and z <= maxZ then self:SetZoom(z) end
  end)
  Minimap:HookScript("OnMouseUp", function(_, button)
    if button == "RightButton" then
      M:TrackingMenu()
    elseif button == "MiddleButton" then
      if ToggleCalendar then pcall(ToggleCalendar) end
    end
  end)
end

function M:TrackingMenu()
  local t = Modern("MinimapCluster.Tracking.Button")
  if t and t.OpenMenu then return pcall(t.OpenMenu, t) end
  if t and t.Click then return pcall(t.Click, t) end
  if MiniMapTrackingDropDown and ToggleDropDownMenu then
    return pcall(ToggleDropDownMenu, 1, nil, MiniMapTrackingDropDown, "cursor")
  end
  local b = _G.MiniMapTrackingButton or _G.MiniMapTracking
  if b and b.Click then pcall(b.Click, b) end
end

function M:UpdateText()
  local strip = self.strip
  local zone = (GetMinimapZoneText and GetMinimapZoneText()) or (GetZoneText and GetZoneText()) or ""
  strip.zone:SetText(zone)
  strip.zone:SetTextColor(PvPColor())
  local m = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
  local text = ""
  if m and not (issecretvalue and issecretvalue(m)) then
    local pos = C_Map.GetPlayerMapPosition(m, "player")
    if pos and not (issecretvalue and issecretvalue(pos)) then
      local x, y = pos.x, pos.y
      if pos.GetXY then x, y = pos:GetXY() end
      if x and not (issecretvalue and issecretvalue(x)) and (x > 0 or y > 0) then
        text = ("%.1f, %.1f"):format(x * 100, y * 100)
      end
    end
  end
  strip.coords:SetText(text)
end

function M:Refresh()
  if not self.strip then return end
  S.Panel(self.strip)
  S.ColorEdges(self.edges, S.EDGE[1], S.EDGE[2], S.EDGE[3], math.min(1, ns.db.alpha + 0.2))
end

function M:Enable()
  if not Minimap then return end
  self.enabled = true
  self:Square()
  self:Strip()
  self:Build()
  self:Refresh()
  self:UpdateText()
  -- The game re-applies some of its own layout on loading screens.
  local ev = CreateFrame("Frame")
  ev:RegisterEvent("PLAYER_ENTERING_WORLD")
  ev:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  ev:SetScript("OnEvent", function()
    C_Timer.After(0.5, function()
      M:Square()
      M:Strip()
      M:UpdateText()
    end)
  end)
end

FUI:Register(M)
