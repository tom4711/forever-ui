local _, ns = ...
local R = ns.Read
local Merchant = {}
ns.Merchant = Merchant

local events, visit

local function isOpen(current)
    return current == visit and not InCombatLockdown()
        and R.Call(MerchantFrame and MerchantFrame.IsShown, MerchantFrame) == true
end

local function canSell(current)
    if not isOpen(current) or not ns.db.comfort.sellJunk then return false end
    local readable, cursor = R.Try(GetCursorInfo)
    return readable and cursor == nil and R.Call(InRepairMode) == false
end

local function saleValue(entry)
    local item = R.Call(function() return entry.hyperlink end) or R.Number(entry.itemID)
    local count = R.Number(entry.stackCount)
    if not item or not count or not C_Item or not C_Item.GetItemInfo then return end
    local result = {pcall(C_Item.GetItemInfo, item)}
    local price = result[1] and R.Number(result[12])
    if price then return price * count end
end

local function transact(kind, expected, action, ...)
    if ns.GoldStats then return ns.GoldStats.MerchantAction(kind, expected, action, ...) end
    return R.Try(action, ...)
end

local function sellJunk(current)
    local container = C_Container
    if not container or not canSell(current) then return end

    local firstBag = Enum and Enum.BagIndex and Enum.BagIndex.Backpack or 0
    local lastBag = R.Number(NUM_BAG_FRAMES) or 4
    local poorQuality = Enum and Enum.ItemQuality and Enum.ItemQuality.Poor or 0
    for bag = firstBag, lastBag do
        local size = R.Number(R.Call(container.GetContainerNumSlots, bag)) or 0
        for slot = 1, size do
            local entry = R.Call(container.GetContainerItemInfo, bag, slot)
            if type(entry) == "table" and R.Number(entry.quality) == poorQuality
                and R.Boolean(entry.hasNoValue) == false and R.Boolean(entry.isLocked) == false then
                -- Using a bag slot outside a vendor can consume or equip its item.
                if not canSell(current) then return end
                local value = ns.GoldStats and saleValue(entry)
                if transact("sale", value, container.UseContainerItem, bag, slot) then current.saleRequested = true end
            end
        end
    end
end

local function repair(current)
    current.waitingForMoney = false
    if not isOpen(current) or not ns.db.comfort.autoRepair or R.Call(CanMerchantRepair) ~= true then return end

    local ok, cost, canRepair = pcall(GetRepairAllCost)
    if not ok or R.Boolean(canRepair) ~= true then return end
    cost = R.Number(cost)
    local funds = R.Number(R.Call(GetMoney))
    if not cost or cost <= 0 or not funds then return end
    if funds < cost then
        -- Some sales update the wallet after the merchant event has finished.
        current.waitingForMoney = current.saleRequested == true
        return
    end

    transact("repair", cost, RepairAllItems, false)
end

local function onEvent(_, event)
    if event == "MERCHANT_CLOSED" then
        visit = nil
    elseif event == "PLAYER_MONEY" then
        if visit and visit.waitingForMoney then repair(visit) end
    elseif not visit and (ns.db.comfort.autoRepair or ns.db.comfort.sellJunk) then
        local current = {}
        visit = current
        C_Timer.After(0, function()
            -- Allow the stock merchant window to finish opening first.
            if not isOpen(current) then return end
            sellJunk(current)
            repair(current)
        end)
    end
end

function Merchant.Init()
    if events then return end
    events = CreateFrame("Frame")
    events:RegisterEvent("MERCHANT_SHOW")
    events:RegisterEvent("MERCHANT_CLOSED")
    events:RegisterEvent("PLAYER_MONEY")
    events:SetScript("OnEvent", onEvent)
end
