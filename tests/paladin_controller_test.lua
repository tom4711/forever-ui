local function loadController(ns)
    loadAddon("Core/Read.lua", ns)
    loadAddon("Core/CombatQueue.lua", ns)
    loadAddon("Modules/Paladin/Model.lua", ns)
    loadAddon("Modules/Paladin/Controller.lua", ns)
    ns.Paladin.Init()
end

test("Paladin controller leaves other classes untouched", function()
    withGlobals({UnitClass = function() return "Mage", "MAGE" end}, function()
        local created = 0
        local ns = {PaladinView = {Create = function() created = created + 1 end}}
        loadController(ns)
        assert(created == 0)
    end)
end)

test("Paladin controller hides weapon toggle without two valid selected sets", function()
    local eventFrame = {RegisterEvent = function() end, SetScript = function(self, key, fn) self[key] = fn end}
    withGlobals({
        UnitClass = function() return "Paladin", "PALADIN" end,
        InCombatLockdown = function() return false end,
        CreateFrame = function() return eventFrame end,
        C_EquipmentSet = {
            GetEquipmentSetIDs = function() return {1} end,
            GetEquipmentSetInfo = function(id)
                assert(id == 1)
                return "Shield Set"
            end,
        },
    }, function()
        local rendered, status
        local ns = {
            db = {paladin = {enabled = true, weaponSets = {shield = 1}}},
            Preview = {IsEnabled = function() return false end},
            PaladinView = {Create = function()
                return {
                    RenderStatus = function(data) status = data end,
                    RenderActions = function(data, _, macro) rendered = {data = data, macro = macro} end,
                }
            end},
        }
        loadController(ns)
        assert(rendered and rendered.macro == nil and rendered.data.visible == true and status.visible == true)

        ns.db.paladin.weaponSets.twoHand = 2
        rendered = nil
        eventFrame.OnEvent(eventFrame, "EQUIPMENT_SETS_CHANGED")
        assert(rendered and rendered.macro == nil, "a deleted set must not produce a weapon macro")
    end)
end)

test("Paladin secure updates are queued until combat ends", function()
    local locked, hasShield = false, true
    withGlobals({
        UnitClass = function() return "Paladin", "PALADIN" end,
        InCombatLockdown = function() return locked end,
        CreateFrame = function() return {RegisterEvent = function() end, SetScript = function() end} end,
        C_EquipmentSet = {
            GetEquipmentSetIDs = function() return {1, 2} end,
            GetEquipmentSetInfo = function(id) return id == 1 and "Shield Set" or "Two Hand" end,
        },
        C_Item = {IsEquippedItemType = function(value)
            assert(value == "Shields")
            return hasShield
        end},
        IsPlayerSpell = function(id) return id == 465 end,
    }, function()
        local rendered, status
        local ns = {
            db = {paladin = {enabled = true, scale = 1, position = {}, weaponSets = {shield = 1, twoHand = 2}}},
            Preview = {IsEnabled = function() return false end},
            PaladinView = {Create = function()
                return {
                    RenderStatus = function(data) status = data end,
                    RenderActions = function(data, actions, macro)
                        rendered = {data = data, actions = actions, macro = macro}
                    end,
                }
            end},
        }
        loadController(ns)
        assert(rendered and rendered.macro == "/equipset [equipped:shield] Two Hand; Shield Set")
        assert(status.shield == true and rendered.actions[1].spellID == 465)

        local initial = rendered
        locked, hasShield = true, false
        ns.Paladin.Refresh()
        assert(status.shield == false, "live status should update during combat")
        assert(ns.CombatQueue.Flush() == false and rendered == initial, "secure actions should wait until combat ends")

        locked = false
        assert(ns.CombatQueue.Flush() == true)
        assert(rendered ~= initial and rendered.macro == initial.macro and rendered.data.shield == false)
    end)
end)
