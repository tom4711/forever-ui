local function withMerchant(options, body, ledger)
    local pending, sales, repairs = {}, {}, {}
    local merchant = {shown = true, funds = 100, cost = 50, canRepair = true}
    local junk = {quality = 0, isLocked = false, hasNoValue = false, hyperlink = "item:123", stackCount = 3}
    local bags = {
        [0] = {
            junk,
            {quality = 1, isLocked = false, hasNoValue = false},
            {quality = 0, isLocked = false, hasNoValue = true},
            {quality = 0, isLocked = true, hasNoValue = false},
            {isLocked = false, hasNoValue = false},
            {quality = 0, isLocked = false},
        },
        [4] = {junk},
        [5] = {junk},
    }
    local driver = {registered = {}}
    function driver:RegisterEvent(event) self.registered[event] = true end
    function driver:SetScript(_, callback) self.onEvent = callback end
    function merchant.emit(event)
        assert(driver.registered[event])
        driver.onEvent(driver, event)
    end
    function merchant.runScheduled()
        for _, callback in ipairs(pending) do callback() end
        pending = {}
    end
    local ns = {db = {comfort = options}, GoldStats = ledger}
    withGlobals({
        MerchantFrame = {IsShown = function() return merchant.shown end},
        InCombatLockdown = function() return merchant.combat == true end,
        InRepairMode = function() return merchant.repairCursor == true end,
        GetCursorInfo = function() return merchant.cursor end,
        CanMerchantRepair = function() return merchant.canRepair end,
        GetRepairAllCost = function() return merchant.cost, merchant.canRepair end,
        GetMoney = function() return merchant.funds end,
        RepairAllItems = function(guildBank) repairs[#repairs + 1] = guildBank end,
        NUM_BAG_FRAMES = 4,
        Enum = {BagIndex = {Backpack = 0}, ItemQuality = {Poor = 0}},
        C_Timer = {After = function(_, callback) pending[#pending + 1] = callback end},
        C_Item = {GetItemInfo = function(item)
            assert(item == "item:123")
            return "Junk", item, 0, 0, 0, "Junk", "", 1, "", 1, 25
        end},
        C_Container = {
            GetContainerNumSlots = function(bag) return bags[bag] and #bags[bag] or 0 end,
            GetContainerItemInfo = function(bag, slot) return bags[bag][slot] end,
            UseContainerItem = function(bag, slot)
                sales[#sales + 1] = ("%d:%d"):format(bag, slot)
                if merchant.closeAfterFirstSale then
                    merchant.shown = false
                    merchant.emit("MERCHANT_CLOSED")
                end
            end,
        },
        CreateFrame = function() return driver end,
    }, function()
        loadAddon("Core/Read.lua", ns)
        loadAddon("Modules/Merchant.lua", ns)
        ns.Merchant.Init()
        body(merchant, sales, repairs)
    end)
end

test("merchant automation is opt-in and runs only once per open vendor", function()
    local options = {sellJunk = false, autoRepair = false}
    withMerchant(options, function(merchant, sales, repairs)
        merchant.emit("MERCHANT_SHOW")
        merchant.runScheduled()
        assert(#sales == 0 and #repairs == 0)
        merchant.emit("MERCHANT_CLOSED")
        options.sellJunk = true
        merchant.emit("MERCHANT_SHOW")
        merchant.emit("MERCHANT_SHOW")
        merchant.runScheduled()
        assert(table.concat(sales, ",") == "0:1,4:1" and #repairs == 0)
        merchant.emit("MERCHANT_SHOW")
        merchant.runScheduled()
        assert(#sales == 2, "repeated merchant notifications must not sell again")

        merchant.emit("MERCHANT_CLOSED")
        options.sellJunk, options.autoRepair = false, true
        merchant.emit("MERCHANT_SHOW")
        merchant.runScheduled()
        assert(repairs[1] == false and #repairs == 1 and #sales == 2)
    end)
end)

test("merchant sales cannot outlive the vendor or interfere with the cursor", function()
    withMerchant({sellJunk = true, autoRepair = true}, function(merchant, sales, repairs)
        merchant.emit("MERCHANT_SHOW")
        merchant.emit("MERCHANT_CLOSED")
        merchant.runScheduled()
        assert(#sales == 0 and #repairs == 0)

        merchant.shown = false
        merchant.emit("MERCHANT_SHOW")
        merchant.runScheduled()
        assert(#sales == 0 and #repairs == 0)
        merchant.emit("MERCHANT_CLOSED")

        merchant.shown, merchant.cursor = true, "item"
        merchant.emit("MERCHANT_SHOW")
        merchant.runScheduled()
        assert(#sales == 0)
        merchant.emit("MERCHANT_CLOSED")

        local priorRepairs = #repairs
        merchant.cursor, merchant.closeAfterFirstSale = nil, true
        merchant.emit("MERCHANT_SHOW")
        merchant.runScheduled()
        assert(#sales == 1 and #repairs == priorRepairs)
    end)
end)

test("auto-repair checks the price and can use proceeds from the current vendor visit", function()
    withMerchant({sellJunk = true, autoRepair = true}, function(merchant, sales, repairs)
        merchant.funds = 0
        merchant.emit("MERCHANT_SHOW")
        merchant.runScheduled()
        assert(#sales == 2 and #repairs == 0)
        merchant.funds = 50
        merchant.emit("PLAYER_MONEY")
        merchant.emit("PLAYER_MONEY")
        assert(#repairs == 1 and repairs[1] == false)

        merchant.emit("MERCHANT_CLOSED")
        merchant.canRepair = false
        merchant.emit("MERCHANT_SHOW")
        merchant.runScheduled()
        assert(#repairs == 1)
    end)
end)

test("the merchant tags actual sale stacks and repair quotes for the gold ledger", function()
    local categories = {}
    local ledger = {MerchantAction = function(kind, value, action, ...)
        categories[#categories + 1] = kind .. ":" .. tostring(value)
        action(...)
        return true
    end}
    withMerchant({sellJunk = true, autoRepair = true}, function(merchant, sales, repairs)
        merchant.emit("MERCHANT_SHOW")
        merchant.runScheduled()
        assert(#sales == 2 and repairs[1] == false)
        assert(table.concat(categories, ",") == "sale:75,sale:75,repair:50")
    end, ledger)
end)
