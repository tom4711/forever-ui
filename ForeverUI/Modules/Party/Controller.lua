local _, ns = ...
local R = ns.Read
local Party = {}
ns.Party = Party

local live, demo, events, hiddenParent
local preview, watchingRange = false, false
local hiddenStock = {}
local stockFrames = {"PartyFrame", "CompactPartyFrame"}
local partyUnits = {party1 = true, party2 = true, party3 = true, party4 = true}

local function updateStock(hide)
    if hide then
        for _, name in ipairs(stockFrames) do
            local frame = _G[name]
            if frame and not hiddenStock[frame] then
                if not hiddenParent then
                    hiddenParent = CreateFrame("Frame", nil, UIParent)
                    hiddenParent:Hide()
                end
                local parent = frame:GetParent()
                pcall(frame.SetParent, frame, hiddenParent)
                if frame:GetParent() == hiddenParent then hiddenStock[frame] = {parent = parent} end
            end
        end
    else
        for frame, state in pairs(hiddenStock) do
            if frame:GetParent() == hiddenParent then pcall(frame.SetParent, frame, state.parent) end
            if frame:GetParent() ~= hiddenParent then hiddenStock[frame] = nil end
        end
    end
end

local function layout()
    local config = ns.db.party
    local enabled = config.enabled == true
    if enabled and not live then live = ns.PartyView.Create(false) end
    if live then
        live.ApplySettings(config)
        live.SetLive(enabled and not preview)
        if not live.frame.dragging then ns.UI.Place(live.frame, "party") end
    end

    if preview then
        if not demo then demo = ns.PartyView.Create(true) end
        demo.ApplySettings(config)
        if not demo.frame.dragging then ns.UI.Place(demo.frame, "party") end
        demo.ShowPreview()
    elseif demo then
        demo.frame:Hide()
    end

    local inParty = R.Boolean(R.Call(IsInGroup)) == true and R.Boolean(R.Call(IsInRaid)) == false
    local watchRange = enabled and not preview and inParty
    if watchRange ~= watchingRange then
        watchingRange = watchRange
        if watchRange then events:RegisterEvent("UNIT_IN_RANGE_UPDATE")
        else events:UnregisterEvent("UNIT_IN_RANGE_UPDATE") end
    end
    updateStock(enabled and not preview and config.replaceBlizzard and inParty)
    if live then live.Render() end
end

function Party.Refresh()
    if not events then return end
    ns.CombatQueue.Request("party", layout)
    if InCombatLockdown() and live then live.Render() end
end

function Party.SetPreview(enabled)
    preview = enabled == true
end

local unitEvents = {
    "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER",
    "UNIT_NAME_UPDATE", "UNIT_PORTRAIT_UPDATE", "UNIT_CONNECTION", "UNIT_FLAGS", "UNIT_AURA", "UNIT_PHASE",
}
local function onEvent(_, event, value)
    if partyUnits[value] and live then
        live.Render(event, value)
    elseif event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED"
        or event == "SPELLS_CHANGED" or event == "LEARNED_SPELL_IN_SKILL_LINE" then
        if live then live.Render(event) end
    elseif event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ROLES_ASSIGNED" or event == "PLAYER_ENTERING_WORLD"
        or (event == "ADDON_LOADED" and (value == "Blizzard_CompactRaidFrames" or value == "Blizzard_UnitFrame")) then
        Party.Refresh()
    end
end

function Party.Init()
    if events then return end
    events = CreateFrame("Frame")
    for _, event in ipairs(unitEvents) do events:RegisterEvent(event) end
    for _, event in ipairs({"GROUP_ROSTER_UPDATE", "PLAYER_ROLES_ASSIGNED", "PLAYER_ENTERING_WORLD",
        "PLAYER_TARGET_CHANGED", "ADDON_LOADED", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
        "SPELLS_CHANGED", "LEARNED_SPELL_IN_SKILL_LINE"}) do events:RegisterEvent(event) end
    events:SetScript("OnEvent", onEvent)
    Party.Refresh()
end
