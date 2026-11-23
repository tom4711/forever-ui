local function loadController(ns)
    loadAddon("Core/Read.lua", ns)
    loadAddon("Core/CombatQueue.lua", ns)
    loadAddon("Modules/Warlock/Model.lua", ns)
    loadAddon("Modules/Warlock/Controller.lua", ns)
    ns.Warlock.Init()
end

test("Warlock controller leaves other classes untouched", function()
    withGlobals({UnitClass = function() return "Mage", "MAGE" end}, function()
        local created = 0
        local ns = {WarlockView = {Create = function() created = created + 1 end}}
        loadController(ns)
        assert(created == 0)
    end)
end)

test("Warlock controller refreshes pet and bag state on matching events", function()
    local locked, petExists, shardCount, impKnown = false, true, 5, true
    local checkedItems = {}
    local itemAPI = {GetItemCount = function(id, bank, uses)
        checkedItems.modern = {id, bank, uses}
        return shardCount
    end}
    local events = {}
    local eventFrame = {
        RegisterEvent = function(_, event) events[event] = true end,
        SetScript = function(self, key, fn) self[key] = fn end,
    }
    withGlobals({
        UnitClass = function() return "Warlock", "WARLOCK" end,
        InCombatLockdown = function() return locked end,
        CreateFrame = function() return eventFrame end,
        UnitExists = function() return petExists end,
        UnitIsDeadOrGhost = function() return false end,
        UnitName = function() return "Imp" end,
        UnitHealth = function() return 80 end,
        UnitHealthMax = function() return 100 end,
        GetItemCount = function(id, bank, uses)
            checkedItems.legacy = {id, bank, uses}
            return 0
        end,
        C_Item = itemAPI,
        IsPlayerSpell = function(id) return id == 688 and impKnown end,
    }, function()
        local rendered, status
        local ns = {
            db = {warlock = {enabled = true, scale = 1, position = {}}},
            Preview = {IsEnabled = function() return false end},
            UI = {Place = function() end},
            WarlockView = {Create = function()
                return {
                    frame = {},
                    RenderStatus = function(data) status = data end,
                    RenderActions = function(data, actions) rendered = {data = data, actions = actions} end,
                }
            end},
        }
        loadController(ns)
        assert(rendered.data.demon.state == "living" and rendered.data.shards == 5)
        assert(#rendered.actions == 1 and rendered.actions[1].spellID == 688)
        assert(events.UNIT_PET and events.BAG_UPDATE_DELAYED)
        assert(checkedItems.modern[1] == 6265 and checkedItems.modern[2] == false and checkedItems.modern[3] == false)

        C_Item = nil
        eventFrame.OnEvent(eventFrame, "BAG_UPDATE_DELAYED")
        assert(rendered.data.shards == 0 and checkedItems.legacy[1] == 6265, "missing modern API should use legacy count")
        C_Item = itemAPI

        local previous = rendered
        petExists, shardCount, impKnown = false, 2, false
        eventFrame.OnEvent(eventFrame, "UNIT_PET", "party1")
        assert(rendered == previous, "an unrelated pet event should not refresh the controls")
        eventFrame.OnEvent(eventFrame, "BAG_UPDATE_DELAYED")
        assert(rendered.data.demon.state == "missing" and rendered.data.shards == 2 and #rendered.actions == 0)

        petExists = true
        eventFrame.OnEvent(eventFrame, "UNIT_PET", "player")
        assert(rendered.data.demon.state == "living")

        previous = rendered
        locked, petExists, shardCount = true, false, 4
        eventFrame.OnEvent(eventFrame, "BAG_UPDATE_DELAYED")
        assert(status.demon.state == "missing" and status.shards == 4, "status must update while combat defers secure buttons")
        assert(ns.CombatQueue.Flush() == false and rendered == previous)
        locked = false
        assert(ns.CombatQueue.Flush() == true)
        assert(rendered ~= previous and rendered.data.shards == 4)
    end)
end)
