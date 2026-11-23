test("target frame clears its destination and follows changes to the target's target", function()
    local selected, destination = true, "Bear"
    local registered, events = {}, {}
    local name, isPlayer
    function events:RegisterEvent() end
    function events:RegisterUnitEvent(event, ...) registered[event] = {...} end
    function events:SetScript(key, callback) self[key] = callback end

    withGlobals({
        TargetFrame = false,
        CreateFrame = function() return events end,
        InCombatLockdown = function() return false end,
        UnitExists = function(unit)
            if unit == "target" then return selected end
            return unit == "targettarget" and destination ~= nil
        end,
        UnitName = function(unit) return unit == "targettarget" and destination or "Wolf" end,
        UnitIsUnit = function(first, second)
            return first == "targettarget" and second == "player" and destination == "Player"
        end,
        UnitCanAttack = function() return false end,
    }, function()
        local noop = function() end
        local ns = {
            db = {target = {enabled = true}},
            UI = {Place = noop},
            TargetView = {Create = function()
                return {
                    frame = {}, SetUnitWatch = noop, Identity = noop, Health = noop, Cast = noop, Debuffs = noop, AuraLimit = 10,
                    Destination = function(value, player) name, isPlayer = value, player end,
                }
            end},
        }
        loadAddon("Core/Read.lua", ns)
        loadAddon("Modules/Target/Model.lua", ns)
        loadAddon("Modules/Target/Controller.lua", ns)
        ns.Target.Init()
        assert(registered.UNIT_TARGET[1] == "target" and registered.UNIT_NAME_UPDATE[2] == "targettarget")
        assert(name == "Bear" and not isPlayer)

        destination = "Player"
        events.OnEvent(events, "UNIT_TARGET", "target")
        assert(name == "Player" and isPlayer)

        destination = nil
        events.OnEvent(events, "UNIT_TARGET", "target")
        assert(name == nil and not isPlayer)

        destination = "Bear"
        events.OnEvent(events, "UNIT_TARGET", "target")
        assert(name == "Bear")
        selected = false
        events.OnEvent(events, "PLAYER_TARGET_CHANGED")
        assert(name == nil and not isPlayer)
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
