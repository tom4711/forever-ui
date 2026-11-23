local function region(alpha, color)
    local value = { alpha = alpha or 1, color = color or { 1, 1, 1, 1 }, shown = true }
    function value:GetAlpha() return self.alpha end
    function value:SetAlpha(nextAlpha) self.alpha = nextAlpha end
    function value:GetTextColor() return unpack(self.color) end
    function value:SetTextColor(...) self.color = { ... } end
    function value:SetShown(shown) self.shown = shown end
    function value:SetPoint() end
    function value:SetHeight() end
    function value:SetJustifyH() end
    function value:SetText(text) self.text = text end
    return value
end

local function window()
    local frame = region()
    frame.Bg = region(0.8)
    frame.NineSlice = region(0.5)
    frame.TitleContainer = { TitleText = region() }
    frame.art = {}
    function frame:IsShown() return self.shown end
    return frame
end

local function withAppearance(body)
    local driver, timers, inCombat = {}, {}, false
    function driver:RegisterEvent() end
    function driver:UnregisterAllEvents() end
    function driver:SetScript(name, callback) self[name] = callback end

    local bags, bank = window(), window()
    bags.Background1Slot = region(0.75)
    bank.Background = region(0.9)
    bank.bankType = 2
    function bank:GetActiveBankType() return self.bankType end

    local ns = {
        db = { inventory = { enabled = true, opacity = 0.92 } },
        L = { INVENTORY_FREE_SLOTS = "%d free" },
        UI = {
            Rect = function(frame)
                local art = region()
                frame.art[#frame.art + 1] = art
                return art
            end,
            Text = function(frame)
                frame.freeSlots = region()
                return frame.freeSlots
            end,
        },
    }
    local function step()
        local pending = timers
        timers = {}
        for _, callback in ipairs(pending) do callback() end
    end
    local function refresh(enabled, opacity)
        ns.db.inventory.enabled = enabled
        if opacity then ns.db.inventory.opacity = opacity end
        ns.Inventory.Refresh()
        step()
    end

    withGlobals({
        CreateFrame = function() return driver end,
        InCombatLockdown = function() return inCombat end,
        C_Timer = { After = function(_, callback) timers[#timers + 1] = callback end },
        EventRegistry = false,
        NUM_CONTAINER_FRAMES = 0,
        NUM_BAG_FRAMES = 0,
        ContainerFrameCombinedBags = bags,
        BankFrame = bank,
        Enum = { BankType = { Character = 2 }, BagIndex = { Backpack = 0 } },
        C_Bank = { FetchNumPurchasedBankTabs = function() return 1 end },
        C_Container = { GetContainerNumFreeSlots = function() return 3 end },
        InputUtil = { IsGamepadUIEnabled = function() return false end },
        hooksecurefunc = function(object, method, callback)
            local original = object[method]
            object[method] = function(...)
                original(...)
                callback(...)
            end
        end,
    }, function()
        loadAddon("Core/Read.lua", ns)
        loadAddon("Core/CombatQueue.lua", ns)
        loadAddon("UI/Theme.lua", ns)
        loadAddon("Modules/Inventory/Appearance.lua", ns)

        local function setCombat(value)
            inCombat = value
            if not value then ns.CombatQueue.Flush() end
            step()
        end
        local function bankEvent(event)
            driver:OnEvent(event)
            step()
        end

        body(ns.Inventory.Init, refresh, bags, bank, step, setCombat, bankEvent)
    end)
end

test("Inventory releases only bag art it still owns when disabled", function()
    withAppearance(function(init, refresh, bags)
        local nativeBorderAlpha = bags.NineSlice.SetAlpha
        init()
        local title = bags.TitleContainer.TitleText
        assert(bags.Bg:GetAlpha() == 0 and bags.NineSlice:GetAlpha() == 0.19)
        assert(bags.Background1Slot:GetAlpha() == 0)
        bags.Bg:SetAlpha(0)
        nativeBorderAlpha(bags.NineSlice, 0.65)
        title:SetTextColor(0.3, 0.6, 0.9, 0.7)

        refresh(true, 0.4)
        assert(bags.art[1]:GetAlpha() == 0.4 and bags.art[2]:GetAlpha() == 0.4)
        assert(bags.freeSlots.text == "3 free" and bags.freeSlots.shown)
        refresh(false)
        assert(bags.Bg:GetAlpha() == 0, "a later writer owns the background even if it also wants zero alpha")
        assert(bags.NineSlice:GetAlpha() == 0.65, "a later border alpha survives disabling")
        assert(bags.Background1Slot:GetAlpha() == 0.75, "untouched slot art is restored")
        local r, g, b, a = title:GetTextColor()
        assert(r == 0.3 and g == 0.6 and b == 0.9 and a == 0.7, "a later title color survives disabling")
        assert(not bags.art[1].shown and not bags.freeSlots.shown)
    end)
end)

test("Inventory handles same-color claims and restores fresh values after re-enabling", function()
    withAppearance(function(init, refresh, bags)
        local title = bags.TitleContainer.TitleText
        init()
        title:SetTextColor(title:GetTextColor())
        refresh(false)
        local r, g, b, a = title:GetTextColor()
        assert(r == 1 and g == 0.82 and b == 0.42 and a == 1, "a later writer owns the matching title color")

        title:SetTextColor(0.5, 0.5, 0.5, 0.8)
        bags.Bg:SetAlpha(0.4)
        refresh(true)
        refresh(false)
        r, g, b, a = title:GetTextColor()
        assert(r == 0.5 and g == 0.5 and b == 0.5 and a == 0.8)
        assert(bags.Bg:GetAlpha() == 0.4, "the latest activation restores its own baseline")
    end)
end)

test("Inventory yields bank art on tab changes and respects combat-deferred disabling", function()
    withAppearance(function(init, refresh, bags, bank, step, setCombat, bankEvent)
        init()
        step()
        assert(bank.Background:GetAlpha() == 0 and bank.art[1].shown)
        bank.Background:SetAlpha(0)
        bank.bankType = 3
        bankEvent("BANK_TABS_CHANGED")
        assert(bank.Background:GetAlpha() == 0, "the bank tab change preserves a later zero-alpha claim")
        assert(bank.Bg:GetAlpha() == 0.8 and not bank.art[1].shown)

        bank.bankType = 2
        bankEvent("BANK_TABS_CHANGED")
        setCombat(true)
        refresh(false)
        assert(bags.art[1].shown and bank.art[1].shown, "disabling waits until combat ends")
        bank.NineSlice:SetAlpha(0.35)
        setCombat(false)
        assert(not bags.art[1].shown and not bank.art[1].shown)
        assert(bank.NineSlice:GetAlpha() == 0.35)
    end)
end)

test("Inventory leaves already-matching native art alone", function()
    withAppearance(function(init, refresh, bags)
        local title = bags.TitleContainer.TitleText
        bags.Bg:SetAlpha(0)
        title:SetTextColor(1, 0.82, 0.42, 1)
        local alphaWrites, colorWrites = 0, 0
        hooksecurefunc(bags.Bg, "SetAlpha", function() alphaWrites = alphaWrites + 1 end)
        hooksecurefunc(title, "SetTextColor", function() colorWrites = colorWrites + 1 end)
        init()
        refresh(false)
        assert(alphaWrites == 0 and colorWrites == 0, "matching values need no style or restore writes")
    end)
end)
