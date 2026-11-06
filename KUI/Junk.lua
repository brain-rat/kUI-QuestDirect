-- kUI · Junk
-- Sells your grey (poor-quality) items when you open a vendor, then says what it
-- made. Hold Shift while opening the vendor to skip it. Never repairs.
-- Each slot is checked again right before selling, so nothing else gets sold or used.

local _, ns = ...
local FUI, S = ns.FUI, ns.Style

local J = { key = "junk", name = "Sell junk" }
ns.Junk = J

local CC = C_Container
local STEP = 0.2 -- seconds between sales, so the server keeps up

local function NumSlots(bag)
  local fn = CC and CC.GetContainerNumSlots or GetContainerNumSlots
  return fn and fn(bag) or 0
end

local function Info(bag, slot)
  if CC and CC.GetContainerItemInfo then return CC.GetContainerItemInfo(bag, slot) end
  local tex, count, locked, quality, _, _, link, _, noValue, itemID = GetContainerItemInfo(bag, slot)
  if not tex then return nil end
  return { stackCount = count, isLocked = locked, quality = quality, hyperlink = link, hasNoValue = noValue, itemID = itemID }
end

local function Sell(bag, slot)
  local fn = CC and CC.UseContainerItem or UseContainerItem
  if fn then fn(bag, slot) end
end

local function SellPrice(id)
  local fn = C_Item and C_Item.GetItemInfo or GetItemInfo
  local sell = select(11, fn(id))
  return sell or 0
end

local function Money(c)
  if GetCoinTextureString then return GetCoinTextureString(c) end
  return ("%dg %ds %dc"):format(math.floor(c / 10000), math.floor(c / 100) % 100, c % 100)
end

local function IsJunk(info)
  return info and info.quality == 0 and not info.hasNoValue and not info.isLocked and info.itemID
end

-- Every grey item you can sell: { bag, slot, id, count, value }
function J:Find()
  local list = {}
  for bag = 0, (NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4) do
    for slot = 1, NumSlots(bag) do
      local info = Info(bag, slot)
      if IsJunk(info) then
        local price = SellPrice(info.itemID)
        if price > 0 then
          list[#list + 1] = { bag = bag, slot = slot, id = info.itemID, count = info.stackCount or 1, value = price * (info.stackCount or 1) }
        end
      end
    end
  end
  return list
end

function J:Run()
  if self.running then return end
  local list = self:Find()
  if #list == 0 then return end
  self.running = true
  local i, sold, total = 0, 0, 0
  local function step()
    if not self.atMerchant then
      self.running = false
      if sold > 0 then FUI:Print("Sold %d junk item%s for %s (the vendor closed before the rest).", sold, sold == 1 and "" or "s", Money(total)) end
      return
    end
    i = i + 1
    local it = list[i]
    if not it then
      self.running = false
      if sold > 0 then FUI:Print("Sold %d junk item%s for %s.", sold, sold == 1 and "" or "s", Money(total)) end
      return
    end
    local info = Info(it.bag, it.slot)
    -- still the same grey item in that slot?
    if IsJunk(info) and info.itemID == it.id then
      Sell(it.bag, it.slot)
      sold = sold + 1
      total = total + SellPrice(it.id) * (info.stackCount or 1)
    end
    C_Timer.After(STEP, step)
  end
  step()
end

function J:Enable()
  self.enabled = true
  local ev = CreateFrame("Frame")
  ev:RegisterEvent("MERCHANT_SHOW")
  ev:RegisterEvent("MERCHANT_CLOSED")
  ev:SetScript("OnEvent", function(_, event)
    if event == "MERCHANT_SHOW" then
      J.atMerchant = true
      if IsShiftKeyDown and IsShiftKeyDown() then return end
      C_Timer.After(0.3, function() if J.atMerchant then J:Run() end end)
    else
      J.atMerchant = false
    end
  end)
end

FUI:Register(J)
