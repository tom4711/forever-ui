test("action bar appearance gives native bars a separate tray and restores the stock art", function()
    local locked = false
    local button = {GetFrameLevel = function() return 5 end}
    local art = {alpha = 0.68}
    function art:GetAlpha() return self.alpha end
    function art:SetAlpha(value)
        assert(not locked)
        self.alpha = value
    end
    local main = {actionButtons = {button}, BorderArt = art, GetFrameLevel = function() return 3 end}
    local frames = {}
    local eventFrame
    withGlobals({
        InCombatLockdown = function() return locked end,
        MainActionBar = main,
        MultiBarBottomLeft = false,
        CreateFrame = function(kind, name, parent, template)
            assert(kind == "Frame" and not name and not template)
            if not parent then
                eventFrame = {RegisterEvent = function() end, SetScript = function(self, event, callback) self[event] = callback end}
                return eventFrame
            end
            assert(not locked, "creating an appearance frame must wait until combat ends")
            local frame = {parent = parent, textures = {}, shown = true}
            function frame:SetFrameLevel(value) self.level = value end
            function frame:EnableMouse(value) self.mouse = value end
            function frame:SetPoint() end
            function frame:SetAllPoints() end
            function frame:Show() self.shown = true end
            function frame:Hide() self.shown = false end
            function frame:CreateTexture(_, layer)
                local texture = {layer = layer}
                function texture:SetAlpha(value) self.alpha = value end
                function texture:SetColorTexture(...) self.color = {...} end
                function texture:SetPoint() end
                function texture:SetAllPoints() end
                function texture:SetHeight() end
                function texture:SetWidth() end
                self.textures[#self.textures + 1] = texture
                return texture
            end
            frames[#frames + 1] = frame
            return frame
        end,
    }, function()
        local ns = {db = {actionBars = {enabled = false, opacity = 0}}}
        loadAddon("Core/CombatQueue.lua", ns)
        loadAddon("Core/Read.lua", ns)
        loadAddon("UI/Theme.lua", ns)
        loadAddon("UI/Widgets.lua", ns)
        loadAddon("Modules/ActionBars/Appearance.lua", ns)
        ns.ActionBars.Init()
        assert(#frames == 0 and art.alpha == 0.68)
        ns.db.actionBars.enabled = true
        locked = true
        ns.ActionBars.Refresh()
        assert(#frames == 0 and art.alpha == 0.68)
        locked = false
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
        eventFrame.OnEvent(eventFrame, "ADDON_LOADED", "Blizzard_ActionBar")
        assert(#frames == 3)

        ns.db.actionBars.enabled = false
        ns.ActionBars.Refresh()
        for _, frame in ipairs(frames) do assert(not frame.shown) end
        assert(art.alpha == 0.68)
    end)
end)
