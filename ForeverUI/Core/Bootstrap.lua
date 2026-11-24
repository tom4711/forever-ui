local addon, ns = ...
function ns.Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffd4a447Forever UI|r: "..message)
end
function ns.Refresh()
    if InCombatLockdown() then ns.CombatQueue.Request("layout",ns.Refresh);return end
    ns.Layout.Refresh()
    ns.MinimapMenu.Refresh()
    ns.Preview.Refresh()
    if ns.Hunter then ns.Hunter.Refresh()end
    if ns.Paladin then ns.Paladin.Refresh()end
    if ns.Warlock then ns.Warlock.Refresh()end
    if ns.Priest then ns.Priest.Refresh()end
    ns.ClassSupport.Refresh()
    if ns.Player then ns.Player.Refresh()end
    ns.Target.Refresh()
    ns.Party.Refresh()
    ns.ActionBars.Refresh()
    ns.Inventory.Refresh()
    ns.UnitFrameAppearance.Refresh()
    ns.Companion.Refresh()
    if ns.CastBar then ns.CastBar.Refresh()end
    if ns.XP then ns.XP.Refresh()end
    if ns.HunterActions and ns.Preview.IsEnabled then ns.HunterActions.SetPreview(ns.Preview.IsEnabled())end
end
local events=CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:SetScript("OnEvent",function(_,event,name)
    if event=="PLAYER_REGEN_ENABLED"then
        local moved=ns.UI.FlushDeferredMoves()
        ns.CombatQueue.Flush()
        if moved then ns.Refresh()end
    elseif event=="PLAYER_REGEN_DISABLED"then
        local hunterFrame=ns.Hunter and ns.Hunter.GetFrame()
        if hunterFrame and hunterFrame.dragging then hunterFrame:GetScript("OnDragStop")(hunterFrame)end
    elseif event=="ADDON_LOADED" and name==addon then
        ns.db=ns.Settings.Load(ForeverUICharDB)
        ForeverUICharDB=ns.db
        ForeverUIProfilesDB=ns.Profiles.Init(ForeverUIProfilesDB)
    elseif event=="PLAYER_LOGIN" then
        ns.Theme.SetClassAccent(ns.db.classAccent)
        SLASH_FOREVERUI1="/fui"
        SlashCmdList.FOREVERUI=function(message)
            if message:match("^%s*preview%s*$") then ns.Preview.SetEnabled(not ns.Preview.IsEnabled())
            elseif message:match("^%s*layout%s*$") then ns.Layout.SetEditing(not ns.Layout.IsEditing())
            elseif message:match("^%s*stats%s*$") then ns.StatsView.Toggle()
            else ns.Options.Toggle() end
        end
        ns.GoldStats.Init()
        ns.LevelStats.Init()
        ns.Bindings.Init()
        if ns.Hunter then ns.Hunter.Init()end
        if ns.Paladin then ns.Paladin.Init()end
        if ns.Warlock then ns.Warlock.Init()end
        if ns.Priest then ns.Priest.Init()end
        ns.ClassSupport.Init()
        if ns.Player then ns.Player.Init()end
        ns.Target.Init()
        ns.Party.Init()
        ns.ActionBars.Init()
        ns.Inventory.Init()
        ns.Merchant.Init()
        ns.ItemTooltips.Init()
        ns.UnitFrameAppearance.Init()
        ns.Companion.Init()
        if ns.CastBar then ns.CastBar.Init()end
        if ns.XP then ns.XP.Init()end
        if ns.MinimapButton then ns.MinimapButton.Init()end
        ns.Print(ns.L.READY)
    end
end)
