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
            local frame = {Hide = function(self) self.visible = false end, RegisterEvent = function() end,
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

        ns.Party.SetPreview(true)
        ns.Party.Refresh()
        assert(demo.frame.visible and not live and stock.parent == original)
        ns.Party.SetPreview(false)
        ns.db.party.enabled = true
        ns.db.party.replaceBlizzard = true
        ns.Party.Refresh()
        assert(live.live and not demo.frame.visible and stock.parent ~= original)
        assert(wick.parent == original)

        locked = true
        eventFrame.OnEvent(eventFrame, "UNIT_HEALTH", "party2")
        assert(live.event == "UNIT_HEALTH" and live.unit == "party2")
        eventFrame.OnEvent(eventFrame, "UNIT_HEALTH", "raid10")
        assert(live.unit == "party2")
        inRaid = true
        eventFrame.OnEvent(eventFrame, "GROUP_ROSTER_UPDATE")
        assert(stock.parent ~= original and ns.CombatQueue.Flush() == false)
        locked = false
        assert(ns.CombatQueue.Flush() and stock.parent == original and wick.parent == original)

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
