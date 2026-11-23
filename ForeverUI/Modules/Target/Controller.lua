local _, ns = ...
local M, R = ns.TargetModel, ns.Read
local Target = {}
ns.Target = Target

local view, previewView, stockParent, hiddenParent
local replacedStock
local active, previewEnabled, inWorld = false, false, true
local castRefreshQueued = false

local function replaceStock(enabled)
    if enabled and not replacedStock then
        local stock = _G.TargetFrame
        if not stock then return enabled end
        if not hiddenParent then
            hiddenParent = CreateFrame("Frame", nil, UIParent)
            hiddenParent:Hide()
        end
        local parent = stock:GetParent()
        -- Keep Blizzard's Show/Hide events and unit updates intact under a hidden parent.
        pcall(stock.SetParent, stock, hiddenParent)
        if stock:GetParent() ~= hiddenParent then return false end
        stockParent, replacedStock = parent, stock
    elseif not enabled and replacedStock then
        if replacedStock:GetParent() == hiddenParent then
            pcall(replacedStock.SetParent, replacedStock, stockParent)
            if replacedStock:GetParent() == hiddenParent then return true end
        end
        stockParent, replacedStock = nil, nil
    end
    return enabled
end

local function hasTarget()
    return inWorld and R.Call(UnitExists, "target") == true
end

local function refreshIdentity()
    view.Identity(M.Value(UnitName, "target"), M.Value(UnitLevel, "target"))
end

local function refreshDestination()
    local name
    if R.Call(UnitExists, "targettarget") == true then name = M.Value(UnitName, "targettarget") end
    local isPlayer = R.Call(UnitIsUnit, "targettarget", "player") == true
    view.Destination(name, isPlayer)
end

local function refreshHealth()
    view.Health(M.Value(UnitHealth, "target"), M.Value(UnitHealthMax, "target"),
        R.Call(UnitCanAttack, "player", "target") == true)
end

local function refreshDebuffs()
    if view.NativeDebuffs then
        view.RefreshNativeDebuffs()
    else
        view.Debuffs(M.Debuffs(view.AuraLimit))
    end
end

local function refreshCast()
    view.Cast(active and hasTarget() and M.Cast() or nil)
end

local function refreshTarget()
    if active and hasTarget() then
        refreshIdentity()
        refreshDestination()
        refreshHealth()
        refreshDebuffs()
        refreshCast()
    else
        view.Destination(nil, false)
        view.Cast(nil)
        view.Debuffs({})
    end
end

function Target.Refresh()
    if not view or not ns.db.target then return end
    if not InCombatLockdown() then
        local enabled = ns.db.target.enabled == true
        local replaced = replaceStock(enabled)
        local showLive = replaced and (not previewEnabled or not enabled)
        if showLive ~= active then
            view.SetUnitWatch(showLive)
            active = showLive
        end
        if not view.frame.dragging then ns.UI.Place(view.frame, "target") end
        if enabled and previewEnabled then
            if not previewView then previewView = ns.TargetView.Create("ForeverUI_PreviewTarget", true) end
            if not previewView.frame.dragging then ns.UI.Place(previewView.frame, "target") end
            if not previewView.frame:IsShown() then previewView.ShowPreview() end
        elseif previewView then
            previewView.frame:Hide()
        end
    end
    refreshTarget()
end

function Target.Preview(enabled)
    previewEnabled = enabled == true
    Target.Refresh()
end

local stopEvents = {
    UNIT_SPELLCAST_STOP = true, UNIT_SPELLCAST_CHANNEL_STOP = true, UNIT_SPELLCAST_EMPOWER_STOP = true,
    UNIT_SPELLCAST_FAILED = true, UNIT_SPELLCAST_FAILED_QUIET = true, UNIT_SPELLCAST_INTERRUPTED = true,
}
local castEvents = {
    "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_DELAYED",
    "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_UPDATE",
    "UNIT_SPELLCAST_EMPOWER_START", "UNIT_SPELLCAST_EMPOWER_UPDATE",
    "UNIT_SPELLCAST_INTERRUPTIBLE", "UNIT_SPELLCAST_NOT_INTERRUPTIBLE",
}

local function onEvent(_, event, unit)
    if event == "PLAYER_ENTERING_WORLD" then
        inWorld = true
        Target.Refresh()
    elseif event == "PLAYER_LEAVING_WORLD" then
        inWorld = false
        refreshTarget()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if not view then Target.Init() else Target.Refresh() end
    elseif event == "PLAYER_TARGET_CHANGED" then
        refreshTarget()
    elseif active and hasTarget() then
        if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
            refreshHealth()
        elseif event == "UNIT_TARGET" or (event == "UNIT_NAME_UPDATE" and unit == "targettarget") then
            refreshDestination()
        elseif event == "UNIT_NAME_UPDATE" or event == "UNIT_LEVEL" or event == "UNIT_PORTRAIT_UPDATE" then
            refreshIdentity()
        elseif event == "UNIT_FACTION" then
            refreshHealth()
            refreshCast()
        elseif event == "UNIT_AURA" then
            refreshDebuffs()
        elseif stopEvents[event] and C_Timer and C_Timer.After then
            -- The client may still return the just-ended cast while dispatching its stop event.
            if not castRefreshQueued then
                castRefreshQueued = true
                C_Timer.After(0, function()
                    castRefreshQueued = false
                    refreshCast()
                end)
            end
        else
            refreshCast()
        end
    end
end

local events
function Target.Init()
    if view then return end
    if not events then
        events = CreateFrame("Frame")
        events:RegisterEvent("PLAYER_REGEN_ENABLED")
        events:SetScript("OnEvent", onEvent)
    end
    if InCombatLockdown() then return end
    view = ns.TargetView.Create("ForeverUI_Target")
    for _, event in ipairs({"PLAYER_ENTERING_WORLD", "PLAYER_LEAVING_WORLD", "PLAYER_TARGET_CHANGED"}) do
        events:RegisterEvent(event)
    end
    for _, event in ipairs({"UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_LEVEL", "UNIT_PORTRAIT_UPDATE", "UNIT_TARGET"}) do
        events:RegisterUnitEvent(event, "target")
    end
    events:RegisterUnitEvent("UNIT_NAME_UPDATE", "target", "targettarget")
    events:RegisterUnitEvent("UNIT_FACTION", "target", "player")
    if not view.NativeDebuffs then events:RegisterUnitEvent("UNIT_AURA", "target") end
    for _, event in ipairs(castEvents) do events:RegisterUnitEvent(event, "target") end
    for event in pairs(stopEvents) do events:RegisterUnitEvent(event, "target") end
    Target.Refresh()
end
