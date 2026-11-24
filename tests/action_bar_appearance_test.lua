local function withActionBars(callback)
    local state = {frames = {}, locked = false, grid = false, editMode = false, quickKeybind = false}
    local function alphaRegion(alpha)
        return {
            alpha = alpha,
            GetAlpha = function(self) return self.alpha end,
            SetAlpha = function(self, value) self.alpha = value end,
        }
    end

    local bar = {actionButtons = {}, BorderArt = alphaRegion(0.68), GetFrameLevel = function() return 3 end}
    function bar:AddButton(action, alpha)
        local button = alphaRegion(alpha or 1)
        button.action = action
        button.available = true
        button.GetFrameLevel = function() return 5 end
        button.HasAction = function(self) return self.action end
        self.actionButtons[#self.actionButtons + 1] = button
        return button
    end

    local dividers = {}
    bar.HorizontalDividersPool = {EnumerateActive = function() return pairs(dividers) end}
    function bar:UpdateDividers()
        local shown = 0
        for _, button in ipairs(self.actionButtons) do
            if button.shown then shown = shown + 1 end
        end
        for divider in pairs(dividers) do divider.shown = shown > 1 end
    end
    function bar:UpdateShownButtons()
        for _, button in ipairs(self.actionButtons) do
            button.shown = button.available and (state.grid or button.action ~= false or button.alwaysShow)
        end
        self:UpdateDividers()
    end
    local divider = alphaRegion(0.84)
    dividers[divider] = true

    function state:Send(event, ...)
        assert(self.eventFrame.events[event], event .. " wasn't registered")
        self.eventFrame.OnEvent(self.eventFrame, event, ...)
    end
    local callbacks = {}
    function state:Trigger(event)
        assert(callbacks[event], event .. " wasn't registered")
        callbacks[event]()
    end

    withGlobals({
        InCombatLockdown = function() return state.locked end,
        MainActionBar = bar,
        MultiBarBottomLeft = false,
        hooksecurefunc = function(object, method, hook)
            local original = object[method]
            object[method] = function(self, ...)
                original(self, ...)
                hook(self, ...)
            end
        end,
        EventRegistry = {RegisterCallback = function(_, event, handler) callbacks[event] = handler end},
        EditModeManagerFrame = {IsEditModeActive = function() return state.editMode end},
        KeybindFrames_InQuickKeybindMode = function() return state.quickKeybind end,
        CreateFrame = function(kind, name, parent, template)
            assert(kind == "Frame" and not name and not template)
            if not parent then
                local frame = {events = {}}
                function frame:RegisterEvent(event) self.events[event] = true end
                function frame:SetScript(event, handler) self[event] = handler end
                state.eventFrame = frame
                return frame
            end
            assert(not state.locked, "creating an appearance frame must wait until combat ends")
            local frame = alphaRegion(1)
            frame.parent, frame.textures, frame.shown = parent, {}, true
            function frame:SetFrameLevel(value) self.level = value end
            function frame:EnableMouse(value) self.mouse = value end
            function frame:SetPoint() end
            function frame:SetAllPoints() end
            function frame:Show() self.shown = true end
            function frame:Hide() self.shown = false end
            function frame:CreateTexture(_, layer)
                local texture = alphaRegion(1)
                texture.layer = layer
                function texture:SetColorTexture(...) self.color = {...} end
                function texture:SetPoint() end
                function texture:SetAllPoints() end
                function texture:SetHeight() end
                function texture:SetWidth() end
                self.textures[#self.textures + 1] = texture
                return texture
            end
            state.frames[#state.frames + 1] = frame
            return frame
        end,
    }, function()
        local ns = {db = {actionBars = {enabled = false, opacity = 0}}}
        loadAddon("Core/CombatQueue.lua", ns)
        loadAddon("Core/Read.lua", ns)
        loadAddon("UI/Theme.lua", ns)
        loadAddon("UI/Widgets.lua", ns)
        loadAddon("Modules/ActionBars/Appearance.lua", ns)
        callback(ns, state, bar, divider)
    end)
end

test("action bar appearance gives native bars a separate tray and restores the stock art", function()
    withActionBars(function(ns, state, main)
        local button = main:AddButton(true)
        local frames, art = state.frames, main.BorderArt
        local setAlpha = art.SetAlpha
        function art:SetAlpha(value)
            assert(not state.locked)
            setAlpha(self, value)
        end

        ns.ActionBars.Init()
        assert(#frames == 0 and art.alpha == 0.68)
        ns.db.actionBars.enabled = true
        state.locked = true
        ns.ActionBars.Refresh()
        assert(#frames == 0 and art.alpha == 0.68)
        state.locked = false
        assert(ns.CombatQueue.Flush())
        assert(#frames == 2 and art.alpha == 0)

        local tray, rim = frames[1], frames[2]
        assert(tray.shown and tray.parent == main and tray.ignoreInLayout and tray.mouse == false)
        assert(tray.level == main:GetFrameLevel() and tray.textures[1].alpha == 0)
        assert(tray.textures[6].color[4] >= 0.6, "tray trim stays visible at zero opacity")
        assert(rim.shown and rim.parent == button and rim.mouse == false and rim.level > button:GetFrameLevel())

        ns.db.actionBars.opacity = 0.7
        ns.ActionBars.Refresh()
        assert(#frames == 2 and tray.textures[1].alpha == 0.7)

        _G.MultiBarBottomLeft = {actionButtons = {button}, GetFrameLevel = main.GetFrameLevel}
        state:Send("ADDON_LOADED", "Blizzard_ActionBar")
        assert(#frames == 3)

        ns.db.actionBars.enabled = false
        ns.ActionBars.Refresh()
        for _, frame in ipairs(frames) do assert(not frame.shown) end
        assert(art.alpha == 0.68)
    end)
end)

test("hidden empty slots follow native action changes and preserve button positions in combat", function()
    withActionBars(function(ns, state, bar, divider)
        local filled = bar:AddButton(true, 0.76)
        local empty = bar:AddButton(false, 0.86)
        empty.alwaysShow = true
        local unknown = bar:AddButton(nil, 0.57)
        bar:UpdateShownButtons()
        ns.db.actionBars.enabled = true
        ns.db.actionBars.hideEmpty = true
        ns.ActionBars.Init()

        assert(empty.alpha == 0 and empty.shown, "fade the empty button while retaining its native presentation state")
        assert(state.frames[1].alpha == 0 and divider.alpha == 0, "remove the full tray and native divider behind empty slots")
        assert(filled.alpha == 0.76 and unknown.alpha == 0.57)
        state.locked = true
        -- A native page swap updates button occupancy before laying out that page.
        filled.action, empty.action = false, true
        bar:UpdateShownButtons()
        assert(filled.alpha == 0 and empty.alpha == 0.86 and empty.shown)
        assert(bar.actionButtons[1] == filled and bar.actionButtons[2] == empty)
    end)
end)

test("native drag grid, Edit Mode, and Quick Keybind reveal empty-slot art", function()
    withActionBars(function(ns, state, bar, divider)
        local empty = bar:AddButton(false, 0.86)
        local unavailable = bar:AddButton(false)
        unavailable.available = false
        bar:AddButton(true)
        bar:UpdateShownButtons()
        ns.db.actionBars.enabled = true
        ns.db.actionBars.hideEmpty = true
        ns.ActionBars.Init()

        state.grid = true
        state:Send("ACTIONBAR_SHOWGRID")
        bar:UpdateShownButtons()
        assert(empty.alpha == 0.86 and empty.shown and not unavailable.shown)
        assert(state.frames[1].alpha == 1 and divider.alpha == 0.84)
        state.grid = false
        bar:UpdateShownButtons()
        state:Send("ACTIONBAR_HIDEGRID")
        assert(empty.alpha == 0 and not empty.shown and state.frames[1].alpha == 0)

        state.editMode = true
        state:Trigger("EditMode.Enter")
        assert(empty.alpha == 0.86 and state.frames[1].alpha == 1)
        state.editMode = false
        state:Trigger("EditMode.Exit")
        assert(empty.alpha == 0 and state.frames[1].alpha == 0)

        state.quickKeybind = true
        state:Trigger("QuickKeybindFrame.QuickKeybindModeEnabled")
        assert(empty.alpha == 0.86)
        state.quickKeybind = false
        state:Trigger("QuickKeybindFrame.QuickKeybindModeDisabled")
        assert(empty.alpha == 0)
    end)
end)

test("turning off empty-slot hiding restores owned alphas and respects external changes", function()
    withActionBars(function(ns, state, bar, divider)
        local empty = bar:AddButton(false, 0.83)
        local externallyHidden = bar:AddButton(false, 0)
        local externallyUpdated = bar:AddButton(false, 0.9)
        empty.alwaysShow, externallyHidden.alwaysShow, externallyUpdated.alwaysShow = true, true, true
        bar:UpdateShownButtons()
        ns.db.actionBars.enabled = true
        ns.db.actionBars.hideEmpty = true
        ns.ActionBars.Init()

        assert(empty.alpha == 0 and externallyUpdated.alpha == 0 and externallyHidden.alpha == 0)
        externallyUpdated:SetAlpha(0.42)
        bar:UpdateShownButtons()
        assert(externallyUpdated.alpha == 0.42)
        ns.db.actionBars.hideEmpty = false
        ns.ActionBars.Refresh()
        assert(empty.alpha == 0.83 and externallyHidden.alpha == 0 and externallyUpdated.alpha == 0.42)
        assert(state.frames[1].shown and state.frames[1].alpha == 1 and divider.alpha == 0.84)

        ns.db.actionBars.hideEmpty = true
        ns.ActionBars.Refresh()
        ns.db.actionBars.enabled = false
        ns.ActionBars.Refresh()
        assert(empty.alpha == 0.83 and externallyUpdated.alpha == 0.42 and divider.alpha == 0.84)
        assert(not state.frames[1].shown and bar.BorderArt.alpha == 0.68)
    end)
end)
