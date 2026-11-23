local _, ns = ...
local UI, T, R = ns.UI, ns.Theme, ns.Read
local L = ns.L
local castColor = {0.72, 0.56, 0.32, 1}
local channelColor = {0.22, 0.61, 0.62, 1}
local M = {}
ns.CastBar = M

local frame, nativeBar, plainBar, icon, title, time, timeBinding
local cast, demo
local stock, hiddenStockLayers, replaceStock
local updateQueued
local directions = Enum and Enum.StatusBarTimerDirection
local interpolation = Enum and Enum.StatusBarInterpolation
local drawLayers = {"BACKGROUND", "BORDER", "ARTWORK", "OVERLAY", "HIGHLIGHT"}

local function present(value)
    return (issecretvalue and issecretvalue(value)) or value ~= nil
end

local function readDuration(api)
    if type(api) ~= "function" then return nil end
    local ok, duration = pcall(api, "player")
    if ok then return duration end
end

local function readCast()
    local ok, name, displayName, texture, startMs, endMs = pcall(UnitCastingInfo, "player")
    if not ok then name = nil end
    local kind, duration = "cast", readDuration(UnitCastingDuration)
    if not present(duration) and (not ok or not present(name)) then
        local tradeSkill, notInterruptible, spellID, empowered
        ok, name, displayName, texture, startMs, endMs, tradeSkill, notInterruptible, spellID, empowered = pcall(UnitChannelInfo, "player")
        if not ok then name = nil end
        kind = R.Boolean(empowered) == true and "empower" or "channel"
        if kind == "empower" then duration = readDuration(UnitEmpoweredChannelDuration) end
        if not present(duration) then duration = readDuration(UnitChannelDuration) end
    end
    if not present(duration) and (not ok or not present(name)) then return nil end

    local startTime, endTime = R.Number(startMs), R.Number(endMs)
    if startTime and endTime and endTime > startTime then
        startTime, endTime = startTime / 1000, endTime / 1000
        if kind == "empower" then
            local hold = R.Number(R.Call(GetUnitEmpowerHoldAtMaxTime, "player"))
            if hold and hold > 0 then endTime = endTime + hold / 1000 end
        end
    else
        startTime, endTime = nil, nil
    end

    return {
        kind = kind, duration = duration, startTime = startTime, endTime = endTime,
        name = present(displayName) and displayName or name,
        texture = texture,
    }
end

local function restoreStockLayers()
    if not hiddenStockLayers then return end
    for widget, layers in pairs(hiddenStockLayers) do
        for _, layer in ipairs(layers) do widget:EnableDrawLayer(layer) end
    end
    hiddenStockLayers = nil
end

