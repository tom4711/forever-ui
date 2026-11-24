test("party layout previews without touching stock and restores stock on entering a raid", function()
    local locked, inRaid = false, false
    local original = {}
    local stock = {parent = original}
    function stock:GetParent() return self.parent end
    function stock:SetParent(parent) assert(not locked); self.parent = parent end
    local wick = {parent = original}
    local eventFrame, live, demo
    withGlobals({
        UIParent = {},
        PartyFrame = stock,
        CompactPartyFrame = false,
        WicksUI = wick,
        IsInGroup = function() return true end,
        IsInRaid = function() return inRaid end,
        InCombatLockdown = function() return locked end,
        CreateFrame = function()
            local frame = {Hide = function(self) self.visible = false end, registered = {},
                RegisterEvent = function(self, name) self.registered[name] = true end,
                UnregisterEvent = function(self, name) self.registered[name] = nil end,
                SetScript = function(self, key, handler) self[key] = handler end}
            if not eventFrame then eventFrame = frame end
            return frame
        end,
    }, function()
        local ns = {
            UI = {Place = function(_, key) assert(key == "party" and not locked) end},
            PartyView = {Create = function(preview)
                assert(not locked)
                local view = {frame = {Hide = function(self) self.visible = false end}}
                function view.SetLive(enabled) assert(not locked); view.live = enabled end
                function view.ApplySettings(config) assert(not locked); view.compact = config.compact end
                function view.Render(event, unit) view.event, view.unit = event, unit end
                function view.ShowPreview() view.frame.visible = true end
                if preview then demo = view else live = view end
                return view
            end},
        }
        loadAddon("Core/Read.lua", ns)
        loadAddon("Core/Settings.lua", ns)
        loadAddon("Core/CombatQueue.lua", ns)
        loadAddon("Modules/Party/Controller.lua", ns)
        ns.db = ns.Settings.Load(nil)
        assert(ns.db.party.enabled == false and ns.db.party.replaceBlizzard == false)
        ns.Party.Init()
        assert(not live and stock.parent == original)
        assert(not eventFrame.registered.UNIT_IN_RANGE_UPDATE)

        ns.Party.SetPreview(true)
        ns.Party.Refresh()
        assert(demo.frame.visible and not live and stock.parent == original)
        ns.Party.SetPreview(false)
        ns.db.party.enabled = true
        ns.db.party.replaceBlizzard = true
        ns.Party.Refresh()
        assert(live.live and not demo.frame.visible and stock.parent ~= original)
        assert(wick.parent == original and eventFrame.registered.UNIT_IN_RANGE_UPDATE)

        locked = true
        eventFrame.OnEvent(eventFrame, "UNIT_HEALTH", "party2")
        assert(live.event == "UNIT_HEALTH" and live.unit == "party2")
        eventFrame.OnEvent(eventFrame, "UNIT_HEALTH", "raid10")
        assert(live.unit == "party2")
        eventFrame.OnEvent(eventFrame, "UNIT_IN_RANGE_UPDATE", "party1")
        assert(live.event == "UNIT_IN_RANGE_UPDATE" and live.unit == "party1")
        ns.db.party.compact = true
        ns.Party.Refresh()
        assert(live.compact ~= true)
        inRaid = true
        eventFrame.OnEvent(eventFrame, "GROUP_ROSTER_UPDATE")
        assert(stock.parent ~= original and ns.CombatQueue.Flush() == false)
        locked = false
        assert(ns.CombatQueue.Flush() and stock.parent == original and wick.parent == original)
        assert(live.compact == true and not eventFrame.registered.UNIT_IN_RANGE_UPDATE)

        inRaid = false
        ns.Party.Refresh()
        assert(stock.parent ~= original)
        ns.db.party.enabled = false
        ns.Party.Refresh()
        assert(not live.live and stock.parent == original)
    end)
end)

test("Priest Mouseover actions use the learned rank and leave the current target alone", function()
    local ns = {}
    loadAddon("Core/FriendlyBuffs.lua", ns)
    loadAddon("Modules/Priest/Model.lua", ns)
    local macros = {}
    for _, entry in ipairs(ns.PriestModel.Actions({[17] = true, [592] = true, [139] = true}).macros) do
        macros[entry.key] = entry
    end
    assert(macros.shieldMouseover.mode == "mouseover" and macros.shieldMouseover.spellID == 592)
    assert(macros.renewMouseover.mode == "mouseover" and macros.renewMouseover.spellID == 139)
    assert(macros.shieldSelf.mode == "self" and macros.renewSelf.mode == "self")
    local mouseover = ns.FriendlyBuffs.MouseoverMacro
    assert(mouseover("Machtwort: Schild") == "/cast [@mouseover,help,nodead] Machtwort: Schild")
    assert(mouseover("bad\n/target player") == nil)
end)

