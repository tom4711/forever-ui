local noop = function() end

local function widget(parent)
    local frame = {shown = true, parent = parent, alpha = 1, layers = {}, scripts = {}, children = {}}
    if parent then parent.children[#parent.children + 1] = frame end
    function frame:SetScript(event, callback) self.scripts[event] = callback end
    function frame:HookScript(event, callback)
        local original = self.scripts[event] or noop
        self.scripts[event] = function(...)
            original(...)
            callback(...)
        end
    end
    function frame:IsShown() return self.shown end
    function frame:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
    function frame:Show() self.shown = true end
    function frame:Hide()
        if not self.shown then return end
        self.shown = false
        if self.scripts.OnHide then self.scripts.OnHide(self) end
    end
    function frame:SetShown(value) if value then self:Show() else self:Hide() end end
    function frame:SetAlpha(value) self.alpha = value end
    function frame:GetAlpha() return self.alpha end
    function frame:CreateTexture() return widget() end
    function frame:GetChildren() return unpack(self.children) end
    function frame:IsDrawLayerEnabled(layer) return self.layers[layer] ~= false end
    function frame:DisableDrawLayer(layer) self.layers[layer] = false end
    function frame:EnableDrawLayer(layer) self.layers[layer] = true end
    function frame:IsMouseClickEnabled() return self.click end
    function frame:IsMouseMotionEnabled() return self.motion end
    function frame:SetMouseClickEnabled(value) self.click = value end
    function frame:SetMouseMotionEnabled(value) self.motion = value end
    return setmetatable(frame, {__index = function(_, method)
        if method:match("^[A-Z]") then return noop end
    end})
end

local function withPlayer(body)
    local stock = widget()
    stock.click, stock.motion = true, true
    stock.PlayerFrameContainer = widget(stock)
    stock.PlayerFrameContent = widget(stock)
    local pet, stockCast = widget(stock), widget(stock)
    pet:SetMouseClickEnabled(true)
    local events, data, preview, inCombat
    local wallet, displayedMoney = 123456
    local registered = {}
    local ns = {
        db = {player = {enabled = true}},
        PlayerView = {Create = function()
            return {
                frame = {}, Render = function(update) data = update end,
                RenderMoney = function(amount) displayedMoney = amount end,
            }
        end},
        Preview = {IsEnabled = function() return preview == true end},
        UI = {Place = noop},
    }
    withGlobals({
        PlayerFrame = stock,
        PetFrame = pet,
        PlayerCastingBarFrame = stockCast,
        InCombatLockdown = function() return inCombat == true end,
        GetMoney = function() return wallet end,
        CreateFrame = function()
            events = widget()
            function events:RegisterEvent(event) registered[event] = true end
            return events
        end,
    }, function()
        loadAddon("Core/Read.lua", ns)
        loadAddon("Modules/Player/Controller.lua", ns)
        body(ns.Player, stock, pet, stockCast, function() return data end, function(value)
            preview = value
            ns.Player.Refresh()
        end, function(value)
            inCombat = value
            if not value then events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED") end
        end, function() return displayedMoney end, function(value)
            wallet = value
            assert(registered.PLAYER_MONEY, "player frame must listen for money changes")
            events.scripts.OnEvent(events, "PLAYER_MONEY")
        end)
    end)
end

test("player replacement keeps the native pet and attached cast bar usable", function()
    withPlayer(function(player, stock, pet, stockCast, data)
        player.Init()
        assert(pet:IsVisible() and pet:IsMouseClickEnabled(), "native pet menu must remain clickable")
        assert(stockCast:IsVisible(), "an attached stock cast bar must remain visible")
        assert(not stock.PlayerFrameContainer:IsVisible() and not stock.PlayerFrameContent:IsVisible(), "stock player art must be suppressed")
        assert(not stock:IsMouseClickEnabled() and not stock:IsMouseMotionEnabled(), "stock player hit area must not intercept the mouse")
        assert(data().visible)
        player.SetReplacementEnabled(false)
        assert(stock.PlayerFrameContainer:IsVisible() and stock.PlayerFrameContent:IsVisible(), "stock player art must return on opt-out")
        assert(stock:IsMouseClickEnabled() and stock:IsMouseMotionEnabled(), "stock player interaction must return on opt-out")
        assert(not data().visible)
    end)
end)

test("player preview preserves the pet without taking over stock visibility in combat", function()
    withPlayer(function(player, stock, pet, stockCast, data, preview, combat)
        player.SetReplacementEnabled(false)
        stock.PlayerFrameContent:Hide()
        stock:SetMouseMotionEnabled(false)
        player.Init()
        preview(true)
        assert(pet:IsVisible() and stockCast:IsVisible(), "the preview must keep the native pet and cast bar visible")
        assert(not stock.PlayerFrameContainer:IsVisible() and not data().visible)
        combat(true)
        preview(false)
        assert(not stock.PlayerFrameContainer:IsVisible() and not stock:IsMouseClickEnabled())
        combat(false)
        assert(stock.PlayerFrameContainer:IsVisible() and stock:IsMouseClickEnabled())
        assert(not stock.PlayerFrameContent:IsShown() and not stock:IsMouseMotionEnabled(), "restore the captured art and input states")
    end)
end)

test("opting out leaves stock player visibility under native or external ownership", function()
    withPlayer(function(player, stock)
        player.Init()
        stock:Hide()
        player.SetReplacementEnabled(false)
        assert(not stock:IsShown(), "an externally hidden PlayerFrame must stay hidden")
    end)
end)

test("player money updates at login and on wallet changes", function()
    withPlayer(function(player, _, _, _, data, _, _, money, changeMoney)
        player.Init()
        assert(money() == 123456, "player frame must read the character's balance on initialization")
        local before = data()
        changeMoney(125055)
        assert(money() == 125055 and data() == before, "the money event should update only the balance")
        changeMoney(0)
        assert(money() == 0, "a zero balance is valid")
        changeMoney(nil)
        assert(money() == nil, "an unreadable balance should clear the display")
    end)
end)

local function withCast(body)
    local stock = widget()
    stock:Hide()
    local active, preview, events, replacement, timer
    local inCombat = false
    local ns = {
        db = {castBar = {enabled = true}},
        L = {}, Theme = {},
        Preview = {IsEnabled = function() return preview == true end},
        UI = {Rect = function() return widget() end, Text = function() return widget() end, MakeMovable = noop, Place = noop},
    }
    local function nativeStart(kind)
        active = kind or "cast"
        stock.casting = active ~= "channel"
        stock.channeling = active == "channel"
        stock.fading = false
        stock:SetAlpha(1)
        stock:Show()
        local event = stock.channeling and "UNIT_SPELLCAST_CHANNEL_START" or "UNIT_SPELLCAST_START"
        if stock.scripts.OnEvent then stock.scripts.OnEvent(stock, event) end
        events.scripts.OnEvent(events, event)
    end
    local function nativeStop()
        local event = stock.channeling and "UNIT_SPELLCAST_CHANNEL_STOP" or "UNIT_SPELLCAST_STOP"
        -- Forever's native fade starts only while the bar is visible and has positive alpha.
        stock.fading = stock:IsVisible() and stock:GetAlpha() > 0
        stock.casting, stock.channeling, active = nil, nil, nil
        if stock.scripts.OnEvent then stock.scripts.OnEvent(stock, event) end
        events.scripts.OnEvent(events, event)
        if timer then
            local callback = timer
            timer = nil
            callback()
        end
    end
    stock.FadeOutAnim = {IsPlaying = function() return stock.fading end}
    local function finishFade()
        if not stock.fading then return end
        stock.fading = false
        stock:SetAlpha(0)
        stock:Hide()
    end
    function stock:HasVisibleFill()
        return self:IsVisible() and self:GetAlpha() > 0 and self:IsDrawLayerEnabled("ARTWORK")
    end
    withGlobals({
        InCombatLockdown = function() return inCombat end,
        GetTime = function() return 2 end,
        UnitCastingInfo = function()
            if active == "cast" then return "Fireball", "Fireball", 1, 1000, 4000 end
        end,
        UnitChannelInfo = function()
            if active == "channel" then return "Drain Life", "Drain Life", 1, 1000, 4000 end
        end,
        CreateFrame = function(kind, name)
            local frame = widget()
            if name == "ForeverUI_CastBar" then replacement = frame end
            events = frame
            return frame
        end,
        PlayerCastingBarFrame = stock,
        hooksecurefunc = function(object, method, callback)
            local original = object[method]
            object[method] = function(self, ...) original(self, ...); callback(self, ...) end
        end,
        C_Timer = {After = function(_, handler) timer = handler end},
    }, function()
        loadAddon("Core/Read.lua", ns)
        loadAddon("Modules/CastBar.lua", ns)
        ns.CastBar.Init()
        body(stock, replacement, nativeStart, nativeStop, finishFade, function(enabled)
            ns.db.castBar.enabled = enabled
            ns.CastBar.Refresh()
        end, function(value)
            preview = value
            ns.CastBar.Refresh()
        end, function() inCombat = true end)
    end)
end

test("disabling the replacement leaves a completed native cast hidden and permits the next cast", function()
    withCast(function(stock, replacement, start, stop, finishFade, enable)
        stock:DisableDrawLayer("HIGHLIGHT")
        start()
        assert(replacement:IsShown() and not stock:HasVisibleFill())
        stop()
        finishFade()
        enable(false)
        assert(not stock:HasVisibleFill() and not stock:IsShown(), "a completed stock cast must stay hidden")
        start()
        assert(stock:HasVisibleFill() and not replacement:IsShown())
        assert(not stock:IsDrawLayerEnabled("HIGHLIGHT"), "preserve a layer originally disabled by another owner")
    end)
end)

test("preview does not reveal a native cast finishing its fade", function()
    withCast(function(stock, replacement, start, stop, finishFade, _, preview)
        start("channel")
        stop()
        preview(true)
        assert(replacement:IsShown() and not stock:HasVisibleFill(), "preview must keep the completed cast masked during its fade")
        finishFade()
        start("channel")
        assert(stock:HasVisibleFill(), "the next real channel must use the native cast bar during preview")
    end)
end)

test("disabling the replacement preserves an active stock channel and its current alpha in combat", function()
    withCast(function(stock, replacement, start, _, _, enable, _, combat)
        combat()
        start("channel")
        assert(replacement:IsShown() and not stock:HasVisibleFill())
        stock:SetAlpha(0.75)
        assert(stock:GetAlpha() == 0.75, "the native bar must keep its own alpha while suppressed")
        enable(false)
        assert(stock:HasVisibleFill() and stock:GetAlpha() == 0.75 and not replacement:IsShown())
    end)
end)
