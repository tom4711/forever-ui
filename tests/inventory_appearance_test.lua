local function region(alpha, color)
    local value = { alpha = alpha or 1, color = color or { 1, 1, 1, 1 }, shown = true }
    function value:GetAlpha() return self.alpha end
    function value:SetAlpha(nextAlpha) self.alpha = nextAlpha end
    function value:GetTextColor() return unpack(self.color) end
    function value:SetTextColor(...) self.color = { ... } end
    function value:SetColorTexture(...) self.color = { ... } end
    function value:SetVertexColor(...) self.color = { ... } end
    function value:SetTexture(texture) self.texture = texture end
    function value:SetShown(shown) self.shown = shown end
    function value:Hide() self:SetShown(false) end
    function value:SetPoint(...) self.points = self.points or {}; self.points[#self.points + 1] = {...} end
    function value:SetAllPoints(target) self.target = target end
    function value:SetHeight(height) self.height = height end
    function value:SetWidth(width) self.width = width end
    function value:SetJustifyH() end
    function value:SetText(text) self.text = text end
    function value:SetFont() end
    function value:SetShadowColor() end
    function value:SetShadowOffset() end
    return value
end

local function frame(parent)
    local frame = region()
    frame.parent, frame.level, frame.strata, frame.scale = parent, 1, "MEDIUM", 1
    frame.children, frame.art, frame.scripts = {}, {}, {}
    if parent then parent.children[#parent.children + 1] = frame end
    function frame:GetParent() return self.parent end
    function frame:GetFrameLevel() return self.level end
    function frame:SetFrameLevel(level) self.level = level end
    function frame:GetFrameStrata() return self.strata end
    function frame:SetFrameStrata(strata) self.strata = strata end
    function frame:GetScale() return self.scale end
    function frame:SetScale(scale) self.scale = scale end
    function frame:EnableMouse(enabled) self.mouse = enabled end
    function frame:IsShown() return self.shown end
    function frame:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
    function frame:SetScript(name, callback) self.scripts[name] = callback end
    function frame:HookScript(name, callback)
        local original = self.scripts[name]
        self.scripts[name] = function(...)
            if original then original(...) end
            callback(...)
        end
    end
    function frame:SetShown(shown)
        if self.shown == shown then return end
        self.shown = shown
        local script = self.scripts[shown and "OnShow" or "OnHide"]
        if script then script(self) end
    end
    function frame:CreateTexture(_, layer, _, sublevel)
        local art = region()
        art.layer, art.sublevel = layer, sublevel
        self.art[#self.art + 1] = art
        return art
    end
    function frame:CreateFontString()
        self.freeSlots = region()
        return self.freeSlots
    end
    return frame
end

local function window(parent)
    local frame = frame(parent)
    frame.Bg = region(0.8)
    frame.NineSlice = region(0.5)
    frame.TitleContainer = { TitleText = region() }
    return frame
end

local function chrome(window)
    for _, child in ipairs(window:GetParent().children) do
        if child.target == window then return child end
    end
    return nil
end

local function withAppearance(body)
    local driver, timers, inCombat, gamepad = {}, {}, false, false
    function driver:RegisterEvent() end
    function driver:UnregisterAllEvents() end
    function driver:SetScript(name, callback) self[name] = callback end

    local root = frame()
    local bags, bank = window(root), window(root)
    bags.Background1Slot = region(0.75)
    bags.items = {frame(bags)}
    function bags:EnumerateItems() return ipairs(self.items) end
    function bags:UpdateItemSlots(items) self.items = items end
    bank.Background = region(0.9)
    bank.BankPanel = frame(bank)
    bank.BankPanel.NineSlice = region(0.85)
    bank.BankPanel.items = { [frame(bank.BankPanel)] = true }
    function bank.BankPanel:EnumerateValidItems() return pairs(self.items) end
    function bank.BankPanel:GenerateItemSlotsForSelectedTab(items) self.items = items end
    bank.bankType = 2
    function bank:GetActiveBankType() return self.bankType end

    local ns = {
        db = { inventory = { enabled = true, opacity = 0.92 } },
        L = { INVENTORY_FREE_SLOTS = "%d free" },
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
        CreateFrame = function(_, _, parent) return parent and frame(parent) or driver end,
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
        InputUtil = { IsGamepadUIEnabled = function() return gamepad end },
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
        loadAddon("UI/Widgets.lua", ns)
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
        local function setGamepad(value)
            gamepad = value
            bankEvent("INPUT_DEVICE_INTERFACE_TRANSITION")
        end

        body(ns.Inventory.Init, refresh, bags, bank, step, setCombat, bankEvent, setGamepad)
    end)
end

test("Inventory casing stays visible after a recursive native repaint", function()
    withAppearance(function(init, refresh, bags, bank, step)
        local function repaint(native)
            for _, art in ipairs(native.art) do art:SetAlpha(0) end
            for _, child in ipairs(native.children) do repaint(child) end
        end

        init()
        step()
        for _, window in ipairs({bags, bank}) do
            repaint(window)
            local panel = assert(chrome(window), "inventory chrome must live outside the restyled window's tree")
            assert(panel:IsShown() and panel.art[1]:GetAlpha() == 0.92)
            assert(panel.art[2]:GetAlpha() == 0.92 and panel.art[2].color[2] > panel.art[1].color[2],
                "the petrol header remains distinct from the body after a repaint")
            assert(panel.mouse == false and panel:GetFrameLevel() == window:GetFrameLevel(),
                "window controls and labels need to stay above a passive backdrop")
            local edges = 0
            for _, art in ipairs(panel.art) do
                if art.layer == "BORDER" and (art.width == 2 or art.height == 2) then edges = edges + 1 end
            end
            assert(edges >= 4, "the gold casing should reach all four sides")
        end
        refresh(true, 0.4)
        assert(chrome(bags).art[1]:GetAlpha() == 0.4 and chrome(bags).art[2]:GetAlpha() == 0.4)
    end)
end)

test("Inventory chrome follows native stacking and visibility and yields to gamepad", function()
    withAppearance(function(init, _, bags, bank, step, _, _, setGamepad)
        local opened = 0
        bags:SetScript("OnShow", function() opened = opened + 1 end)
        init()
        step()
        local panel = assert(chrome(bags))
        bags:SetFrameLevel(14)
        bags:SetFrameStrata("HIGH")
        bags:SetScale(0.75)
        bags:SetAlpha(0.6)
        panel.scripts.OnUpdate(panel)
        assert(panel:GetFrameLevel() == 14 and panel:GetFrameStrata() == "HIGH")
        assert(panel:GetScale() == 0.75 and panel:GetAlpha() == 0.6)
        bags:SetShown(false)
        assert(not panel:IsShown())
        bags:SetShown(true)
        assert(panel:IsShown() and opened == 1)
        setGamepad(true)
        assert(not panel:IsShown() and not bags.freeSlots.shown and not chrome(bank):IsShown())
        setGamepad(false)
        assert(panel:IsShown() and bags.freeSlots.shown and chrome(bank):IsShown())
    end)
end)

test("Inventory slot trim follows pooled bags and personal bank pages", function()
    withAppearance(function(init, refresh, bags, bank, step, _, bankEvent)
        local function checkRim(button)
            local rim = assert(button.art[1], "native item slot has a neutral rim")
            assert(rim.layer == "ARTWORK" and rim.sublevel < 0 and rim.shown,
                "the rim is above the icon but below count, quality, search, and highlight art")
        end

        init()
        step()
        checkRim(bags.items[1])
        checkRim(next(bank.BankPanel.items))
        local bagSlot, bankSlot = frame(bags), frame(bank.BankPanel)
        bags:UpdateItemSlots({bagSlot})
        bank.BankPanel:GenerateItemSlotsForSelectedTab({[bankSlot] = true})
        checkRim(bagSlot)
        checkRim(bankSlot)
        bank.bankType = 3
        bankEvent("BANK_TABS_CHANGED")
        assert(not bankSlot.art[1].shown and bagSlot.art[1].shown)
        refresh(false)
        assert(not bagSlot.art[1].shown)
        refresh(true)
        assert(bagSlot.art[1].shown and #bagSlot.art == 1, "re-enabling must reuse the pooled trim")
    end)
end)

test("Inventory releases only bag art it still owns when disabled", function()
    withAppearance(function(init, refresh, bags)
        local nativeBorderAlpha = bags.NineSlice.SetAlpha
        init()
        local title = bags.TitleContainer.TitleText
        assert(bags.Bg:GetAlpha() == 0 and bags.NineSlice:GetAlpha() == 0)
        assert(bags.Background1Slot:GetAlpha() == 0)
        bags.Bg:SetAlpha(0)
        nativeBorderAlpha(bags.NineSlice, 0.65)
        title:SetTextColor(0.3, 0.6, 0.9, 0.7)

        refresh(true, 0.4)
        assert(bags.freeSlots.text == "3 free" and bags.freeSlots.shown)
        refresh(false)
        assert(bags.Bg:GetAlpha() == 0, "a later writer owns the background even if it also wants zero alpha")
        assert(bags.NineSlice:GetAlpha() == 0.65, "a later border alpha survives disabling")
        assert(bags.Background1Slot:GetAlpha() == 0.75, "untouched slot art is restored")
        local r, g, b, a = title:GetTextColor()
        assert(r == 0.3 and g == 0.6 and b == 0.9 and a == 0.7, "a later title color survives disabling")
        assert(not chrome(bags):IsShown() and not bags.freeSlots.shown)
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
        assert(bank.Background:GetAlpha() == 0 and bank.BankPanel.NineSlice:GetAlpha() == 0 and chrome(bank):IsShown())
        bank.Background:SetAlpha(0)
        bank.bankType = 3
        bankEvent("BANK_TABS_CHANGED")
        assert(bank.Background:GetAlpha() == 0, "the bank tab change preserves a later zero-alpha claim")
        assert(bank.Bg:GetAlpha() == 0.8 and not chrome(bank):IsShown())
        assert(bank.BankPanel.NineSlice:GetAlpha() == 0.85)

        bank.bankType = 2
        bankEvent("BANK_TABS_CHANGED")
        setCombat(true)
        refresh(false)
        assert(chrome(bags):IsShown() and chrome(bank):IsShown(), "disabling waits until combat ends")
        bank.NineSlice:SetAlpha(0.35)
        setCombat(false)
        assert(not chrome(bags):IsShown() and not chrome(bank):IsShown())
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