local function hideStockLayers(widget)
    if not hiddenStockLayers[widget] then
        local changed = {}
        hiddenStockLayers[widget] = changed
        for _, layer in ipairs(drawLayers) do
            if widget:IsDrawLayerEnabled(layer) then
                widget:DisableDrawLayer(layer)
                changed[#changed + 1] = layer
            end
        end
    end
    for _, child in ipairs({widget:GetChildren()}) do
        if child ~= stock.Selection then hideStockLayers(child) end
    end
end

local function syncStockLayers()
    if replaceStock then
        -- The native finish logic needs both positive alpha and a visible frame to run its fade.
        hiddenStockLayers = hiddenStockLayers or {}
        hideStockLayers(stock)
    elseif hiddenStockLayers then
        -- Keep a suppressed finish animation invisible until the native bar hides itself.
        if not stock:IsShown() or R.Boolean(stock.isInEditMode) == true
            or R.Boolean(stock.casting) == true or R.Boolean(stock.channeling) == true then
            restoreStockLayers()
        end
    end
end

local function suppressStock(suppress)
    replaceStock = suppress
    if suppress and not stock then
        local native = _G.PlayerCastingBarFrame or _G.CastingBarFrame
        if not native or type(native.IsDrawLayerEnabled) ~= "function" then return end
        stock = native
        stock:HookScript("OnHide", function(self)
            if not self:IsShown() then restoreStockLayers() end
        end)
        -- Empowered casts can create additional stage frames during the native event handler.
        stock:HookScript("OnEvent", syncStockLayers)
    end
    if stock then syncStockLayers() end
end

local function hide()
    cast, demo = nil, false
    if timeBinding then timeBinding:SetEnabled(false) end
    frame:Hide()
    suppressStock(false)
end

local function setCaption(name, texture)
    if not present(name) or not pcall(title.SetText, title, name) then title:SetText(L.CAST_BAR) end
    if not present(texture) or not pcall(icon.SetTexture, icon, texture) then icon:SetTexture(136243) end
end

local function update()
    if not cast then return end
    local remaining
    if cast.endTime then
        local now = GetTime()
        remaining = math.max(0, cast.endTime - now)
        if now > cast.endTime + 0.15 then
            hide()
            return
        end
        if not cast.native then
            local span = cast.endTime - cast.startTime
            local ratio = math.min(remaining / span, 1)
            plainBar:SetValue(cast.kind == "channel" and ratio or 1 - ratio)
        end
    end
    if not cast.boundTime and remaining then time:SetFormattedText("%.1f s", remaining) end
end

local function showCast(data)
    local direction = directions and (data.kind == "channel" and directions.RemainingTime or directions.ElapsedTime)
    data.native = direction ~= nil and nativeBar.SetTimerDuration ~= nil and present(data.duration)
        and pcall(nativeBar.SetTimerDuration, nativeBar, data.duration, interpolation and interpolation.Immediate or 0, direction)
    if not data.native and not data.endTime then
        hide()
        return
    end
    if data.endTime and data.endTime <= GetTime() then
        hide()
        return
    end

    cast, demo = data, false
    local color = data.kind == "channel" and channelColor or castColor
    local fill = data.native and nativeBar or plainBar
    fill:SetStatusBarColor(unpack(color))
    nativeBar:SetShown(data.native == true)
    plainBar:SetShown(not data.native)
    setCaption(data.name, data.texture)
    if timeBinding then timeBinding:SetEnabled(false) end
    time:SetText("")
    if timeBinding and present(data.duration) then
        data.boundTime = pcall(timeBinding.SetDuration, timeBinding, data.duration)
        if data.boundTime then timeBinding:SetEnabled(true) end
    end
    update()
    if cast ~= data then return end
    frame:Show()
    suppressStock(true)
end

local function showPreview()
    cast, demo = nil, true
    if timeBinding then timeBinding:SetEnabled(false) end
    nativeBar:Hide()
    plainBar:Show()
    plainBar:SetStatusBarColor(unpack(castColor))
    plainBar:SetValue(0.55)
    setCaption(L.CAST_BAR_DEMO, 134414)
    time:SetText(L.CAST_BAR_DEMO_TIME)
    frame:Show()
    suppressStock(false)
end

local function refreshCast()
    if not ns.db.castBar.enabled then hide(); return end
    if ns.Preview.IsEnabled() and not InCombatLockdown() then
        if not demo then showPreview() end
        return
    end
    local data = readCast()
    if data then showCast(data) else hide() end
end

function M.Refresh()
    if not frame then return end
    if not frame.dragging and not InCombatLockdown() then UI.Place(frame, "castBar") end
    refreshCast()
end

local function makeBar(root)
    local bar = CreateFrame("StatusBar", nil, root)
    bar:SetPoint("BOTTOMLEFT", 34, 5)
    bar:SetPoint("BOTTOMRIGHT", -8, 5)
    bar:SetHeight(3)
    bar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
    bar:SetMinMaxValues(0, 1)
    return bar
end

function M.Init()
    if frame then return end
    frame = CreateFrame("Frame", "ForeverUI_CastBar", UIParent)
    frame:SetSize(310, 32)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("MEDIUM")
    frame:Hide()

    local background = UI.Rect(frame, {0.018, 0.052, 0.064, 0.82}, "BACKGROUND")
    background:SetAllPoints()
    icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("LEFT", 6, 0)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    title = UI.Text(frame, 11, T.text)
    title:SetPoint("TOPLEFT", 34, -6)
    title:SetPoint("TOPRIGHT", -62, -6)
    title:SetWordWrap(false)
    time = UI.Text(frame, 10, T.muted)
    time:SetPoint("TOPRIGHT", -8, -7)
    time:SetJustifyH("RIGHT")

    local track = UI.Rect(frame, {0.13, 0.20, 0.22, 0.85}, "BACKGROUND")
    track:SetPoint("BOTTOMLEFT", 34, 5)
    track:SetPoint("BOTTOMRIGHT", -8, 5)
    track:SetHeight(3)
    nativeBar, plainBar = makeBar(frame), makeBar(frame)
    if C_DurationUtil and C_DurationUtil.CreateDurationTextBinding and C_StringUtil and C_StringUtil.CreateSecondsFormatter then
        local formatter = C_StringUtil.CreateSecondsFormatter()
        formatter:SetDefaultAbbreviation(Enum.SecondsFormatterAbbreviation.OneLetter)
        formatter:SetMinInterval(Enum.SecondsFormatterInterval.Seconds)
        formatter:SetMillisecondsThreshold(60)
        timeBinding = C_DurationUtil.CreateDurationTextBinding()
        timeBinding:SetFormatter(formatter)
        timeBinding:SetFontString(time)
        timeBinding:SetEnabled(false)
    end

    UI.MakeMovable(frame, "castBar")
    frame:SetScript("OnUpdate", update)
    local events = CreateFrame("Frame")
    local terminal = {
        UNIT_SPELLCAST_STOP = true, UNIT_SPELLCAST_CHANNEL_STOP = true, UNIT_SPELLCAST_EMPOWER_STOP = true,
        UNIT_SPELLCAST_FAILED = true, UNIT_SPELLCAST_FAILED_QUIET = true, UNIT_SPELLCAST_INTERRUPTED = true,
    }
    local startEvents = {UNIT_SPELLCAST_START = true, UNIT_SPELLCAST_CHANNEL_START = true, UNIT_SPELLCAST_EMPOWER_START = true}
    for event in pairs(startEvents) do events:RegisterUnitEvent(event, "player") end
    for _, event in ipairs({"UNIT_SPELLCAST_DELAYED", "UNIT_SPELLCAST_CHANNEL_UPDATE", "UNIT_SPELLCAST_EMPOWER_UPDATE"}) do
        events:RegisterUnitEvent(event, "player")
    end
    for event in pairs(terminal) do events:RegisterUnitEvent(event, "player") end
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("PLAYER_LEAVING_WORLD")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:RegisterEvent("PLAYER_REGEN_DISABLED")
    events:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_LEAVING_WORLD" then
            hide()
        elseif terminal[event] and C_Timer and C_Timer.After then
            -- The cast query can still contain the ending cast during the stop event.
            if not updateQueued then
                updateQueued = true
                C_Timer.After(0, function()
                    updateQueued = false
                    refreshCast()
                end)
            end
        else
            refreshCast()
        end
    end)
    M.Refresh()
end