local function withPartyView(body)
    local frames, widgets = {}, {}
    local function makeWidget(kind, _, parent, template)
        if kind == "AuraContainer" then error("Lua aura fallback") end
        local widget = {kind = kind, parent = parent, template = template or false, shown = true,
            alpha = 1, points = {}, scripts = {}}
        local noop = function() end
        local methods = {
            SetPoint = function(self, point, ...) self.points[point] = {...} end,
            ClearAllPoints = function(self) self.points = {} end,
            SetSize = function(self, width, height) self.width, self.height = width, height end,
            SetHeight = function(self, height) self.height = height end,
            SetAlpha = function(self, alpha) self.alpha = alpha end,
            SetText = function(self, value) self.text = value end,
            SetFormattedText = function(self, format, ...) self.text = format:format(...) end,
            SetShown = function(self, shown) self.shown = shown end,
            Show = function(self) self.shown = true end,
            Hide = function(self) self.shown = false end,
            IsShown = function(self) return self.shown end,
            SetScript = function(self, key, callback) self.scripts[key] = callback end,
            CreateTexture = function(self) return makeWidget("Texture", nil, self) end,
            CreateFontString = function(self) return makeWidget("FontString", nil, self) end,
        }
        setmetatable(widget, {__index = function(_, method) return methods[method] or noop end})
        if kind == "Button" then frames[#frames + 1] = widget end
        widgets[#widgets + 1] = widget
        return widget
    end
    local state = {exists = true, connected = true, visible = true, dead = false, target = "target", auraReads = 0}
    local tooltip = {
        SetOwner = function(self, owner) self.owner, self.line = owner, nil end,
        SetUnit = function(self, unit) self.unit = unit; return true end,
        IsOwned = function(self, owner) return owner == self.owner end,
        AddLine = function(self, line) self.line = line end,
        Hide = function(self) self.owner = nil end,
        Show = function() end,
    }
    withGlobals({
        CreateFrame = makeWidget, UIParent = {}, GetLocale = function() return "enUS" end,
        SecureUnitButton_OnLoad = function(button, unit) button.secureUnit = unit end,
        RegisterUnitWatch = function() end, UnregisterUnitWatch = function() end,
        RegisterStateDriver = function() end, UnregisterStateDriver = function() end,
        UnitExists = function(unit) return state.exists and unit == "party1" end,
        UnitHealth = function() return 45 end, UnitHealthMax = function() return 60 end,
        UnitPower = function() return 30 end, UnitPowerMax = function() return 95 end,
        UnitIsConnected = function() return state.connected end,
        UnitIsVisible = function() return state.visible end,
        UnitIsDeadOrGhost = function() return state.dead end,
        UnitInRange = function() return state.inRange, state.rangeChecked end,
        UnitName = function() return "Tavin" end,
        UnitClass = function() return "Priest", state.class or "PRIEST" end,
        UnitGroupRolesAssigned = function() return "HEALER" end,
        IsPlayerSpell = function(id) return id == state.learned end,
        issecretvalue = function(value) return value ~= nil and value == state.secret end,
        C_Secrets = {ShouldAurasBeSecret = function() return state.aurasSecret == true end},
        C_UnitAuras = {GetAuraDataByIndex = function(_, index, filter)
            if filter ~= "HELPFUL" then return nil end
            state.auraReads = state.auraReads + 1
            if state.auraError then error("unknown auras") end
            return (state.auras or {})[index]
        end},
        GameTooltip = tooltip,
        TargetUnit = function(unit) state.target = unit end,
    }, function()
        local ns = {db = {party = {}}}
        for _, path in ipairs({"Locales.lua", "Core/Read.lua", "Core/Format.lua", "UI/Theme.lua", "UI/Widgets.lua",
            "Modules/Priest/Model.lua", "Modules/Paladin/Model.lua", "Modules/ClassSupport.lua", "Modules/Party/View.lua"}) do
            loadAddon(path, ns)
        end
        body(ns, state, frames, widgets, tooltip)
    end)
end

test("party settings resize the secure cards, reclaim portrait space, and preview the same layout", function()
    withPartyView(function(ns, _, frames, widgets)
        local live = ns.PartyView.Create(false)
        live.SetLive(true)
        local card = frames[1]
        local name, health, track, portrait
        live.Render()
        for _, widget in ipairs(widgets) do
            if widget.parent == card then
                if widget.text == "Tavin" then name = widget end
                if widget.kind == "StatusBar" and not health then health = widget end
                if widget.kind == "Texture" and widget.height == 11 then track = widget end
                if widget.kind == "Frame" and widget.width == 38 then portrait = widget end
            end
        end
        local normalHeight, normalLeft = card.height, name.points.TOPLEFT[1]
        assert(card.secureUnit == "party1" and portrait.shown and health and track)
        local normalTrackHeight = track.height
        ns.db.party.compact, ns.db.party.showPortrait = true, false
        live.ApplySettings(ns.db.party)
        assert(card.height < normalHeight and track.height < normalTrackHeight, "compact cards should have slimmer health bars")
        assert(not portrait.shown and name.points.TOPLEFT[1] < normalLeft, "text should use the vacated portrait space")
        local compactHeight = card.height
        local demo = ns.PartyView.Create(true)
        demo.ApplySettings(ns.db.party)
        demo.ShowPreview()
        assert(frames[5].height == compactHeight and not frames[5].template and not frames[5].scripts.OnEnter)
        live.ApplySettings({})
        assert(card.height == normalHeight and track.height == normalTrackHeight and portrait.shown and card.secureUnit == "party1")
    end)
end)

test("party cards clear range dimming whenever the range is unchecked, secret, or stale", function()
    withPartyView(function(ns, state, frames)
        local live = ns.PartyView.Create(false)
        live.SetLive(true)
        local card = frames[1]
        state.inRange, state.rangeChecked = false, true
        live.Render()
        assert(card.alpha < 1, "confirmed out-of-range party members should dim")
        state.rangeChecked = false
        live.Render("UNIT_IN_RANGE_UPDATE", "party1")
        assert(card.alpha == 1)
        state.secret = {}
        state.inRange, state.rangeChecked = state.secret, true
        live.Render("UNIT_IN_RANGE_UPDATE", "party1")
        assert(card.alpha == 1)
        state.inRange = false
        live.Render("UNIT_IN_RANGE_UPDATE", "party1")
        assert(card.alpha < 1)
        state.connected = false
        live.Render("UNIT_CONNECTION", "party1")
        assert(card.alpha == 1)
        state.connected = true
        live.Render("UNIT_CONNECTION", "party1")
        assert(card.alpha < 1)
        state.exists = false
        live.Render()
        assert(card.alpha == 1)
    end)
end)

test("party hover exposes the native unit without targeting it and reports a confirmed missing learned buff", function()
    withPartyView(function(ns, state, frames, widgets, tooltip)
        ns.L.PARTY_MISSING_BUFF = "Group buff missing"
        ns.db.party.showMissingBuff = true
        local live = ns.PartyView.Create(false)
        live.SetLive(true)
        live.ApplySettings(ns.db.party)
        local card = frames[1]
        live.Render()
        assert(state.auraReads == 0, "unlearned spells should not trigger a helpful aura scan")
        state.learned = 1243
        live.Render("SPELLS_CHANGED")
        card.scripts.OnEnter(card)
        assert(card.unit == "party1" and tooltip.unit == "party1" and state.target == "target")
        assert(tooltip.line == ns.L.PARTY_MISSING_BUFF)
        local mark
        for _, widget in ipairs(widgets) do
            if widget.parent == card and widget.text == "•" then mark = widget end
        end
        assert(mark and mark.shown)
        state.auras = {{spellId = 21564}}
        live.Render("UNIT_AURA", "party1")
        assert(not mark.shown, "a group-cast rank of Fortitude should cover the party member")
        assert(tooltip.line == nil, "the native unit tooltip should clear the stale buff hint")
        card.scripts.OnLeave(card)
        assert(tooltip.owner == nil)
        state.auras = {}
        live.Render("UNIT_AURA", "party1")
        assert(mark.shown)
        state.aurasSecret = true
        live.Render("UNIT_AURA", "party1")
        assert(not mark.shown)
        state.aurasSecret, state.secret = false, {}
        state.auras = {{spellId = state.secret}}
        live.Render("UNIT_AURA", "party1")
        assert(not mark.shown)
        state.auras, state.auraError = {}, true
        live.Render("UNIT_AURA", "party1")
        assert(not mark.shown)
        state.auraError, state.visible = false, false
        live.Render("UNIT_IN_RANGE_UPDATE", "party1")
        assert(not mark.shown)
        state.visible = true
        live.Render("UNIT_IN_RANGE_UPDATE", "party1")
        assert(mark.shown)
        state.exists = false
        live.Render()
        assert(not mark.shown)
    end)
end)

test("party buff hints accept equivalent party-cast ranks of learned class buffs", function()
    withPartyView(function(ns, state, frames, widgets)
        local live = ns.PartyView.Create(false)
        live.SetLive(true)
        live.ApplySettings({showMissingBuff = true})
        local mark
        for _, widget in ipairs(widgets) do
            if widget.parent == frames[1] and widget.text == "•" then mark = widget end
        end
        assert(mark, "the missing buff display should be present on each card")
        for _, spec in ipairs({{"MAGE", 1459, 23028}, {"DRUID", 1126, 21849}, {"PALADIN", 19742, 25894}}) do
            state.class, state.learned, state.auras = spec[1], spec[2], {}
            live.Render("SPELLS_CHANGED")
            assert(mark.shown, "a missing learned buff should be indicated for " .. spec[1])
            state.auras = {{spellId = spec[3]}}
            live.Render("UNIT_AURA", "party1")
            assert(not mark.shown, "the party-cast rank should cover the member for " .. spec[1])
        end
    end)
end)
