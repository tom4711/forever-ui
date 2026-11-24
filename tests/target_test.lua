test("target frame clears its destination and follows changes to the target's target", function()
    local selected, destination = false, "Bear"
    local playerTarget, selfTarget = false, false
    local targetClass
    local restricted = {}
    local helpful, harmful = "Fortitude", "Shadow Word: Pain"
    local registered, events = {}, {}
    local name, isPlayer, buffs, debuffs, nativeFallback, debuffsRestricted, ownAuraTimers
    local threat, threatPercent
    local fighting = false
    local frame = {SetScript = function(self, key, callback) self[key] = callback end}
    function events:RegisterEvent() end
    function events:RegisterUnitEvent(event, ...) registered[event] = {...} end
    function events:SetScript(key, callback) self[key] = callback end

    withGlobals({
        TargetFrame = false,
        CreateFrame = function() return events end,
        InCombatLockdown = function() return false end,
        UnitExists = function(unit) return unit == "target" and selected or nil end,
        UnitName = function(unit)
            if unit == "targettarget" then return destination end
            return "Wolf"
        end,
        issecretvalue = function(value) return value == restricted end,
        UnitIsUnit = function(first, second)
            if first == "target" and second == "player" then return selfTarget end
            return first == "targettarget" and second == "player" and destination == "Player"
        end,
        UnitIsPlayer = function(unit) return unit == "target" and playerTarget end,
        UnitClass = function(unit)
            assert(unit == "target")
            return "Priesterin", "PRIEST"
        end,
        UnitCanAttack = function() return fighting end,
        UnitAffectingCombat = function() return fighting end,
        UnitDetailedThreatSituation = function()
            if fighting then return false, 0, threatPercent, 0, 800 end
        end,
        C_UnitAuras = {GetAuraDataByIndex = function(unit, index, filter)
            assert(unit == "target")
            local aura = filter == "HELPFUL" and helpful or harmful
            if index == 1 and type(aura) == "table" then return aura end
            if index == 1 and aura then return {name = aura} end
        end},
    }, function()
        local noop = function() end
        local ns = {
            db = {target = {enabled = true}},
            UI = {Place = noop},
            TargetView = {Create = function()
                return {
                    frame = frame, SetUnitWatch = noop, Health = noop, Cast = noop, AuraLimit = 10,
                    Identity = function(_, _, className) targetClass = className end,
                    NativeBuffs = true, NativeDebuffs = true, RefreshNativeAuras = noop,
                    Buffs = function(auras, blocked) buffs, nativeFallback = auras, blocked end,
                    Threat = function(value) threat = value end,
                    Debuffs = function(auras, blocked, timers)
                        debuffs, debuffsRestricted, ownAuraTimers = auras, blocked, timers
                    end,
                    Destination = function(value, player) name, isPlayer = value, player end,
                }
            end},
        }
        loadAddon("Core/Read.lua", ns)
        loadAddon("Modules/Target/Model.lua", ns)
        loadAddon("Modules/Target/Controller.lua", ns)
        ns.Target.Init()
        assert(name == nil and #buffs == 0 and #debuffs == 0)
        selected = true
        events.OnEvent(events, "PLAYER_TARGET_CHANGED")
        assert(registered.UNIT_TARGET[1] == "target" and registered.UNIT_NAME_UPDATE[2] == "targettarget")
        assert(registered.UNIT_AURA and registered.UNIT_AURA[1] == "target")
        assert(buffs[1].name == "Fortitude" and debuffs[1].name == "Shadow Word: Pain")
        assert(ownAuraTimers == true, "own debuff timers default to enabled")
        harmful = {name = "Shadow Word: Pain", isFromPlayerOrPlayerPet = true, duration = restricted,
            expirationTime = restricted}
        events.OnEvent(events, "UNIT_AURA", "target")
        assert(debuffs[1].own and debuffsRestricted, "native timers must receive restricted own durations")
        ns.db.target.showOwnAuraTimers = false
        ns.Target.Refresh()
        assert(ownAuraTimers == false, "turning off timers must update the displayed target")
        assert(not debuffsRestricted, "readable aura icons can still use the regular row with timers off")
        assert(name == "Bear" and not isPlayer)
        assert(targetClass == nil)

        playerTarget = true
        events.OnEvent(events, "PLAYER_TARGET_CHANGED")
        assert(targetClass == "Priesterin")
        selfTarget = true
        events.OnEvent(events, "PLAYER_TARGET_CHANGED")
        assert(targetClass == nil)
        selfTarget = false
        events.OnEvent(events, "PLAYER_TARGET_CHANGED")
        assert(targetClass == "Priesterin")
        playerTarget = false
        events.OnEvent(events, "PLAYER_TARGET_CHANGED")
        assert(targetClass == nil)

        helpful = restricted
        events.OnEvent(events, "UNIT_AURA", "target")
        assert(nativeFallback and #buffs == 0)
        helpful = {name = "Fortitude", duration = restricted, expirationTime = restricted}
        events.OnEvent(events, "UNIT_AURA", "target")
        assert(nativeFallback and buffs[1].name == "Fortitude", "restricted buff times use the native caption")
        helpful = "Fortitude"
        events.OnEvent(events, "UNIT_AURA", "target")
        assert(not nativeFallback and buffs[1].name == "Fortitude")

        destination = "Mage"
        frame.OnUpdate(frame, 0.25)
        assert(name == "Mage")

        destination = "Player"
        events.OnEvent(events, "UNIT_TARGET", "target")
        assert(name == "Player" and isPlayer)

        destination = nil
        events.OnEvent(events, "UNIT_TARGET", "target")
        assert(name == nil and not isPlayer)

        destination = "Bear"
        events.OnEvent(events, "UNIT_TARGET", "target")
        assert(name == "Bear")
        fighting = true
        threatPercent = 18
        events.OnEvent(events, "PLAYER_REGEN_DISABLED")
        assert(threat and threat.percent == 18)
        threatPercent = 92
        events.OnEvent(events, "UNIT_THREAT_LIST_UPDATE", "target")
        assert(threat.percent == 92 and threat.state == "warning")
        ns.db.target.showThreat = false
        ns.Target.Refresh()
        assert(threat == nil)
        ns.db.target.showThreat = true
        events.OnEvent(events, "UNIT_THREAT_SITUATION_UPDATE", "player")
        assert(threat and threat.percent == 92)
        selected = false
        events.OnEvent(events, "PLAYER_TARGET_CHANGED")
        assert(name == nil and not isPlayer and threat == nil)
        assert(#buffs == 0 and #debuffs == 0)
    end)
end)

test("interrupt cue pairs the cast and button only when the action can be used", function()
    local usable, active, inRange = true, false, true
    local legacyRange
    local protected = {locked = true}
    local driver = {SetScript = function(self, key, callback) self[key] = callback end}

    withGlobals({
        CreateFrame = function() return driver end,
        issecretvalue = function(value) return value == protected end,
        IsSpellInRange = function(name, unit)
            assert(name == "Tritt" and unit == "target")
            return legacyRange
        end,
        C_Spell = {
            IsSpellUsable = function() return usable end,
            GetSpellCooldown = function() return {duration = protected, isActive = active, isEnabled = true} end,
            IsSpellInRange = function() return inRange end,
            GetSpellName = function() return "Tritt" end,
        },
    }, function()
        local ns = {
            UI = {ActionOutline = function(frame)
                frame.line = {
                    SetVertexColor = function() end,
                    SetAlpha = function(self, alpha) self.alpha = alpha end,
                    SetShown = function(self, shown) self.shown = shown end,
                    SetAlphaFromBoolean = function(self, locked, yes, no)
                        assert(locked == protected)
                        self.alpha = locked.locked and yes or no
                    end,
                }
                return {frame.line}
            end},
            Theme = {goldLight = {1, 0.8, 0.4}},
        }
        loadAddon("Core/Read.lua", ns)
        loadAddon("UI/InterruptCue.lua", ns)
        local button = {IsVisible = function() return true end,
            HookScript = function(self, key, handler) self[key] = handler end}
        local castBar = {}
        local cue = ns.InterruptCue
        local outline = cue.Outline(castBar)
        cue.Track(button, 1766)

        local function expect(shown)
            assert((button.line.shown and button.line.alpha > 0) == shown)
            assert((castBar.line.shown and castBar.line.alpha > 0) == shown)
        end
        local function tick() driver.OnUpdate(driver, 0.2) end

        cue.SetCast(outline, false)
        expect(true)
        active = true
        tick()
        expect(false)
        active, usable = false, false
        tick()
        expect(false)
        usable, inRange = true, false
        tick()
        expect(false)
        inRange = nil
        tick()
        expect(false)
        legacyRange = 1
        tick()
        expect(true)
        inRange = false
        tick()
        expect(false)
        inRange, legacyRange = protected, nil
        tick()
        expect(false)
        inRange = true
        cue.SetCast(outline, true)
        expect(false)
        assert(driver.OnUpdate == nil)

        cue.SetCast(outline, protected)
        expect(false)
        protected.locked = false
        tick()
        expect(true)
        button.OnHide(button)
        tick()
        expect(false)
        cue.SetCast(outline)
        assert(driver.OnUpdate == nil)
    end)
end)

local function withTargetAuraView(native, body)
    local widgets, groups = {}, {}
    local noop = function() end
    local methods = {
        CreateTexture = function(self) return CreateFrame("Texture", nil, self) end,
        SetText = function(self, value) self.text = value end,
        SetFormattedText = function(self, format, ...) self.text = format:format(...) end,
        SetTexture = function(self, value) self.texture = value end,
        SetValue = function(self, value) self.value = value end,
        SetStatusBarColor = function(self, ...) self.color = {...} end,
        SetScript = function(self, key, callback) self[key] = callback end,
        GetFrameLevel = function() return 1 end,
        Hide = function(self) self.shown = false end,
        Show = function(self) self.shown = true end,
        SetShown = function(self, value) self.shown = value end,
        IsShown = function(self) return self.shown end,
        SetDurationText = function(self, label) self.durationLabel = label end,
        SetDurationCooldown = function(self, cooldown) self.durationCooldown = cooldown end,
        SetHideCountdownNumbers = function(self, hidden) self.hideCountdownNumbers = hidden end,
        SetSize = function(self, width, height) self.width, self.height = width, height end,
        SetPoint = function(self, ...) self.point = {...} end,
        SetClipsChildren = function(self, clipped) self.clipped = clipped end,
        SetFlowLayoutMaximumLineSize = function(self, width) self.lineWidth = width end,
        AddAuraGroup = function(self, _, filter, options)
            local button = CreateFrame("AuraButton", nil, self)
            options.initializeFrame(button)
            groups[filter] = {container = self, button = button, layoutIndex = options.layout.layoutIndex}
        end,
    }
    local function create(kind, _, parent)
        local widget = setmetatable({kind = kind, parent = parent, shown = true}, {
            __index = function(_, key)
                if key:match("^[A-Z]") then return methods[key] or noop end
            end,
        })
        widgets[#widgets + 1] = widget
        return widget
    end
    local now = 100
    local ns = {
        L = {TARGET_THREAT = "Bedrohung", TARGET_THREAT_ON_YOU = "Aggro bei dir"},
        Theme = {teal = {0, 0.7, 0.7}, goldLight = {1, 0.8, 0.4}, good = {0.4, 0.8, 0.4}},
        InterruptCue = {Outline = noop},
        UI = {
            CreatePanel = function(parent) return create("Frame", nil, parent) end,
            Text = function(parent) return create("FontString", nil, parent) end,
            Rect = function(parent) return create("Texture", nil, parent) end,
            MakeMovable = noop, DecorateActionButton = noop, DecorateGroup = noop,
            ActionOutline = noop, SetActionState = noop,
        },
    }
    withGlobals({
        CreateFrame = create, SecureUnitButton_OnLoad = noop,
        C_AddOns = native and {IsAddOnLoaded = function() return true end, LoadAddOn = noop} or false,
        GetTime = function() return now end,
        GameTooltip = {IsOwned = function() return false end},
    }, function()
        loadAddon("Core/Read.lua", ns)
        loadAddon("Modules/Target/Model.lua", ns)
        loadAddon("Modules/Target/View.lua", ns)
        body(ns.TargetView.Create("TestTarget", not native), widgets, groups, function(value) now = value end)
    end)
end

test("target debuff countdown only labels the player's timed effects and clears on reuse", function()
    withTargetAuraView(false, function(view, widgets, _, time)
        local own = {icon = 136207, own = true, duration = 20, expirationTime = 112, timeMod = 2}
        local other = {icon = 132212, own = false, duration = 20, expirationTime = 111}
        local timeless = {icon = 134400, own = true, duration = 0, expirationTime = 0}
        local function countdown(holder, value)
            for _, widget in ipairs(widgets) do
                if widget.kind == "FontString" and widget.parent.parent == holder
                    and widget.shown and widget.text == value then return true end
            end
        end
        local function auraButton(icon)
            for _, widget in ipairs(widgets) do
                if widget.texture == icon then return widget.parent end
            end
        end
        view.Debuffs({own, other, timeless}, false, true)
        local button = assert(auraButton(own.icon))
        assert(countdown(button, "6s"), "a player's timed effect displays its adjusted remaining time")
        assert(not countdown(auraButton(other.icon), "11s"), "other players' effects have no countdown")
        assert(not countdown(auraButton(timeless.icon), "0s"), "permanent effects have no countdown")
        time(104)
        button.parent.OnUpdate(button.parent, 0.25)
        assert(countdown(button, "4s"))
        view.Debuffs({own}, false, false)
        assert(not countdown(button, "4s"), "disabling timers clears the text on the reused button")
        view.Debuffs({own}, false, true)
        view.Debuffs({other}, false, true)
        assert(not countdown(button, "4s"), "another caster's effect must not retain the previous countdown")
        view.Debuffs({own}, false, true)
        time(112)
        button.parent.OnUpdate(button.parent, 0.25)
        assert(not countdown(button, "4s") and not countdown(button, "0s"))
    end)
end)


test("restricted debuffs bind native timers only for own effects in the existing row", function()
    withTargetAuraView(true, function(view, _, groups)
        local own = groups["HARMFUL|PLAYER"]
        local other = groups["HARMFUL|!PLAYER"]
        assert(own and other and own.container == other.container)
        assert(own.container.parent.clipped and own.layoutIndex < other.layoutIndex)
        local label = own.button.durationLabel
        assert(label and not other.button.durationLabel)
        view.Debuffs({}, true, false)
        assert(own.container.shown and not label.shown)
        view.Debuffs({}, true, true)
        assert(own.container.shown and label.shown)
    end)
end)

test("target threat reads the current enemy, scaled pull percentage, and tank state", function()
    local alive, enemy, combat = true, true, true
    local tanking, status, scaled = false, 1, 93.4
    local role, inGroup = "DAMAGER", true
    withGlobals({
        UnitCanAttack = function() return enemy end,
        UnitIsDead = function() return not alive end,
        UnitAffectingCombat = function(unit) assert(unit == "player"); return combat end,
        UnitGroupRolesAssigned = function() return role end,
        IsInGroup = function() return inGroup end,
        UnitExists = function() return false end,
        UnitDetailedThreatSituation = function(unit, target)
            assert(unit == "player" and target == "target")
            return tanking, status, scaled, 79, 23000
        end,
    }, function()
        local ns = {}
        loadAddon("Core/Read.lua", ns)
        loadAddon("Modules/Target/Model.lua", ns)
        local threat = ns.TargetModel.Threat()
        assert(threat.percent == 93.4 and threat.state == "warning" and not threat.tanking)
        tanking, status, scaled = true, 3, 100
        assert(ns.TargetModel.Threat().state == "warning")
        role = "TANK"
        assert(ns.TargetModel.Threat().state == "tanking")
        tanking, status, scaled = false, 0, 26
        assert(ns.TargetModel.Threat().state == "warning")
        role, inGroup = "DAMAGER", false
        tanking, status, scaled = true, 3, 100
        assert(ns.TargetModel.Threat().state == "tanking")
        alive = false
        assert(ns.TargetModel.Threat() == nil)
        alive, enemy = true, false
        assert(ns.TargetModel.Threat() == nil)
        enemy, combat = true, false
        assert(ns.TargetModel.Threat() == nil)
    end)
end)

test("restricted target threat is forwarded for display without a false warning or ranking", function()
    local secret = {}
    withGlobals({
        issecretvalue = function(value) return value == secret end,
        UnitCanAttack = function() return true end,
        UnitAffectingCombat = function() return true end,
        UnitDetailedThreatSituation = function() return secret, secret, secret, secret, secret end,
        UnitName = function() return "Test" end,
    }, function()
        local ns = {}
        loadAddon("Core/Read.lua", ns)
        loadAddon("Modules/Target/Model.lua", ns)
        local data = ns.TargetModel.Threat()
        assert(data.percent == secret and data.tanking == nil and data.state == "normal")
        assert(#ns.TargetModel.ThreatRoster() == 0)
    end)
end)

test("threat roster ranks readable party threat and includes companions", function()
    local values = {player = 3000, party1 = 8000, pet = 4800, party2 = 0, partypet1 = 2500}
    withGlobals({
        UnitCanAttack = function() return true end,
        UnitAffectingCombat = function() return true end,
        UnitExists = function(unit) return values[unit] ~= nil end,
        UnitName = function(unit) return unit end,
        IsInGroup = function() return true end,
        IsInRaid = function() return false end,
        UnitDetailedThreatSituation = function(unit)
            return unit == "party1", 0, 0, 0, values[unit]
        end,
    }, function()
        local ns = {}
        loadAddon("Core/Read.lua", ns)
        loadAddon("Modules/Target/Model.lua", ns)
        local ranked = ns.TargetModel.ThreatRoster()
        assert(#ranked == 4 and ranked[1].unit == "party1" and ranked[1].tanking)
        assert(ranked[2].unit == "pet" and ranked[3].unit == "player" and ranked[4].unit == "partypet1")
    end)
end)

test("the threat bar shows pull percentage, aggro and a bounded fill, then hides", function()
    withTargetAuraView(false, function(view, widgets)
        local function find(key, value, parent)
            for _, widget in ipairs(widgets) do
                if widget[key] == value and (not parent or widget.parent == parent) then return widget end
            end
        end
        local panel = assert(find("text", "Bedrohung")).parent
        assert(not panel:IsShown())
        view.Threat({percent = 91.6, tanking = false, state = "warning"})
        local amount = assert(find("text", "92%", panel))
        local bar = assert(find("kind", "StatusBar", panel))
        assert(panel:IsShown() and bar.value == 91.6 and bar.color[1] > bar.color[2])
        view.Threat({percent = 108, tanking = true, state = "tanking"})
        assert(amount.text == "Aggro bei dir" and bar.value == 100 and bar.color[2] > bar.color[1])
        view.Threat(nil)
        assert(not panel:IsShown())
    end)
end)

test("restricted target buffs use centered captions below their icons instead of stock countdowns", function()
    withTargetAuraView(true, function(view, _, groups)
        local buff = groups.HELPFUL
        local timer = assert(buff.button.durationLabel, "native helpful auras need a duration caption")
        assert(buff.button.durationCooldown.hideCountdownNumbers == true)
        assert(timer.point[1] == "TOPRIGHT" and timer.point[3] == "BOTTOMRIGHT")
        assert(buff.container.parent.height > 24, "the row needs space for the caption")
        view.Buffs({}, true)
        assert(buff.container.shown and timer.shown)
    end)
end)

test("readable target buffs show compact countdowns from other casters and clear on expiry", function()
    withTargetAuraView(false, function(view, widgets, _, time)
        local function find(predicate)
            for _, widget in ipairs(widgets) do if predicate(widget) then return widget end end
        end
        view.Buffs({
            {icon = 1, own = false, duration = 1000, expirationTime = 995},
            {icon = 2, own = false, duration = 0, expirationTime = 0},
        })
        local icon = assert(find(function(widget) return widget.texture == 1 end))
        local timer = assert(find(function(widget) return widget.text == "15m" end))
        assert(timer.parent.parent == icon.parent and timer.point[3] == "BOTTOMRIGHT")
        local cooldown = assert(find(function(widget) return widget.kind == "Cooldown" and widget.parent == icon.parent end))
        assert(cooldown.hideCountdownNumbers == true)
        assert(not find(function(widget) return widget.text == "0s" end))
        time(995)
        local row = icon.parent.parent
        row.OnUpdate(row, 0.25)
        assert(timer.text == "" and rawget(row, "OnUpdate") == nil)
    end)
end)
