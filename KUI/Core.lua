-- kUI · Core
-- Settings, module start-up and /kui.

local ADDON, ns = ...
local FUI = { modules = {} }
ns.FUI = FUI
FUI.Style = ns.Style -- other add-ons (GoldForever) use the same look and font
_G.KUI = FUI
_G.ForeverUI = FUI -- the old name, for add-ons that still look for it

local defaults = {
  alpha = 0.85,   -- panel background opacity
  glow = 0.6,     -- rarity glow strength (0 = outline only)
  common = false, -- white outline + glow on common items
  loot = true,    -- kUI loot window
  lootLeft = nil, lootTop = nil, -- saved loot window spot (when not under the mouse)
  map = true,     -- square, simplified minimap
  font = "barlow", -- kUI font (see Style.lua)
  -- Bags
  bags = true,
  bank = true,
  bagCols = 10, bagSize = 36, gapX = 4, gapY = 4, sectionGap = 10,
  categories = true, ilvl = false,
  countSize = 12, headerSize = 12, outline = "OUTLINE",
  bagScale = 1,
  bagLeft = nil, bagTop = nil, bankLeft = nil, bankTop = nil,
  -- Tooltips and vendor
  tooltips = true,
  tipIlvl = true, tipVendor = true, tipDrops = true,
  junk = true,
  -- Rare scanner
  rares = true,
  rareSound = true, rareFlash = true, rareMark = true, rarePins = true,
  rareTreasures = true, -- alert for the game's treasure map markers
  chestPins = true,     -- Classic chest spawns (and finds) on the world map
  findPins = true,      -- things you've looted from the world, on the map
  findNearby = true,    -- alert near spots where you've looted something before
  chestNearby = false,  -- ...including chests
  findRange = 40,       -- yards
  findRespawn = 900,    -- seconds a looted spot counts as empty
  rareCooldown = 300,  -- seconds before the same rare alerts again
  rareToastTime = 120, -- seconds an alert stays up
}
FUI.defaults = defaults

function FUI:Print(fmt, ...)
  local msg = select("#", ...) > 0 and fmt:format(...) or fmt
  DEFAULT_CHAT_FRAME:AddMessage("|cff7fc8ffkUI|r " .. msg)
end

-- module = { name, Enable(), Refresh() }
function FUI:Register(m) table.insert(self.modules, m) end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function(_, event, name)
  if event == "ADDON_LOADED" and name == ADDON then
    KUIDB = type(KUIDB) == "table" and KUIDB or {}
    for k, v in pairs(defaults) do
      if KUIDB[k] == nil then KUIDB[k] = v end
    end
    ns.db = KUIDB
  elseif event == "PLAYER_LOGIN" then
    ns.Style.LoadSharedFonts()
    for _, m in ipairs(FUI.modules) do
      if ns.db[m.key] ~= false then
        local ok, err = pcall(m.Enable, m)
        if not ok then FUI:Print("%s couldn't start: %s", m.name, tostring(err)) end
      end
    end
  end
end)

function FUI:Refresh()
  for _, m in ipairs(self.modules) do
    if m.enabled and m.Refresh then pcall(m.Refresh, m) end
  end
end

local function OnOff(v) return v and "|cff7fff7fon|r" or "|cffff7f7foff|r" end

SLASH_KUI1 = "/kui"
SLASH_KUI2 = "/fui" -- the old name still works
SlashCmdList.KUI = function(msg)
  local db = ns.db
  if not db then return end
  local cmd, arg = (msg or ""):lower():match("^%s*(%S*)%s*(.-)%s*$")
  local n = tonumber(arg)
  local mod
  for _, m in ipairs(FUI.modules) do if m.key == cmd then mod = m end end
  if cmd == "bank" and (arg == "on" or arg == "off") then
    db.bank = arg == "on"
    FUI:Print("kUI bank window %s. Type /reload to apply.", OnOff(db.bank))
  elseif mod and (arg == "on" or arg == "off") then
    db[mod.key] = arg == "on"
    FUI:Print("%s %s. Type /reload to apply.", mod.name, OnOff(db[mod.key]))
  elseif cmd == "alpha" and n then
    db.alpha = math.max(0, math.min(1, n))
    FUI:Refresh()
    FUI:Print("panel opacity %.2f", db.alpha)
  elseif cmd == "glow" and n then
    db.glow = math.max(0, math.min(1, n))
    FUI:Refresh()
    FUI:Print("glow strength %.2f", db.glow)
  elseif cmd == "common" then
    db.common = not db.common
    FUI:Refresh()
    FUI:Print("white glow on common items: %s", OnOff(db.common))
  elseif cmd == "bags" then
    ns.Bags:Slash(arg)
  elseif cmd == "rares" or cmd == "rare" then
    if ns.Rares.enabled then ns.Rares:Slash(arg) else FUI:Print("The rare scanner is off. /kui rares on, then /reload.") end
  elseif cmd == "font" then
    local found
    for _, f in ipairs(ns.Style.FONTS) do
      if f.key == arg or f.name:lower():find(arg, 1, true) == 1 then found = found or f end
    end
    if found then
      db.font = found.key
      ns.Style.ApplyFonts()
      FUI:Refresh()
      FUI:Print("font: %s", found.name)
    else
      local names = {}
      for _, f in ipairs(ns.Style.FONTS) do names[#names + 1] = f.name end
      FUI:Print("fonts: %s", table.concat(names, ", "))
    end
  elseif cmd == "tip" or (cmd == "tooltips" and arg ~= "") then
    local map = { ilvl = "tipIlvl", vendor = "tipVendor", drops = "tipDrops" }
    if map[arg] then
      db[map[arg]] = not db[map[arg]]
      FUI:Print("tooltip %s line: %s", arg, OnOff(db[map[arg]]))
    else
      FUI:Print("/kui tooltips ilvl · vendor · drops (turn those lines on or off) · on|off")
    end
  elseif cmd == "loottest" or cmd == "test" then
    if ns.Loot then ns.Loot:Test() end
  elseif cmd == "reset" then
    db.lootLeft, db.lootTop = nil, nil
    FUI:Print("loot window back in its default spot.")
  else
    local parts = {}
    for _, m in ipairs(FUI.modules) do parts[#parts + 1] = m.name .. " " .. OnOff(db[m.key] ~= false) end
    FUI:Print("%s. Opacity %.2f, glow %.2f.", table.concat(parts, ", "), db.alpha, db.glow)
    FUI:Print("/kui bags · rares · tooltips · loot on|off · map on|off · bags on|off · rares on|off · tooltips on|off · junk on|off · bank on|off · font <name> · alpha 0-1 · glow 0-1 · common · test (sample loot window) · reset")
  end
end
